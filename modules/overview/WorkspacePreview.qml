import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Rectangle {
    id: root
    
    required property int workspaceId
    required property HyprlandMonitor monitor
    property string searchText: ""
    
    readonly property HyprlandWorkspace workspace: Hyprland.workspaces?.values?.find(w => w && w.id === workspaceId) ?? null
    readonly property bool isActive: monitor?.activeWorkspace?.id === workspaceId
    readonly property bool hasWindows: workspace?.windows > 0
    readonly property var clients: Hyprland.clients?.values?.filter(c => c && c.workspace && c.workspace.id === workspaceId) ?? []
    
    radius: 12
    color: isActive ? Appearance.m3colors.primary_container : 
           mouseArea.containsMouse ? Appearance.m3colors.surface_container_high : 
           Appearance.m3colors.surface_container_low
    border.width: isActive ? 2 : 1
    border.color: isActive ? Appearance.m3colors.primary : Appearance.m3colors.outline_variant
    
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    
    Behavior on border.color {
        ColorAnimation { duration: 150 }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            // Switch to workspace
            switchToWorkspace(workspaceId)
        }
    }
    
    // Workspace number
    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 10
        text: workspaceId.toString()
        font.family: "SF Pro Display"
        font.pixelSize: 18
        font.weight: Font.Bold
        color: isActive ? Appearance.m3colors.primary : Appearance.m3colors.on_surface_variant
    }
    
    // Window previews
    Item {
        anchors.fill: parent
        anchors.margins: 12
        anchors.topMargin: 35
        
        GridLayout {
            anchors.fill: parent
            columns: Math.ceil(Math.sqrt(clients?.length ?? 0))
            rowSpacing: 4
            columnSpacing: 4
            
            Repeater {
                model: clients?.slice(0, 9) ?? []  // Show max 9 windows
                
                delegate: Rectangle {
                    required property var modelData
                    
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 4
                    color: Appearance.m3colors.surface_container_high
                    
                    // Window icon or class name
                    Text {
                        anchors.centerIn: parent
                        text: modelData.class?.substring(0, 2).toUpperCase() || "?"
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 10
                        color: Appearance.m3colors.on_surface_variant
                    }
                    
                    // Window title tooltip
                    StyledTooltip {
                        visible: windowMouseArea.containsMouse
                        text: modelData.title || modelData.class || "Window"
                        delay: 500
                    }
                    
                    MouseArea {
                        id: windowMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            // Focus window
                            focusWindow(modelData.address)
                        }
                    }
                }
            }
        }
        
        // Empty workspace indicator
        Text {
            anchors.centerIn: parent
            text: "Empty"
            font.family: "SF Pro Display"
            font.pixelSize: 12
            color: Appearance.m3colors.on_surface_variant
            opacity: 0.5
            visible: (clients?.length ?? 0) === 0
        }
    }
    
    // More windows indicator
    Text {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 8
        text: "+" + ((clients?.length ?? 0) - 9)
        font.family: "SF Pro Display"
        font.pixelSize: 10
        color: Appearance.m3colors.on_surface_variant
        visible: (clients?.length ?? 0) > 9
    }
    
    // Helper functions
    function switchToWorkspace(id) {
        const proc = Process.createObject(null, {
            command: ["hyprctl", "dispatch", "workspace", id.toString()]
        })
        proc.running = true
        GlobalStates.overviewOpen = false
    }
    
    function focusWindow(address) {
        const proc = Process.createObject(null, {
            command: ["hyprctl", "dispatch", "focuswindow", "address:" + address]
        })
        proc.running = true
        GlobalStates.overviewOpen = false
    }
}