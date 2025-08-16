import qs.common
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    
    implicitWidth: 20
    implicitHeight: 20
    
    Text {
        anchors.centerIn: parent
        text: "⏻"  // Power symbol
        font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
        font.pixelSize: 16
        // Access isHovered from the Loader (parent.parent)
        color: {
            var loader = parent.parent
            if (loader && loader.isHovered) {
                return Appearance.m3colors.primary
            }
            return Appearance.m3colors.on_surface_variant
        }
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
}