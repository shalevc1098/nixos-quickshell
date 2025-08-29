import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

Scope {
    id: trayExpandScope
    
    property alias anchorWindow: popupBox.anchorWindow
    property alias anchorItem: popupBox.anchorItem
    property alias showing: popupBox.showing
    
    // Debug shortcut for testing the tray popup (remove this in production)
    GlobalShortcut {
        appid: "quickshell"
        name: "trayExpandToggle"
        description: "Toggle tray expand popup"
        
        onPressed: {
            popupBox.showing = !popupBox.showing
        }
    }
    
    // Debug shortcut to test menu display for first tray item
    GlobalShortcut {
        appid: "quickshell"
        name: "trayMenuTest"
        description: "Test tray menu display"
        
        onPressed: {
            console.log("Testing tray menu display...")
            if (SystemTray.items.values.length > 0) {
                const firstItem = SystemTray.items.values[0]
                console.log("First tray item:", firstItem.id, "hasMenu:", firstItem.hasMenu)
                
                if (firstItem.hasMenu) {
                    // Try different position values
                    console.log("anchorWindow:", popupBox.anchorWindow)
                    console.log("popupBox:", popupBox)
                    console.log("popupBox visible:", popupBox.visible)
                    
                    // Test with different coordinates and windows
                    console.log("Testing display with popupBox at 100, 100")
                    firstItem.display(popupBox, 100, 100)
                    
                    // Also try with anchorWindow after a delay
                    Qt.callLater(() => {
                        console.log("Testing display with anchorWindow at 200, 200")
                        firstItem.display(popupBox.anchorWindow, 200, 200)
                    })
                }
            } else {
                console.log("No tray items available")
            }
        }
    }

PopupBox {
    id: popupBox
    
    property int iconSize: 16  // Same as main tray
    property int cellSize: 28  // Compact cell size
    property int gridPadding: 6
    property int gridSpacing: 2  // Small gap like main tray
    property int columns: Math.min(4, SystemTray.items.values.length)  // Use actual count if less than 4
    
    popupWidth: columns * cellSize + (columns - 1) * gridSpacing + gridPadding * 2
    popupHeight: Math.ceil(SystemTray.items.values.length / columns) * cellSize + 
                 Math.max(0, Math.ceil(SystemTray.items.values.length / columns) - 1) * gridSpacing + 
                 gridPadding * 2
    xOffset: 0  // Center under the arrow
    autoHeight: false  // We're calculating height manually
    
    content: Component {
        Item {
            anchors.fill: parent
            
            // Grid with dynamic sizing
            Grid {
                anchors.centerIn: parent
                columns: popupBox.columns
                spacing: popupBox.gridSpacing
                
                Repeater {
                    model: SystemTray.items
                    
                    Item {
                        required property SystemTrayItem modelData
                        
                        width: popupBox.cellSize
                        height: popupBox.cellSize
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: mouseArea.containsMouse ? Appearance.m3colors.surface_container_highest : "transparent"
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        Image {
                            anchors.centerIn: parent
                            width: popupBox.iconSize
                            height: popupBox.iconSize
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
                                console.log("=== Tray item clicked ===")
                                console.log("Item:", modelData.id, "hasMenu:", modelData.hasMenu)
                                
                                // The popup is positioned relative to the bar window
                                // We need to calculate: popup position + item position within popup + mouse position
                                
                                // Get popup position relative to bar window
                                const popupX = popupBox.anchor.rect.x || 0
                                const popupY = popupBox.anchor.rect.y || 0
                                
                                // Calculate item position within the popup
                                let itemX = mouse.x
                                let itemY = mouse.y
                                let current = mouseArea
                                
                                // Walk up to the popup content root
                                while (current && current.parent && current.parent !== popupBox) {
                                    itemX += current.x || 0
                                    itemY += current.y || 0
                                    current = current.parent
                                }
                                
                                // Final position relative to bar window
                                const finalX = popupX + itemX
                                const finalY = popupY + itemY
                                
                                console.log("Popup position:", popupX, popupY)
                                console.log("Item position within popup:", itemX, itemY)
                                console.log("Final position:", finalX, finalY)
                                
                                if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                                    console.log("Displaying menu at:", finalX, finalY)
                                    modelData.display(popupBox.anchorWindow, finalX, finalY)
                                } else if (mouse.button === Qt.LeftButton) {
                                    if (modelData.onlyMenu && modelData.hasMenu) {
                                        modelData.display(popupBox.anchorWindow, finalX, finalY)
                                    } else {
                                        modelData.activate()
                                        popupBox.showing = false
                                    }
                                } else if (mouse.button === Qt.MiddleButton) {
                                    modelData.secondaryActivate()
                                }
                            }
                        }
                        
                        StyledTooltip {
                            visible: mouseArea.containsMouse
                            text: modelData.tooltipTitle || modelData.title || modelData.id
                        }
                    }
                }
            }
            
        }
    }
}
}