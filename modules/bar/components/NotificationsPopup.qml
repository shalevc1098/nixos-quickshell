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
            console.log("Notifications popup toggled, showing:", popupBox.showing)
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
                    
                    model: NotificationService.notificationHistory
                    
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
                        height: notificationContent.height + 16
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 8
                            color: notificationMouseArea.containsMouse ? 
                                   Appearance.m3colors.surface_container_highest : 
                                   Appearance.m3colors.surface_container
                            
                            MouseArea {
                                id: notificationMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                onClicked: {
                                    // Could add action handling here if notifications have actions
                                    console.log("Notification clicked:", modelData.summary)
                                }
                            }
                            
                            Column {
                                id: notificationContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 12
                                spacing: 4
                                
                                // App name and time (account for close button width)
                                Row {
                                    width: parent.width - 28  // Leave space for close button
                                    spacing: 8
                                    
                                    Text {
                                        text: modelData.appName || "System"
                                        font.family: "SF Pro Display"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: Appearance.m3colors.primary
                                    }
                                    
                                    Item { 
                                        width: parent.width - parent.children[0].width - timeText.width - 16
                                        height: 1 
                                    }
                                    
                                    Text {
                                        id: timeText
                                        text: {
                                            // Format time ago
                                            const now = Date.now()
                                            const notifTime = modelData.createdAt || modelData.timestamp || now
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
                                    }
                                }
                                
                                // Summary (title)
                                Text {
                                    width: parent.width - 28  // Account for close button
                                    text: modelData.summary || ""
                                    font.family: "SF Pro Display"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: Appearance.m3colors.on_surface
                                    wrapMode: Text.Wrap
                                }
                                
                                // Body (description)
                                Text {
                                    width: parent.width - 28  // Account for close button
                                    text: modelData.body || ""
                                    font.family: "SF Pro Display"
                                    font.pixelSize: 12
                                    color: Appearance.m3colors.on_surface_variant
                                    wrapMode: Text.Wrap
                                    visible: text.length > 0
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                            }
                            
                            // Close button for individual notification
                            MouseArea {
                                width: 20
                                height: 20
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 8
                                cursorShape: Qt.PointingHandCursor
                                
                                onClicked: {
                                    NotificationService.removeFromHistory(index)
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"  // Close icon
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 14
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