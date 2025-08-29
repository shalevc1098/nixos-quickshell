pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    
    property var notifications: []  // Current notifications (auto-hide)
    property var notificationHistory: []  // Persistent history for popup
    property int defaultTimeout: 5000
    property bool muted: false
    property int maxHistorySize: 50  // Maximum number of notifications to keep in history
    
    signal notificationAdded(var notification)
    signal notificationRemoved(int id)
    
    Component.onCompleted: {
        console.log("NotificationService initialized")
    }
    
    function toggleMute() {
        muted = !muted
        console.log(`Notifications ${muted ? 'muted' : 'unmuted'}`)
    }
    
    function addNotification(notification) {
        // Check if this is a replacement notification
        const existingIndex = notifications.findIndex(n => n.id === notification.id)
        
        
        // Process actions properly - they come as an object with numeric keys
        let actionsArray = []
        if (notification.actions) {
            const keys = Object.keys(notification.actions)
            for (let i = 0; i < keys.length; i++) {
                const action = notification.actions[keys[i]]
                if (action) {
                    // Store action data for display
                    actionsArray.push({
                        identifier: action.identifier,
                        text: action.text
                    })
                }
            }
        }
        
        const notificationData = {
            id: notification.id,
            title: notification.summary || "",
            body: notification.body || "",
            icon: notification.appIcon || notification.image || "",
            appName: notification.appName || "System",
            timeout: notification.expireTimeout && notification.expireTimeout > 0 ? notification.expireTimeout : defaultTimeout,
            createdAt: Date.now(),
            urgency: notification.urgency,
            isReplacement: existingIndex !== -1,
            // Pass the action data for display
            actions: actionsArray
        }
        
        
        if (existingIndex !== -1) {
            // Remove the old notification first
            notifications = notifications.filter(n => n.id !== notification.id)
            console.log(`Replacing notification: "${notificationData.title}"`)
        }
        
        // Add to current notifications (for auto-hide)
        notifications = [notificationData, ...notifications]
        
        // Add to history (persistent)
        notificationHistory = [notificationData, ...notificationHistory]
        
        // Limit history size
        if (notificationHistory.length > maxHistorySize) {
            notificationHistory = notificationHistory.slice(0, maxHistorySize)
        }
        
        console.log(`Notification added: "${notificationData.title}" - Current: ${notifications.length}, History: ${notificationHistory.length}`)
        notificationAdded(notificationData)
        
        // Don't set tracked - this prevents the notification server from receiving updates
        // notification.tracked = true
    }
    
    function invokeAction(notificationId, actionIdentifier) {
        // Find notification in server's tracked notifications
        const trackedNotif = server.trackedNotifications.values.find(n => n.id === notificationId)
        
        if (trackedNotif && trackedNotif.actions) {
            // Find the action in the original notification
            const keys = Object.keys(trackedNotif.actions)
            for (let i = 0; i < keys.length; i++) {
                const action = trackedNotif.actions[keys[i]]
                if (action && action.identifier === actionIdentifier) {
                    try {
                        action.invoke()
                        console.log(`Action "${actionIdentifier}" invoked for notification ${notificationId}`)
                    } catch (e) {
                        console.log("Error invoking action:", e)
                    }
                    break
                }
            }
        }
    }
    
    function remove(id) {
        const index = notifications.findIndex(n => n.id === id)
        if (index !== -1) {
            notifications = notifications.filter(n => n.id !== id)
            console.log(`Notification removed: ${id} - Total: ${notifications.length}`)
            
            // Also untrack from server to prevent persistence
            const trackedNotif = server.trackedNotifications.values.find(n => n.id === id)
            if (trackedNotif) {
                trackedNotif.tracked = false
            }
            
            notificationRemoved(id)
        }
    }
    
    function clear() {
        const ids = notifications.map(n => n.id)
        notifications = []
        
        // Untrack all notifications from server
        ids.forEach(id => {
            const trackedNotif = server.trackedNotifications.values.find(n => n.id === id)
            if (trackedNotif) {
                trackedNotif.tracked = false
            }
            notificationRemoved(id)
        })
    }
    
    // History management functions
    function clearHistory() {
        notificationHistory = []
        console.log("Notification history cleared")
    }
    
    function removeFromHistory(index) {
        if (index >= 0 && index < notificationHistory.length) {
            const removed = notificationHistory[index]
            notificationHistory = notificationHistory.filter((n, i) => i !== index)
            console.log(`Removed from history: "${removed.title}" - History size: ${notificationHistory.length}`)
        }
    }
    
    NotificationServer {
        id: server
        
        // Enable notification features
        bodySupported: true
        bodyImagesSupported: true
        bodyHyperlinksSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: true
        persistenceSupported: true
        
        // Don't keep notifications on reload - they should be fresh
        keepOnReload: false
        
        onNotification: (notification) => {
            console.log(`NotificationServer received: app="${notification.appName}" title="${notification.summary}" id=${notification.id} tracked=${notification.tracked}`)
            
            // Skip processing if notifications are muted
            if (root.muted) {
                console.log("Notification ignored (muted)")
                return
            }
            
            // Only track notifications with actions (needed for invoke to work)
            const hasActions = notification.actions && Object.keys(notification.actions).length > 0
            
            if (hasActions) {
                notification.tracked = true
            }
            
            // Process the notification
            root.addNotification(notification)
        }
    }
}