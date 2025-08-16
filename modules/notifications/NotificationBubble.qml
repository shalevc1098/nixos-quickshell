import qs.common
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell

Rectangle {
    id: root
    
    required property var notification
    required property int yPosition
    property bool hovered: mouseArea.containsMouse || actionButtonsHovered
    property real progress: 1.0
    property bool dismissing: false
    property real swipeX: 0
    property real elapsedTime: 0
    property bool actionButtonsHovered: false
    
    visible: true
    width: 350
    implicitHeight: mainContent.implicitHeight + 24 + 4 // content + margins + progress bar
    height: Math.max(80, implicitHeight)
    radius: 12
    color: Appearance.m3colors.surface_container
    
    property real baseX: 10
    property real dragX: 0
    
    x: dismissing ? width + 10 : baseX + dragX
    y: yPosition
    
    opacity: dismissing ? 0 : 1
    
    Behavior on x {
        NumberAnimation {
            duration: dismissing ? 300 : (dragX !== 0 ? 0 : 200)
            easing.type: dismissing ? Easing.InCubic : Easing.OutCubic
        }
    }
    
    Behavior on y {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    
    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
    
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: 0.5
        shadowColor: "#40000000"
        shadowVerticalOffset: 2
    }
    
    Timer {
        id: lifeTimer
        interval: 50
        repeat: true
        running: !hovered && !dismissing
        
        onTriggered: {
            elapsedTime += 50
            progress = Math.max(0, 1.0 - (elapsedTime / notification.timeout))
            
            if (progress <= 0) {
                root.dismissing = true
            }
        }
    }
    
    Timer {
        id: removeTimer
        interval: 350
        running: dismissing
        onTriggered: {
            NotificationService.remove(notification.id)
            root.destroy()
        }
    }
    
    // Progress bar container with proper clipping
    Item {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        anchors.bottomMargin: 1
        height: 3
        clip: true
        
        Rectangle {
            id: progressBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            height: 3
            x: parent.width * (1.0 - root.progress)
            width: parent.width * root.progress
            radius: root.radius
            color: Appearance.m3colors.primary
            opacity: root.opacity
            
            Behavior on x {
                NumberAnimation {
                    duration: 50
                    easing.type: Easing.Linear
                }
            }
            
            Behavior on width {
                NumberAnimation {
                    duration: 50
                    easing.type: Easing.Linear
                }
            }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        
        property real startX: 0
        property bool swiping: false
        
        onPressed: {
            startX = mouseX
            swiping = true
            root.dragX = 0
        }
        
        onPositionChanged: {
            if (swiping && pressed) {
                let deltaX = mouseX - startX
                // Only allow swiping to the right
                if (deltaX > 0) {
                    root.dragX = deltaX
                }
            }
        }
        
        onReleased: {
            swiping = false
            // Dismiss if swiped more than 80 pixels
            if (root.dragX > 80) {
                root.dismissing = true
            } else {
                // Snap back to original position
                root.dragX = 0
            }
        }
        
        onClicked: {
            // Only dismiss on click if we didn't swipe
            if (Math.abs(mouseX - startX) < 5) {
                root.dismissing = true
            }
        }
    }
    
    Column {
        id: mainContent
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        
        // Header row with app name and timestamp
        Item {
            id: headerItem
            width: parent.width
            height: 20
            
            // App icon and name on the left
            Row {
                spacing: 6
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                
                Image {
                    width: 16
                    height: 16
                    source: {
                        if (!notification.icon) return ""
                        if (notification.icon.startsWith("/")) return "file://" + notification.icon
                        if (notification.icon.startsWith("image://")) return notification.icon
                        return "image://icon/" + notification.icon
                    }
                    fillMode: Image.PreserveAspectFit
                    visible: notification.icon !== "" && status !== Image.Error
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: notification.appName || "System"
                    font.family: "SF Pro Display"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Appearance.m3colors.on_surface_variant
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            
            // Timestamp on the right
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    let now = new Date()
                    return now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                }
                font.family: "SF Pro Display"
                font.pixelSize: 11
                color: Appearance.m3colors.on_surface_variant
            }
        }
        
        // Main content
        Column {
            id: contentColumn
            width: parent.width
            spacing: 4
            
            
            Text {
                width: parent.width
                text: notification.title
                font.family: "SF Pro Display"
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Appearance.m3colors.on_surface
                elide: Text.ElideRight
                visible: text !== ""
            }
            
            Text {
                width: parent.width
                text: notification.body
                font.family: "SF Pro Display"
                font.pixelSize: 12
                color: Appearance.m3colors.on_surface_variant
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
                visible: text !== ""
                lineHeight: 1.2
            }
            
            // Action buttons
            Item {
                width: parent.width
                height: actionButtons.visible ? 28 : 0
                visible: notification.actions && notification.actions.length > 0
                
                Row {
                    id: actionButtons
                    anchors.centerIn: parent
                    spacing: 8
                    
                    Repeater {
                        model: notification.actions || []
                        
                        Rectangle {
                            id: actionButton
                            required property var modelData
                            
                            // For single button: full width minus some padding
                            // For multiple: divide space equally with max width
                            width: {
                                const numActions = notification.actions ? notification.actions.length : 0
                                if (numActions === 1) {
                                    return Math.min(200, contentColumn.width - 32)
                                } else {
                                    const availableWidth = contentColumn.width
                                    const totalSpacing = (numActions - 1) * actionButtons.spacing
                                    const buttonWidth = (availableWidth - totalSpacing) / numActions
                                    return Math.min(120, Math.max(80, buttonWidth))
                                }
                            }
                            height: 28
                            radius: 6
                            color: actionMouseArea.containsMouse ? Appearance.m3colors.primary : Appearance.m3colors.surface_container_high
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: actionButton.modelData ? (actionButton.modelData.text || actionButton.modelData.identifier || "Action") : "Unknown"
                                font.family: "SF Pro Display"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: actionMouseArea.containsMouse ? Appearance.m3colors.on_primary : Appearance.m3colors.on_surface
                                elide: Text.ElideRight
                                width: parent.width - 16
                                horizontalAlignment: Text.AlignHCenter
                            }
                            
                            MouseArea {
                                id: actionMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                onContainsMouseChanged: {
                                    // Simple hover tracking
                                    root.actionButtonsHovered = containsMouse
                                }
                                
                                onClicked: {
                                    console.log("Action button clicked")
                                    
                                    // Call the service to invoke the action
                                    if (actionButton.modelData && actionButton.modelData.identifier) {
                                        NotificationService.invokeAction(notification.id, actionButton.modelData.identifier)
                                    }
                                    
                                    // Dismiss the notification when action is clicked
                                    root.dismissing = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}