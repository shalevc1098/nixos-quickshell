import QtQuick
import QtQuick.Controls
import qs.common

ToolTip {
    id: root
    
    delay: 500
    timeout: 5000
    
    // Material Design styling
    contentItem: Text {
        text: root.text
        font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
        font.pixelSize: 12
        color: Appearance.m3colors.on_surface
    }
    
    background: Rectangle {
        color: Appearance.m3colors.surface_container_highest
        radius: 8
        border.width: 1
        border.color: Appearance.m3colors.outline_variant
    }
    
    padding: 8
    leftPadding: 12
    rightPadding: 12
}