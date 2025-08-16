import qs.common
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: overviewScope
    
    // Global shortcut to toggle overview
    GlobalShortcut {
        appid: "quickshell"
        name: "overviewToggle"
        description: "Toggles overview on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
    }
    
    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            id: root
            required property var modelData
            screen: modelData
            
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: Hyprland.focusedMonitor?.id == monitor?.id
            property string searchText: ""
            
            // Only show overview on the focused monitor
            visible: GlobalStates.overviewOpen && monitorIsFocused
            
            onVisibleChanged: {
                if (visible) {
                    console.log("=== Overview OPENED on monitor:", modelData.name, "Size:", modelData.width, "x", modelData.height, "Scale:", modelData.scale)
                    if (overviewLoader.item) {
                        console.log("    OverviewWidget size:", overviewLoader.item.width, "x", overviewLoader.item.height)
                    }
                    console.log("    Monitor is focused:", monitorIsFocused)
                    console.log("    Focused monitor is:", Hyprland.focusedMonitor?.name)
                }
            }
            
            // Layer configuration
            WlrLayershell.namespace: "quickshell:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            
            color: "transparent"
            
            // Full screen coverage
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            
            // Handle focus - temporarily disabled for debugging
            // HyprlandFocusGrab {
            //     id: focusGrab
            //     windows: [root]
            //     active: GlobalStates.overviewOpen && root.monitorIsFocused
            //     onCleared: {
            //         console.log("FocusGrab cleared, active:", active, "overviewOpen:", GlobalStates.overviewOpen)
            //         if (!active) {
            //             GlobalStates.overviewOpen = false
            //         }
            //     }
            // }
            
            // Transparent background - click to close
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    GlobalStates.overviewOpen = false
                }
            }
            
            // Main content
            ColumnLayout {
                id: columnLayout
                visible: GlobalStates.overviewOpen
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                }
                
                Item {
                    height: 1 // Prevent Wayland protocol error
                    width: 1 // Prevent Wayland protocol error
                }
                
                // Search bar
                SearchWidget {
                    id: searchWidget
                    Layout.alignment: Qt.AlignHCenter
                    
                    onSearchingTextChanged: {
                        root.searchText = searchingText
                    }
                    
                    onSearchSubmitted: {
                        // Launch the first search result
                        if (overviewLoader.item) {
                            overviewLoader.item.launchFirstResult()
                        }
                    }
                }
                
                // Workspace widget
                Loader {
                    id: overviewLoader
                    Layout.alignment: Qt.AlignHCenter
                    active: GlobalStates.overviewOpen
                    sourceComponent: OverviewWidget {
                        panelWindow: root
                        searchText: root.searchText
                        visible: root.searchText === ""
                        
                        Component.onCompleted: {
                            console.log("=== OverviewWidget in Overview panel created for monitor:", root.modelData.name)
                        }
                    }
                }
            }
            
            // Keyboard shortcuts
            Connections {
                target: GlobalStates
                function onOverviewOpenChanged() {
                    if (GlobalStates.overviewOpen) {
                        // focusGrab.active = root.monitorIsFocused
                        searchWidget.focusSearch()
                    } else {
                        searchWidget.clearSearch()
                    }
                }
            }
            
            // ESC key to close
            Keys.onEscapePressed: {
                GlobalStates.overviewOpen = false
            }
        }
    }
}