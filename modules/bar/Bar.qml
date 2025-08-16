import qs.common
import qs.widgets
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import "./components"

Item {
  id: root
  
  // Signal to request PowerMenu from shell
  signal powerMenuRequested()
  
  // Process components for bubble click handlers
  Process {
    id: networkSettingsProcess
    command: ["nm-connection-editor"]
  }
  
  Process {
    id: volumeSettingsProcess
    command: ["easyeffects"]
  }
  
  Process {
    id: volumeToggleMuteProcess
    command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
  }

  Variants {
    model: Quickshell.screens
  
  PanelWindow {
    id: barWindow
    required property var modelData
    screen: modelData
    
    anchors {
      top: true
      left: true
      right: true
    }

    implicitHeight: 48
    color: "transparent"
    
    // Main bar container
    Rectangle {
      id: barContainer
      anchors.fill: parent
      color: "transparent"
      
      // Bar content with padding
      Item {
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        
        // Left section
        Row {
          id: leftSection
          anchors.left: parent.left
          spacing: 8
          
          // Distro (Nix) icon - most left
          Bubble {
            content: Component {
              DistroIcon {}
            }
          }
          
          // Clock
          Bubble {
            content: Component {
              Clock {}
            }
          }
          
          // Brightness
          Bubble {
            content: Component {
              Brightness {
                screenName: modelData.name  // Pass the screen name (e.g., "DP-5", "DP-6")
              }
            }
          }
        }
        
        // Center section
        Row {
          id: centerSection
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 8
          
          // MPRIS media player
          Bubble {
            id: mediaBubble
            horizontalPadding: 10
            content: Component {
              MediaPlayer {
                onOpenPopup: mediaControlsPopup.mediaControlsOpen = !mediaControlsPopup.mediaControlsOpen
              }
            }
          }
          
          // Workspaces bubble
          Bubble {
            horizontalPadding: 6
            content: Component {
              Workspaces {
                currentScreen: modelData
              }
            }
          }
          
          // Overview button - workspace switcher
          Bubble {
            id: overviewBubble
            horizontalPadding: 8
            onClicked: {
              GlobalStates.toggleOverview()
            }
            
            content: Component {
              Item {
                implicitWidth: overviewIcon.width
                implicitHeight: overviewIcon.height
                
                Text {
                  id: overviewIcon
                  text: "󰕰"  // Grid icon for overview
                  font.family: "JetBrainsMono Nerd Font Propo"
                  font.pixelSize: 16
                  color: GlobalStates.overviewOpen ? Appearance.m3colors.primary : 
                        Appearance.m3colors.on_surface_variant
                  
                  Behavior on color {
                    ColorAnimation { duration: 150 }
                  }
                }
                
                StyledTooltip {
                  visible: parent.parent && parent.parent.isHovered
                  text: "Overview (Super+Tab)"
                  delay: 500
                }
              }
            }
          }
          
          // Bell icon bubble (shows notification history) - moved after workspaces
          Bubble {
            id: bellBubble
            content: Component {
              Item {
                implicitWidth: bellText.width
                implicitHeight: bellText.height
                
                Text {
                  id: bellText
                  text: NotificationService.notifications.length > 0 ? "󰂚" : "󰂜"  // Bell icon changes based on notifications
                  font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
                  font.pixelSize: 14
                  // Change color on hover when parent is clickable
                  color: (parent.parent && parent.parent.isHovered) ? Appearance.m3colors.primary : Appearance.m3colors.on_surface_variant
                  
                  Behavior on color {
                      ColorAnimation { duration: 150 }
                  }
                }
                
                // Notification count badge
                Rectangle {
                  visible: NotificationService.notifications.length > 0
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.rightMargin: -4
                  anchors.topMargin: -2
                  width: 6
                  height: 6
                  radius: 3
                  color: Appearance.m3colors.primary
                }
              }
            }
            onClicked: function() {
              notificationHistory.showing = !notificationHistory.showing
            }
          }
        }
        
        // Right section
        Row {
          id: rightSection
          anchors.right: parent.right
          spacing: 8
          
          // Network (WiFi) bubble
          Bubble {
            content: Component {
              Network {
                id: networkItem
              }
            }
            onClicked: function() {
              // Open network settings
              networkSettingsProcess.running = true
            }
          }
          
          // Bluetooth bubble
          Bubble {
            content: Component {
              Bluetooth {
                id: bluetoothItem
              }
            }
            onClicked: function() {
              if (Bluetooth.enabled) {
                Bluetooth.openSettings()
              } else {
                Bluetooth.toggle()
              }
            }
          }
          
          // Volume bubble
          Bubble {
            content: Component {
              Volume {
                id: volumeItem
              }
            }
            onClicked: function(mouse) {
              if (mouse && mouse.button === Qt.RightButton) {
                // Toggle mute
                volumeToggleMuteProcess.running = true
              } else {
                // Open volume settings
                volumeSettingsProcess.running = true
              }
            }
          }
          
          // System tray bubble
          Bubble {
            horizontalPadding: 12
            visible: SystemTray.items.values.length > 0  // Set to false to hide the system tray
            content: Component {
              SystemTray {
                panelWindow: barWindow
              }
            }
          }
          
          // Power button bubble - most right
          Bubble {
            content: Component {
              PowerButton {
                id: powerButton
              }
            }
            onClicked: function() {
              console.log("Power button clicked, emitting powerMenuRequested signal")
              root.powerMenuRequested()
            }
          }
        }
      }
    }
    
    // Simple Hello World Popup
    SimplePopup {
      id: notificationHistory
      barWindow: barWindow
      bellBubble: bellBubble
    }
    
    // Media Controls Popup
    MediaControlsPopup {
      id: mediaControlsPopup
    }
  }
  } // End of Variants
} // End of Item