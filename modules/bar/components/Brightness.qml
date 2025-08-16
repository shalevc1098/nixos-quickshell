import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    
    property string screenName: ""  // Will be set by parent
    
    implicitWidth: brightnessRow.implicitWidth
    implicitHeight: brightnessRow.implicitHeight
    
    property int currentBrightness: -1  // No default
    property string currentDevice: "Monitor"
    property bool isAvailable: false
    property int pendingBrightness: -1  // Track target brightness during scrolling
    
    // Update brightness when monitors change
    Connections {
        target: Brightness
        function onMonitorsChanged() {
            updateFromService()
        }
    }
    
    Component.onCompleted: {
        updateFromService()
    }
    
    function updateFromService() {
        if (screenName) {
            currentBrightness = Brightness.getBrightnessForScreen(screenName)
            currentDevice = Brightness.getDeviceForScreen(screenName)
            isAvailable = Brightness.isAvailableForScreen(screenName)
            pendingBrightness = -1  // Reset pending when we get actual value
        }
    }
    
    // No polling needed - updates come from monitorsChanged signal
    
    Timer {
        id: scrollDebounceTimer
        interval: 1000  // Wait 1 second after scrolling stops
        onTriggered: {
            if (pendingBrightness >= 0) {
                // Get the actual current brightness from the service
                const actualBrightness = Brightness.getBrightnessForScreen(screenName)
                // Only send command if the pending value is different from actual
                if (pendingBrightness !== actualBrightness) {
                    Brightness.setBrightnessForScreen(screenName, pendingBrightness)
                }
                pendingBrightness = -1  // Reset pending
            }
        }
    }
    
    Row {
        id: brightnessRow
        spacing: 4
        anchors.centerIn: parent
        visible: isAvailable && currentBrightness >= 0
        
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                const b = root.currentBrightness
                if (b >= 75) return "󰃠"  // High brightness
                if (b >= 50) return "󰃟"  // Medium brightness
                if (b >= 25) return "󰃞"  // Low brightness
                return "󰃝"  // Very low brightness
            }
            font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            color: Appearance.m3colors.on_surface
        }
        
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: currentBrightness >= 0 ? `${root.currentBrightness}%` : "--"
            font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Appearance.m3colors.on_surface
        }
    }
    
    // Fallback when brightness control not available or loading
    Text {
        anchors.centerIn: parent
        visible: !isAvailable || currentBrightness < 0
        text: "󰃝"
        font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
        font.pixelSize: 14
        color: Appearance.m3colors.on_surface_variant
        opacity: 0.5
    }
    
    MouseArea {
        id: brightnessMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: isAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.NoButton  // Only handle wheel events
        
        onWheel: (wheel) => {
            if (!isAvailable || !screenName) return
            
            // Accept the wheel event to prevent propagation
            wheel.accepted = true
            
            // Calculate new brightness based on current UI value or pending value
            const baseBrightness = pendingBrightness >= 0 ? pendingBrightness : currentBrightness
            let newBrightness = baseBrightness
            
            if (wheel.angleDelta.y > 0) {
                // Increase brightness
                newBrightness = Math.min(baseBrightness + 5, 100)
            } else if (wheel.angleDelta.y < 0) {
                // Decrease brightness
                newBrightness = Math.max(baseBrightness - 5, 0)
            }
            
            // Update UI immediately
            currentBrightness = newBrightness
            pendingBrightness = newBrightness
            
            // Restart timer - will send command after scrolling stops
            scrollDebounceTimer.restart()
        }
    }
}