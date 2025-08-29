import qs.common
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    
    implicitWidth: volumeRow.implicitWidth
    implicitHeight: volumeRow.implicitHeight
    
    property int volume: 0
    property bool isMuted: false
    property bool scrollProcessing: false  // Prevent overlapping scroll commands
    
    Timer {
        interval: 1000  // Update every second
        running: true
        repeat: true
        triggeredOnStart: true
        
        onTriggered: {
            getVolumeProcess.running = true
        }
    }
    
    Process {
        id: getVolumeProcess
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        
        stdout: StdioCollector {
            onDataChanged: {
                const output = String(data)
                // Output format: "Volume: 0.75" or "Volume: 0.75 [MUTED]"
                const match = output.match(/Volume:\s+([\d.]+)/)
                if (match) {
                    const vol = Math.round(parseFloat(match[1]) * 100)
                    volume = vol
                }
                isMuted = output.includes("[MUTED]")
            }
        }
    }
    
    Process {
        id: getMuteStatus
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        
        stdout: StdioCollector {
            onDataChanged: {
                const output = String(data)
                isMuted = output.includes("[MUTED]")
            }
        }
    }
    
    // Functions to be called from Bubble
    function openSettings() {
        easyeffectsProcess.running = true
    }
    
    function toggleMute() {
        toggleMuteProcess.running = true
    }
    
    function increaseVolume() {
        if (scrollProcessing) return
        scrollProcessing = true
        setVolumeProcess.command = ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+"]
        setVolumeProcess.running = true
    }
    
    function decreaseVolume() {
        if (scrollProcessing) return
        scrollProcessing = true
        setVolumeProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]
        setVolumeProcess.running = true
    }
    
    Row {
        id: volumeRow
        spacing: 4
        anchors.centerIn: parent
        
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (isMuted) return "󰝟"  // Muted
                if (volume >= 70) return "󰕾"  // High volume
                if (volume >= 30) return "󰖀"  // Medium volume
                if (volume > 0) return "󰕿"  // Low volume
                return "󰝟"  // Zero volume
            }
            font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            color: {
                // Access isHovered from the Loader (parent.parent.parent for Row > Item > Loader)
                var loader = parent.parent.parent
                if (loader && loader.isHovered) {
                    return Appearance.m3colors.primary
                }
                return isMuted ? Appearance.m3colors.on_surface_variant : Appearance.m3colors.on_surface
            }
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
        
        Text {
            text: `${volume}%`
            font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            font.weight: Font.Medium
            color: {
                // Access isHovered from the Loader (parent.parent.parent for Row > Item > Loader)
                var loader = parent.parent.parent
                if (loader && loader.isHovered) {
                    return Appearance.m3colors.primary
                }
                return Appearance.m3colors.on_surface
            }
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
    }
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton  // Only handle wheel events
        propagateComposedEvents: true  // Allow clicks to pass through
        cursorShape: Qt.PointingHandCursor  // Show pointer to indicate clickability
        
        onWheel: (wheel) => {
            wheel.accepted = true
            
            // Use vertical scroll delta and ensure proper direction
            const delta = wheel.angleDelta.y
            
            if (delta > 0) {
                // Scroll up - increase volume
                increaseVolume()
            } else if (delta < 0) {
                // Scroll down - decrease volume
                decreaseVolume()
            }
        }
    }
    
    Process {
        id: easyeffectsProcess
        command: ["easyeffects"]
    }
    
    Process {
        id: toggleMuteProcess
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        
        onRunningChanged: {
            if (!running) {
                // Process completed, refresh status
                getVolumeProcess.running = true
            }
        }
    }
    
    Process {
        id: setVolumeProcess
        
        onRunningChanged: {
            if (!running) {
                getVolumeProcess.running = true
                scrollProcessing = false  // Reset flag when command completes
            }
        }
    }
}