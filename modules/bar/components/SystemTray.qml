import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root
    
    property var panelWindow: null  // Should be passed from Bar
    
    implicitWidth: trayRow.visible ? trayRow.implicitWidth : placeholderText.implicitWidth
    implicitHeight: 20
    
    // System tray logging removed - was for debugging only
    
    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 8
        
        Repeater {
            model: SystemTray.items
            
            delegate: Item {
                required property SystemTrayItem modelData
                
                width: 20
                height: 20
                
                // Show all tray items regardless of status
                // Status.Passive (0) = inactive but visible
                // Status.Active (1) = active 
                // Status.NeedsAttention (2) = needs attention
                visible: true
                
                // Menu anchor for context menus
                QsMenuAnchor {
                    id: menuAnchor
                    menu: modelData.menu
                    anchor.window: root.panelWindow
                    
                    function updatePosition() {
                        if (!root.panelWindow) return
                        
                        try {
                            const mapped = root.panelWindow.mapFromItem(mouseArea, mouseArea.width / 2, 0)
                            if (mapped) {
                                anchor.rect.x = mapped.x
                                anchor.rect.y = 50 - 2  // Position slightly overlapping the bar
                            }
                        } catch (e) {
                            // Fallback: estimate position
                            let accumulatedX = 0
                            let current = mouseArea
                            
                            while (current && current !== root.panelWindow) {
                                accumulatedX += current.x
                                current = current.parent
                            }
                            
                            anchor.rect.x = accumulatedX + mouseArea.width / 2
                            anchor.rect.y = 50 - 2  // Position slightly overlapping the bar
                        }
                    }
                }
                
                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: CustomIconLoader.getIconSource(modelData.icon)
                    sourceSize.width: 32
                    sourceSize.height: 32
                    smooth: true
                    antialiasing: true
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            // Left click - activate the item
                            if (modelData.onlyMenu && modelData.hasMenu) {
                                // If only menu, open menu
                                menuAnchor.updatePosition()
                                if (menuAnchor.anchor.window) {
                                    menuAnchor.open()
                                }
                            } else {
                                // Otherwise, activate the item
                                modelData.activate()
                            }
                        } else if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                            // Right click - show context menu
                            menuAnchor.updatePosition()
                            if (menuAnchor.anchor.window) {
                                menuAnchor.open()
                            }
                        }
                    }
                    
                    onWheel: (wheel) => {
                        // Some apps support scroll events
                        if (modelData.scroll) {
                            modelData.scroll(wheel.angleDelta.x, wheel.angleDelta.y)
                        }
                    }
                    
                    StyledTooltip {
                        visible: parent.containsMouse
                        text: {
                            if (modelData.tooltipTitle && modelData.tooltipDescription) {
                                return `${modelData.tooltipTitle}\n${modelData.tooltipDescription}`
                            } else if (modelData.tooltipTitle) {
                                return modelData.tooltipTitle
                            } else if (modelData.title) {
                                return modelData.title
                            } else {
                                return modelData.id
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Show placeholder if no tray items
    Text {
        id: placeholderText
        anchors.centerIn: parent
        visible: SystemTray.items.values.length === 0
        text: "󰂜"  // Tray icon
        font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
        font.pixelSize: 14
        color: Appearance.m3colors.on_surface_variant
        opacity: 0.3
    }
}