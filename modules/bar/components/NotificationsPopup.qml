import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland

Scope {
    id: notificationsPopupScope
    
    property alias barWindow: popupBox.anchorWindow
    property alias bellBubble: popupBox.anchorItem
    property alias showing: popupBox.showing
    
    // Debug shortcut to test notifications popup
    GlobalShortcut {
        appid: "quickshell"
        name: "notificationsToggle"
        description: "Toggle notifications popup"
        
        onPressed: {
            popupBox.showing = !popupBox.showing
        }
    }
    
    PopupBox {
        id: popupBox
        
        property var barWindow: null
        property var bellBubble: null
        
        anchorWindow: barWindow
        anchorItem: bellBubble
        
        popupWidth: 380
        popupHeight: 500
        maxHeight: 600
        autoHeight: false
        xOffset: 0  // Center under bell
        
        content: Component {
            Item {
                id: contentRoot
                implicitHeight: notificationsList.contentHeight + headerRow.height + 20
                
                // Header with title and clear button
                Row {
                    id: headerRow
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 40
                    
                    Text {
                        text: "Notifications"
                        font.family: "SF Pro Display"
                        font.pixelSize: 18
                        font.weight: Font.Medium
                        color: Appearance.m3colors.on_surface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Item { 
                        width: parent.width - parent.children[0].width - clearButton.width - 20
                        height: 1 
                    }
                    
                    // Clear all button
                    MouseArea {
                        id: clearButton
                        width: clearText.width + 16
                        height: 30
                        anchors.verticalCenter: parent.verticalCenter
                        cursorShape: Qt.PointingHandCursor
                        visible: NotificationService.notificationHistory.length > 0
                        
                        onClicked: {
                            NotificationService.clearHistory()
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 15
                            color: parent.containsMouse ? Appearance.m3colors.error : "transparent"
                            border.width: 1
                            border.color: Appearance.m3colors.error
                            
                            Text {
                                id: clearText
                                anchors.centerIn: parent
                                text: "Clear All"
                                font.family: "SF Pro Display"
                                font.pixelSize: 12
                                color: parent.parent.containsMouse ? Appearance.m3colors.on_error : Appearance.m3colors.error
                            }
                        }
                    }
                }
                
                // Separator line
                Rectangle {
                    id: separator
                    anchors.top: headerRow.bottom
                    anchors.topMargin: 5
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Appearance.m3colors.outline_variant
                    opacity: 0.5
                }
                
                // Notifications list
                ListView {
                    id: notificationsList
                    anchors.top: separator.bottom
                    anchors.topMargin: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    clip: true
                    spacing: 8
                    
                    property var expandedApps: ({})  // Track which app groups are expanded
                    
                    // Group notifications by app
                    model: {
                        const groups = {}
                        for (let i = 0; i < NotificationService.notificationHistory.length; i++) {
                            const notif = NotificationService.notificationHistory[i]
                            const appName = notif.appName || "System"
                            if (!groups[appName]) {
                                groups[appName] = []
                            }
                            const notifCopy = Object.assign({}, notif)
                            notifCopy.originalIndex = i
                            groups[appName].push(notifCopy)
                        }
                        
                        // Convert to array format for ListView
                        const result = []
                        for (const [appName, notifications] of Object.entries(groups)) {
                            result.push({
                                appName: appName,
                                notifications: notifications,
                                count: notifications.length
                            })
                        }
                        return result
                    }
                    
                    // Empty state
                    Text {
                        visible: parent.count === 0
                        anchors.centerIn: parent
                        text: "No notifications"
                        font.family: "SF Pro Display"
                        font.pixelSize: 14
                        color: Appearance.m3colors.on_surface_variant
                        opacity: 0.7
                    }
                    
                    delegate: Item {
                        width: notificationsList.width
                        height: appGroupColumn.height
                        
                        Column {
                            id: appGroupColumn
                            width: parent.width
                            spacing: 4
                            
                            // App group header
                            Rectangle {
                                width: parent.width
                                height: modelData.count === 1 || !notificationsList.expandedApps[modelData.appName] ? 60 : 40
                                radius: 8
                                color: groupHeaderMouse.containsMouse ? 
                                       Appearance.m3colors.surface_container_highest : 
                                       Appearance.m3colors.surface_container
                                
                                property real dragX: 0
                                property bool dismissing: false
                                
                                transform: Translate {
                                    x: dismissing ? parent.width : dragX
                                    Behavior on x {
                                        NumberAnimation {
                                            duration: dismissing ? 200 : 0
                                            easing.type: Easing.OutCubic
                                            onRunningChanged: {
                                                if (!running && dismissing) {
                                                    NotificationService.clearHistoryByApp(modelData.appName)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                opacity: 1 - Math.abs(dragX) / parent.width
                                
                                MouseArea {
                                    id: groupHeaderMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: modelData.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    
                                    property real startX: 0
                                    property bool isDragging: false
                                    
                                    onPressed: {
                                        startX = mouseX
                                        isDragging = false
                                    }
                                    
                                    onPositionChanged: {
                                        if (pressed) {
                                            const delta = mouseX - startX
                                            if (Math.abs(delta) > 5) {
                                                isDragging = true
                                                parent.dragX = delta
                                            }
                                        }
                                    }
                                    
                                    onReleased: {
                                        if (isDragging) {
                                            if (Math.abs(parent.dragX) > 80) {
                                                parent.dismissing = true
                                            } else {
                                                parent.dragX = 0
                                            }
                                        } else if (!isDragging && modelData.count > 1) {
                                            const expanded = notificationsList.expandedApps
                                            expanded[modelData.appName] = !expanded[modelData.appName]
                                            notificationsList.expandedApps = expanded
                                        }
                                    }
                                }
                                
                                Row {
                                    id: headerRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.topMargin: 12
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 8
                                    
                                    // Expand/collapse arrow (only if multiple notifications)
                                    Text {
                                        visible: modelData.count > 1
                                        text: notificationsList.expandedApps[modelData.appName] ? "󰅃" : "󰅀"
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                        font.pixelSize: 12
                                        color: Appearance.m3colors.on_surface_variant
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    // App icon
                                    Image {
                                        width: 16
                                        height: 16
                                        source: {
                                            const firstNotif = modelData.notifications[0]
                                            if (firstNotif.icon) {
                                                return firstNotif.icon.startsWith("/") || firstNotif.icon.startsWith("file://") ? 
                                                       firstNotif.icon : 
                                                       CustomIconLoader.getIconSource(firstNotif.icon)
                                            }
                                            return ""
                                        }
                                        visible: source !== ""
                                        anchors.verticalCenter: parent.verticalCenter
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }
                                    
                                    // App name
                                    Text {
                                        text: modelData.appName
                                        font.family: "SF Pro Display"
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        color: Appearance.m3colors.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    // Notification count badge
                                    Rectangle {
                                        visible: modelData.count > 1
                                        width: countText.width + 12
                                        height: 20
                                        radius: 10
                                        color: Appearance.m3colors.primary_container
                                        anchors.verticalCenter: parent.verticalCenter
                                        
                                        Text {
                                            id: countText
                                            anchors.centerIn: parent
                                            text: modelData.count
                                            font.family: "SF Pro Display"
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: Appearance.m3colors.on_primary_container
                                        }
                                    }
                                    
                                    
                                    // Most recent time
                                    Text {
                                        text: {
                                            const mostRecent = modelData.notifications[0]
                                            const now = Date.now()
                                            const notifTime = mostRecent.createdAt || mostRecent.timestamp || now
                                            const diff = now - notifTime
                                            const seconds = Math.floor(diff / 1000)
                                            const minutes = Math.floor(seconds / 60)
                                            const hours = Math.floor(minutes / 60)
                                            const days = Math.floor(hours / 24)
                                            
                                            if (days > 0) return days + "d ago"
                                            if (hours > 0) return hours + "h ago"
                                            if (minutes > 0) return minutes + "m ago"
                                            return "Just now"
                                        }
                                        font.family: "SF Pro Display"
                                        font.pixelSize: 11
                                        color: Appearance.m3colors.on_surface_variant
                                        opacity: 0.7
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                
                                // Show first notification preview if collapsed
                                Text {
                                    visible: modelData.count === 1 || !notificationsList.expandedApps[modelData.appName]
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.children[1].bottom
                                    anchors.topMargin: 4
                                    anchors.leftMargin: modelData.count > 1 ? 32 : 12
                                    anchors.rightMargin: 12
                                    text: {
                                        const firstNotif = modelData.notifications[0]
                                        const title = firstNotif.title || ""
                                        const body = firstNotif.body || ""
                                        return title + (body ? " • " + body : "")
                                    }
                                    font.family: "SF Pro Display"
                                    font.pixelSize: 12
                                    color: Appearance.m3colors.on_surface_variant
                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                }
                            }
                            
                            // Expanded notifications
                            Repeater {
                                model: notificationsList.expandedApps[modelData.appName] && modelData.count > 1 ? 
                                       modelData.notifications : []
                                
                                delegate: Rectangle {
                                    width: appGroupColumn.width - 20
                                    height: notifCol.height + 16
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    radius: 6
                                    color: notifMouse.containsMouse ? 
                                           Appearance.m3colors.surface_container_highest : 
                                           Appearance.m3colors.surface_container_high
                                    
                                    property real dragX: 0
                                    property bool dismissing: false
                                    
                                    transform: Translate {
                                        x: dismissing ? parent.width : dragX
                                        Behavior on x {
                                            NumberAnimation {
                                                duration: dismissing ? 200 : 0
                                                easing.type: Easing.OutCubic
                                                onRunningChanged: {
                                                    if (!running && dismissing) {
                                                        NotificationService.removeFromHistory(modelData.originalIndex)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    opacity: 1 - Math.abs(dragX) / parent.width
                                    
                                    MouseArea {
                                        id: notifMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        
                                        property real startX: 0
                                        property bool isDragging: false
                                        
                                        onPressed: {
                                            startX = mouseX
                                            isDragging = false
                                        }
                                        
                                        onPositionChanged: {
                                            if (pressed) {
                                                const delta = mouseX - startX
                                                if (Math.abs(delta) > 5) {
                                                    isDragging = true
                                                    parent.dragX = delta
                                                }
                                            }
                                        }
                                        
                                        onReleased: {
                                            if (isDragging) {
                                                if (Math.abs(parent.dragX) > 80) {
                                                    parent.dismissing = true
                                                } else {
                                                    parent.dragX = 0
                                                }
                                            }
                                        }
                                    }
                                    
                                    Row {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.margins: 10
                                        spacing: 8
                                        
                                        // Notification icon
                                        Image {
                                            width: 20
                                            height: 20
                                            source: {
                                                if (modelData.icon) {
                                                    return modelData.icon.startsWith("/") || modelData.icon.startsWith("file://") ? 
                                                           modelData.icon : 
                                                           CustomIconLoader.getIconSource(modelData.icon)
                                                }
                                                return ""
                                            }
                                            visible: source !== ""
                                            anchors.verticalCenter: parent.verticalCenter
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                        }
                                        
                                        Column {
                                            id: notifCol
                                            width: parent.width - (parent.children[0].visible ? parent.children[0].width + parent.spacing : 0) - 24
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2
                                            
                                            Text {
                                                width: parent.width
                                                text: modelData.title || ""
                                                font.family: "SF Pro Display"
                                                font.pixelSize: 12
                                                font.weight: Font.Medium
                                                color: Appearance.m3colors.on_surface
                                                wrapMode: Text.Wrap
                                            }
                                        
                                            Text {
                                                width: parent.width
                                                text: modelData.body || ""
                                                font.family: "SF Pro Display"
                                                font.pixelSize: 11
                                                color: Appearance.m3colors.on_surface_variant
                                                wrapMode: Text.Wrap
                                                visible: text.length > 0
                                                maximumLineCount: 2
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                    
                                    // Close button for individual notification
                                    MouseArea {
                                        width: 18
                                        height: 18
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 6
                                        cursorShape: Qt.PointingHandCursor
                                        
                                        onClicked: {
                                            NotificationService.removeFromHistory(modelData.originalIndex)
                                        }
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            font.family: "JetBrainsMono Nerd Font Propo"
                                            font.pixelSize: 12
                                            color: parent.containsMouse ? 
                                                   Appearance.m3colors.error : 
                                                   Appearance.m3colors.on_surface_variant
                                            opacity: parent.containsMouse ? 1.0 : 0.5
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}