pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import qs.common

Singleton {
    id: root
    
    property var notifications: []  // Current notifications (auto-hide)
    property var notificationHistory: []  // Persistent history for popup
    property int defaultTimeout: Config.notifications.defaultTimeout
    property bool muted: Config.notifications.muteOnStartup
    property int maxHistorySize: Config.notifications.maxHistory  // Maximum number of notifications to keep in history
    
    // File path for persistent storage
    readonly property string historyFile: Config.paths.data + "/notification_history.json"
    
    signal notificationAdded(var notification)
    signal notificationRemoved(int id)
    
    
    
    function toggleMute() {
        muted = !muted
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
        }
        
        // Add to current notifications (for auto-hide)
        notifications = [notificationData, ...notifications]
        
        // Add to history (persistent)
        notificationHistory = [notificationData, ...notificationHistory]
        
        // Limit history size
        if (notificationHistory.length > maxHistorySize) {
            notificationHistory = notificationHistory.slice(0, maxHistorySize)
        }
        
        notificationAdded(notificationData)
        
        // Save history after adding new notification
        saveHistory()
        
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
                    } catch (e) {
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
        saveHistory()
    }
    
    function clearHistoryByApp(appName) {
        notificationHistory = notificationHistory.filter(n => n.appName !== appName)
        saveHistory()
    }
    
    function removeFromHistory(index) {
        if (index >= 0 && index < notificationHistory.length) {
            const removed = notificationHistory[index]
            notificationHistory = notificationHistory.filter((n, i) => i !== index)
            saveHistory()
        }
    }
    
    // Save notification history to file
    function saveHistory() {
        if (!Config.notifications.persistent) return
        
        try {
            // Create directory if it doesn't exist
            ensureDirectory.running = true
            
            // Prepare data for saving (limit fields to save space)
            const dataToSave = notificationHistory.map(n => ({
                title: n.title,
                body: n.body,
                appName: n.appName,
                icon: n.icon,  // Save icon path
                createdAt: n.createdAt,
                urgency: n.urgency
            }))
            
            const json = JSON.stringify(dataToSave, null, 2)
            writeProcess.command = ["sh", "-c", `echo '${json.replace(/'/g, "'\\''")}' > "${historyFile}"`]
            writeProcess.running = true
        } catch (e) {
            console.error("Failed to save notification history:", e)
        }
    }
    
    // Load notification history from file
    function loadHistory() {
        if (!Config.notifications.persistent) return
        
        readProcess.running = true
    }
    
    // Process output handler for loading history
    function processLoadedHistory(data) {
        try {
            const text = String(data).trim()
            if (text && text !== "") {
                const loaded = JSON.parse(text)
                if (Array.isArray(loaded)) {
                    // Convert loaded data back to notification format
                    notificationHistory = loaded.map((n, index) => ({
                        id: -1000 - index,  // Negative IDs for loaded notifications
                        title: n.title || "",
                        body: n.body || "",
                        icon: n.icon || "",  // Load saved icon
                        appName: n.appName || "System",
                        timeout: 0,  // Historical notifications don't timeout
                        createdAt: n.createdAt || Date.now(),
                        urgency: n.urgency || 0,
                        isReplacement: false,
                        actions: []  // Actions aren't saved
                    })).slice(0, maxHistorySize)
                }
            }
        } catch (e) {
            console.error("Failed to load notification history:", e)
        }
    }
    
    // Process components for file I/O
    Process {
        id: ensureDirectory
        command: ["mkdir", "-p", Config.paths.data]
    }
    
    Process {
        id: writeProcess
        // Command set dynamically in saveHistory()
    }
    
    Process {
        id: readProcess
        command: ["cat", historyFile]
        
        stdout: StdioCollector {
            onDataChanged: processLoadedHistory(data)
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
            
            // Skip processing if notifications are muted
            if (root.muted) {
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
    
    Component.onCompleted: {
        // Load history on startup
        loadHistory()
    }
}