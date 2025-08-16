import qs.common
import qs.services
import QtQuick
import QtQuick.Effects
import Quickshell

Variants {
    model: Quickshell.screens
    
    PanelWindow {
        id: notificationPanel
        required property var modelData
        screen: modelData
        
        anchors.top: true
        anchors.right: true
        margins.right: 10
        margins.top: 10
        
        implicitWidth: 360
        implicitHeight: Math.min(600, contentColumn.implicitHeight)
        
        visible: NotificationService.notifications.length > 0
        focusable: false
        color: "transparent"
        
        Column {
            id: contentColumn
            width: parent.width
            spacing: 10
            
            Repeater {
                model: NotificationService.notifications
                
                delegate: Item {
                    required property var modelData
                    required property int index
                    
                    width: parent.width
                    height: notificationItem.dismissing ? 0 : notificationItem.height
                    clip: true
                    
                    Behavior on height {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Rectangle {
                        id: notificationItem
                        property var modelData: parent.modelData
                        property int index: parent.index
                        
                        property bool hovered: mouseArea.containsMouse
                        property real progress: 1.0
                        property bool dismissing: false
                        property real swipeX: 0
                        property real elapsedTime: 0
                        property bool isPaused: false
                        
                        width: parent.width
                        height: Math.max(80, notificationContent.implicitHeight + 20)
                        radius: 12
                        color: Appearance.m3colors.surface_container
                        
                        opacity: dismissing ? 0 : 1
                    
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Timer {
                        id: removeTimer
                        interval: 350
                        running: notificationItem.dismissing
                        onTriggered: {
                            NotificationService.remove(notificationItem.modelData.id)
                        }
                    }
                    
                    transform: Translate {
                        x: notificationItem.dismissing ? notificationItem.width : notificationItem.swipeX
                        
                        Behavior on x {
                            NumberAnimation {
                                duration: notificationItem.dismissing ? 300 : 200
                                easing.type: notificationItem.dismissing ? Easing.InCubic : Easing.OutCubic
                            }
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
                        id: autoCloseTimer
                        interval: 50
                        repeat: true
                        running: !notificationItem.dismissing && !notificationItem.isPaused
                        
                        onTriggered: {
                            if (!notificationItem.dismissing && !notificationItem.isPaused) {
                                notificationItem.elapsedTime += 50
                                notificationItem.progress = Math.max(0, 1.0 - (notificationItem.elapsedTime / notificationItem.modelData.timeout))
                                
                                if (notificationItem.progress <= 0) {
                                    notificationItem.dismissing = true
                                    autoCloseTimer.stop()
                                }
                            }
                        }
                    }
                    
                    onDismissingChanged: {
                        if (dismissing) {
                            autoCloseTimer.stop()
                        }
                    }
                    
                    onHoveredChanged: {
                        isPaused = hovered
                    }
                    
                    Component.onCompleted: {
                        elapsedTime = 0
                    }
                    
                    Rectangle {
                        id: progressBar
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        height: 3
                        width: parent.width * notificationItem.progress
                        radius: parent.radius
                        color: Appearance.m3colors.primary
                        opacity: notificationItem.opacity
                        
                        Behavior on width {
                            NumberAnimation {
                                duration: 50
                                easing.type: Easing.Linear
                            }
                        }
                    }
                    
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        drag.target: notificationItem
                        drag.axis: Drag.XAxis
                        drag.minimumX: 0
                        drag.maximumX: notificationItem.width + 50
                        
                        onClicked: notificationItem.dismissing = true
                        
                        onPositionChanged: {
                            if (drag.active) {
                                swipeX = mouseX - pressedButtons ? mouseX - width/2 : 0
                            }
                        }
                        
                        onReleased: {
                            if (swipeX > notificationItem.width * 0.3) {
                                notificationItem.dismissing = true
                            } else {
                                swipeX = 0
                            }
                        }
                    }
                    
                    Row {
                        id: notificationContent
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 12
                        
                        Image {
                            width: modelData.icon ? 32 : 0
                            height: 32
                            source: {
                                if (!modelData.icon) return ""
                                if (modelData.icon.startsWith("/")) return "file://" + modelData.icon
                                return "image://icon/" + modelData.icon
                            }
                            fillMode: Image.PreserveAspectFit
                            visible: modelData.icon !== ""
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Column {
                            width: parent.width - (modelData.icon ? 44 : 0)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            
                            Text {
                                width: parent.width
                                text: modelData.title
                                font.family: "SF Pro Display"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: Appearance.m3colors.on_surface
                                elide: Text.ElideRight
                                visible: text !== ""
                            }
                            
                            Text {
                                width: parent.width
                                text: modelData.body
                                font.family: "SF Pro Display"
                                font.pixelSize: 12
                                color: Appearance.m3colors.on_surface_variant
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                visible: text !== ""
                            }
                        }
                    }
                    }
                }
            }
        }
    }
}