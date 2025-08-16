import qs.common
import qs.services
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Rectangle {
    id: window
    
    required property var toplevel
    required property var windowData
    required property var monitorData
    required property real scale
    required property real availableWorkspaceWidth
    required property real availableWorkspaceHeight
    required property int widgetMonitorId
    
    property real xOffset: 0
    property real yOffset: 0
    
    property bool hovered: false
    property bool pressed: false
    
    // Initial position
    property real initX: {
        if (!windowData || !monitorData) return 0
        return Math.max((windowData.at[0] - (monitorData.x || 0) - (monitorData.reserved?.[0] || 0)) * scale, 0) + xOffset
    }
    
    property real initY: {
        if (!windowData || !monitorData) return 0
        return Math.max((windowData.at[1] - (monitorData.y || 0) - (monitorData.reserved?.[1] || 0)) * scale, 0) + yOffset
    }
    
    // Window dimensions
    property real targetWindowWidth: {
        if (!windowData) return 100
        return Math.min(windowData.size[0] * scale, availableWorkspaceWidth)
    }
    
    property real targetWindowHeight: {
        if (!windowData) return 60
        return Math.min(windowData.size[1] * scale, availableWorkspaceHeight)
    }
    
    x: initX
    y: initY
    width: targetWindowWidth
    height: targetWindowHeight
    
    radius: 12 * scale
    color: pressed ? Appearance.m3colors.surface_container_highest : (hovered ? Appearance.m3colors.surface_container_high : Appearance.m3colors.surface_container)
    border.width: 2
    border.color: pressed ? Appearance.m3colors.primary : (hovered ? Appearance.m3colors.outline : Appearance.m3colors.outline_variant)
    
    // Opacity based on monitor
    opacity: {
        if (!windowData || !monitorData) return 0.4
        return widgetMonitorId === windowData.monitor ? 1.0 : 0.4
    }
    
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    
    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }
    
    // Window preview placeholder (will add ScreencopyView when available)
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: parent.radius - 2
        color: Appearance.m3colors.surface_dim
        
        // Window icon/title placeholder
        Column {
            anchors.centerIn: parent
            spacing: 5
            
            // Icon
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    if (!windowData) return "?"
                    const cls = windowData.class?.toLowerCase() || ""
                    if (cls.includes("firefox")) return "󰈹"
                    if (cls.includes("code")) return "󰨞"
                    if (cls.includes("terminal") || cls.includes("foot")) return ""
                    if (cls.includes("nautilus")) return "󰉋"
                    if (cls.includes("spotify")) return ""
                    if (cls.includes("discord")) return "󰙯"
                    return "󰊯"
                }
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: Math.min(parent.width, parent.height) * 0.3
                color: Appearance.m3colors.on_surface
            }
            
            // Title
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: windowData?.title || "Unknown"
                font.family: "SF Pro Display"
                font.pixelSize: 10
                color: Appearance.m3colors.on_surface_variant
                elide: Text.ElideRight
                width: parent.width - 10
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
    
    // Opacity mask for rounded corners
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: Rectangle {
            width: window.width
            height: window.height
            radius: window.radius
        }
    }
}