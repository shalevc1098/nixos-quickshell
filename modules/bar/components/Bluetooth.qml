import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    
    implicitWidth: 20
    implicitHeight: 20
    
    Text {
        anchors.centerIn: parent
        text: {
            if (!Bluetooth.enabled) return "󰂲"  // Bluetooth off
            if (Bluetooth.connectedDevices > 0) return "󰂱"  // Bluetooth connected
            return "󰂯"  // Bluetooth on but not connected
        }
        font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
        font.pixelSize: 16
        color: {
            // Access isHovered from the Loader (parent.parent)
            var loader = parent.parent
            if (loader && loader.isHovered) {
                return Appearance.m3colors.primary
            }
            
            if (!Bluetooth.enabled) return Appearance.m3colors.on_surface_variant
            if (Bluetooth.connectedDevices > 0) return Appearance.m3colors.primary
            return Appearance.m3colors.on_surface
        }
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    StyledTooltip {
        visible: parent.parent && parent.parent.isHovered ? parent.parent.isHovered : false
        text: {
            if (!Bluetooth.enabled) return "Bluetooth: Off"
            if (Bluetooth.connectedDevices > 0) return `Connected: ${Bluetooth.connectedDeviceName}`
            return "Bluetooth: On"
        }
    }
}