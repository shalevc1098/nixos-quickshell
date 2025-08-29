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
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    modelData.activate()
                                    popupBox.showing = false
                                } else if (mouse.button === Qt.RightButton) {
                                    if (modelData.hasMenu) {
                                        modelData.openMenu()
                                    }
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