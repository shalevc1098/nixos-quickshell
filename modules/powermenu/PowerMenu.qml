import qs.common
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Scope {
    id: root
    
    property bool visible: false
    
    onVisibleChanged: {
        console.log("PowerMenu visible changed to:", visible)
    }
    
    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            required property var modelData
            screen: modelData
            
            // For full screen coverage, we use the screen's dimensions directly
            // The key is to NOT set dimensions and let anchors do the work
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            
            // Set margins to 0 to ensure true full screen
            margins {
                top: 0
                bottom: 0
                left: 0
                right: 0
            }
            
            // Ensure window covers entire screen
            exclusiveZone: -1  // Don't push other windows
            
            visible: root.visible
        color: "transparent"
        
        Component.onCompleted: {
            // Force full screen after creation
            const scale = DisplayInfo.getScalingFactor(modelData.name, modelData.width, modelData.height)
            console.log(`PowerMenu for ${modelData.name}: Logical ${modelData.width}x${modelData.height}, Scale ${scale.toFixed(2)}x`)
            
            // Try to force size if needed
            if (scale > 1.0) {
                // For scaled displays, ensure we're using full logical space
                implicitWidth = modelData.width
                implicitHeight = modelData.height

                // Only apply fractional scaling fix to scaled displays
                FractionalScalingFix.attach(this, {
                    triggers: { visible: [true] },     // Only when becoming visible
                    fix: { color: { from: this.color.toString(), to: "#01000000" } },  // Flicker to force redraw
                    delay: 10                           // Wait 10ms before applying
                })
            }
        }
        
        
        // Main content Item for keyboard handling
        Item {
            anchors.fill: parent
            focus: true
            
            // Keyboard handling
            Keys.onEscapePressed: root.visible = false
            
            // Background overlay
            Rectangle {
                anchors.fill: parent
                color: Appearance.m3colors.surface
                opacity: 0.95
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.visible = false
                }
            }
            
            // Center container
            Item {
                anchors.centerIn: parent
                width: grid.width
                height: grid.height
            
            GridLayout {
                id: grid
                columns: 3
                // Scale spacing based on screen size
                rowSpacing: Math.min(modelData.width, modelData.height) * 0.04
                columnSpacing: Math.min(modelData.width, modelData.height) * 0.04
                
                // Lock
                PowerMenuButton {
                    icon: "󰌾"  // Lock icon
                    label: "Lock"
                    command: ["loginctl", "lock-session"]
                    screenSize: Math.min(modelData.width, modelData.height)
                    onExecuted: root.visible = false
                }
                
                // Logout
                PowerMenuButton {
                    icon: "󰍃"  // Logout icon
                    label: "Logout"
                    command: ["loginctl", "terminate-user", "$USER"]
                    screenSize: Math.min(modelData.width, modelData.height)
                    onExecuted: root.visible = false
                }
                
                // Suspend
                PowerMenuButton {
                    icon: "󰤄"  // Sleep/suspend icon
                    label: "Suspend"
                    command: ["systemctl", "suspend"]
                    screenSize: Math.min(modelData.width, modelData.height)
                    onExecuted: root.visible = false
                }
                
                // Hibernate
                PowerMenuButton {
                    icon: "󰋊"  // Hibernate icon
                    label: "Hibernate"
                    command: ["systemctl", "hibernate"]
                    screenSize: Math.min(modelData.width, modelData.height)
                    onExecuted: root.visible = false
                }
                
                // Shutdown
                PowerMenuButton {
                    icon: "󰐥"  // Shutdown icon
                    label: "Shutdown"
                    command: ["systemctl", "poweroff"]
                    screenSize: Math.min(modelData.width, modelData.height)
                    onExecuted: root.visible = false
                }
                
                // Reboot
                PowerMenuButton {
                    icon: "󰑓"  // Reboot icon
                    label: "Reboot"
                    command: ["systemctl", "reboot"]
                    screenSize: Math.min(modelData.width, modelData.height)
                    onExecuted: root.visible = false
                }
            }
            }  // End of center container Item
        }  // End of main content Item
    }
    }
    
    function show() {
        console.log("PowerMenu.show() called")
        visible = true
        console.log("PowerMenu visible set to:", visible)
    }
    
    function hide() {
        console.log("PowerMenu.hide() called")
        visible = false
    }
}