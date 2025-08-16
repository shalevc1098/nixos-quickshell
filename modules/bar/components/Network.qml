import qs.common
import qs.widgets
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    
    implicitWidth: networkText.implicitWidth
    implicitHeight: networkText.implicitHeight
    
    property string networkStatus: ""
    property string networkIcon: "󰤭"  // Default disconnected icon
    property bool isConnected: false
    
    Timer {
        interval: 5000  // Update every 5 seconds
        running: true
        repeat: true
        triggeredOnStart: true
        
        onTriggered: {
            networkStatusProcess.running = true
        }
    }
    
    Process {
        id: networkStatusProcess
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device | grep -E '^(ethernet|wifi):connected'"]
        
        stdout: StdioCollector {
            onDataChanged: {
                const rawData = String(data)
                const output = rawData.trim()
                if (output.includes("ethernet:connected")) {
                    networkIcon = "󰈀"  // Ethernet icon
                    isConnected = true
                    // Get connection name
                    const parts = output.split(":")
                    if (parts.length >= 3) {
                        networkStatus = parts[2]
                    }
                } else if (output.includes("wifi:connected")) {
                    // Get wifi signal strength
                    wifiStrengthProcess.running = true
                    isConnected = true
                } else {
                    networkIcon = "󰤭"  // Disconnected
                    networkStatus = ""
                    isConnected = false
                }
            }
        }
    }
    
    Process {
        id: wifiStrengthProcess
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL device wifi | grep '^yes'"]
        
        stdout: StdioCollector {
            onDataChanged: {
                const rawData = String(data)
                const output = rawData.trim()
                const parts = output.split(":")
                if (parts.length >= 3) {
                    const signal = parseInt(parts[2])
                    networkStatus = parts[1]  // SSID name
                    
                    // Set icon based on signal strength
                    if (signal >= 75) {
                        networkIcon = "󰤨"  // Full signal
                    } else if (signal >= 50) {
                        networkIcon = "󰤥"  // Medium signal
                    } else if (signal >= 25) {
                        networkIcon = "󰤢"  // Low signal
                    } else {
                        networkIcon = "󰤟"  // Very low signal
                    }
                }
            }
        }
    }
    
    // Function to open settings - called from Bubble
    function openSettings() {
        settingsProcess.running = true
    }
    
    Text {
        id: networkText
        anchors.centerIn: parent
        text: networkIcon
        font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
        font.pixelSize: 16
        color: {
            // Access isHovered from the Loader (parent.parent)
            var loader = parent.parent
            if (loader && loader.isHovered) {
                return Appearance.m3colors.primary
            }
            return isConnected ? Appearance.m3colors.on_surface : Appearance.m3colors.on_surface_variant
        }
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    StyledTooltip {
        visible: (parent.parent && parent.parent.isHovered ? parent.parent.isHovered : false) && networkStatus !== ""
        text: networkStatus
    }
    
    Process {
        id: settingsProcess
        command: ["nm-connection-editor"]
    }
}