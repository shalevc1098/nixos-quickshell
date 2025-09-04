import qs.services
import QtQuick
import Quickshell

Variants {
    model: Quickshell.screens
    
    PanelWindow {
        id: notificationPanel
        required property var modelData
        screen: modelData
        
        anchors.top: true
        anchors.right: true
        
        implicitWidth: 370
        implicitHeight: modelData.height
        
        visible: true
        focusable: false
        color: "transparent"
        mask: bubbles.length > 0 ? activeMask : emptyMask
        
        property var bubbles: []
        property int spacing: 10
        property int maxNotifications: 15
        
        // Empty mask for no clicks
        Region {
            id: emptyMask
        }
        
        // Active mask that covers the notification area
        Region {
            id: activeMask
            item: Rectangle {
                x: 0
                y: 0
                width: 370
                height: {
                    // Calculate total height of all bubbles
                    let totalHeight = spacing
                    for (let i = 0; i < notificationPanel.bubbles.length; i++) {
                        const bubble = notificationPanel.bubbles[i]
                        if (bubble && !bubble.dismissing) {
                            totalHeight += bubble.height + spacing
                        }
                    }
                    return Math.max(1, totalHeight)
                }
            }
        }
        
        Item {
            id: container
            anchors.fill: parent
            
            // Make the container area pass through clicks
            MouseArea {
                anchors.fill: parent
                enabled: false  // This makes clicks pass through
            }
        }
        
        Component {
            id: bubbleComponent
            NotificationBubble {}
        }
        
        Connections {
            target: NotificationService
            
            function onNotificationAdded(notification) {
                
                // Remove oldest notifications if we're at the limit
                while (bubbles.length >= maxNotifications) {
                    const oldestBubble = bubbles[bubbles.length - 1]
                    if (oldestBubble && !oldestBubble.dismissing) {
                        oldestBubble.dismissing = true
                    }
                    bubbles.pop()
                }
                
                // Don't push existing bubbles down here - let updatePositions handle it
                
                // Create a new bubble inside the container at the top
                const bubble = bubbleComponent.createObject(container, {
                    notification: notification,
                    yPosition: spacing
                })
                
                if (bubble) {
                    // Make bubble visible immediately
                    bubble.visible = true
                    
                    // Add to beginning of array (newest first)
                    bubbles = [bubble, ...bubbles]
                    
                    // Defer position update to next frame to ensure bubble height is ready
                    Qt.callLater(() => {
                        updatePositions()
                    })
                    
                    // Also update when bubble height changes (for multiline text)
                    bubble.onHeightChanged.connect(() => {
                        updatePositions()
                    })
                    
                    // Connect removal
                    bubble.onDismissingChanged.connect(() => {
                        if (bubble.dismissing) {
                            Qt.callLater(() => {
                                removeBubble(bubble)
                            })
                        }
                    })
                } else {
                }
            }
        }
        
        function calculateYPosition() {
            if (bubbles.length === 0) return spacing
            return spacing
        }
        
        function updatePositions() {
            let currentY = spacing
            // Iterate through bubbles array which has newest first
            for (let i = 0; i < bubbles.length; i++) {
                if (bubbles[i] && !bubbles[i].dismissing) {
                    bubbles[i].yPosition = currentY
                    currentY += bubbles[i].height + spacing
                }
            }
        }
        
        function removeBubble(bubble) {
            const index = bubbles.indexOf(bubble)
            if (index !== -1) {
                bubbles.splice(index, 1)
                bubbles = [...bubbles] // Trigger update
                updatePositions()
                // Mask update happens in updatePositions
            }
        }
        
    }
}