import qs.common
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root
    
    property int workspaceCount: 9  // Workspaces per group (1-9, 10-19, etc.)
    property var currentScreen: null  // Screen this bar is on
    property int currentGroup: Math.floor((Hyprland.focusedWorkspace?.id - 1) / workspaceCount) || 0
    
    implicitWidth: workspaceRow.implicitWidth
    implicitHeight: workspaceRow.implicitHeight
    
    Row {
        id: workspaceRow
        spacing: 6
        padding: 6
        anchors.centerIn: parent
        
        Repeater {
            model: workspaceCount
            
            Rectangle {
                required property int index
                property int workspaceId: (currentGroup * workspaceCount) + index + 1
                property bool isActive: {
                    // Simple check: only active if this is THE focused workspace AND on the focused monitor
                    if (!Hyprland.focusedWorkspace) return false
                    if (Hyprland.focusedWorkspace.id !== workspaceId) return false
                    
                    // If we have screen info, verify this bar is on the focused monitor
                    if (currentScreen && Hyprland.focusedMonitor) {
                        // Compare screen names - they should match
                        return Hyprland.focusedMonitor.name === currentScreen.name
                    }
                    
                    // Fallback: if no screen info, just check if it's the focused workspace
                    return true
                }
                property bool hasWindows: {
                    for (let ws of Hyprland.workspaces.values) {
                        if (ws.id === workspaceId && ws.windows > 0) return true
                    }
                    return false
                }
                
                width: 20
                height: 20
                radius: 10  // Half of width/height for circle
                
                color: {
                    if (isActive) return Appearance.m3colors.primary
                    if (mouseArea.containsMouse) return Appearance.m3colors.surface_container_highest
                    if (hasWindows) return Appearance.m3colors.surface_container_highest
                    return Appearance.m3colors.surface_container_high
                }
                
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: parent.workspaceId.toString()
                    font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: {
                        if (parent.isActive) return Appearance.m3colors.on_primary
                        if (parent.hasWindows) return Appearance.m3colors.on_surface
                        return Appearance.m3colors.on_surface_variant
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        Hyprland.dispatch(`workspace ${parent.workspaceId}`)
                        // Force mouse area to update after click
                        mouse.accepted = false
                    }
                }
            }
        }
    }
    
    // Handle scroll wheel for workspace switching
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            const currentId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
            const currentGroupNum = Math.floor((currentId - 1) / workspaceCount)
            const groupBase = currentGroupNum * workspaceCount
            
            // Helper function to check if workspace is on current monitor
            function isWorkspaceOnCurrentMonitor(wsId) {
                const currentMonitor = Hyprland.focusedMonitor
                if (!currentMonitor) return true  // Default to allowing if no monitor info
                
                for (let ws of Hyprland.workspaces.values) {
                    if (ws.id === wsId && ws.monitor && ws.monitor.id !== currentMonitor.id) {
                        return false  // Workspace is on a different monitor
                    }
                }
                return true  // Workspace is not on another monitor
            }
            
            // Helper function to find next valid workspace
            function findNextWorkspace(direction) {
                let targetId = currentId
                const minWorkspace = groupBase + 1
                const maxWorkspace = groupBase + workspaceCount
                const maxAttempts = workspaceCount  // Prevent infinite loop
                
                for (let i = 0; i < maxAttempts; i++) {
                    if (direction > 0) {
                        // Next workspace
                        if (targetId >= maxWorkspace) {
                            // Move to next group
                            targetId = (currentGroupNum + 1) * workspaceCount + 1
                        } else {
                            targetId = targetId + 1
                        }
                    } else {
                        // Previous workspace
                        if (targetId <= minWorkspace) {
                            // Move to previous group if it exists, otherwise wrap to end of current group
                            if (currentGroupNum > 0) {
                                targetId = currentGroupNum * workspaceCount  // Last workspace of previous group
                            } else {
                                targetId = maxWorkspace  // Wrap to end of current group
                            }
                        } else {
                            targetId = targetId - 1
                        }
                    }
                    
                    if (isWorkspaceOnCurrentMonitor(targetId)) {
                        return targetId
                    }
                }
                
                return currentId  // No valid workspace found, stay on current
            }
            
            if (wheel.angleDelta.y > 0) {
                // Scroll up - previous workspace
                const targetId = findNextWorkspace(-1)
                if (targetId !== currentId) {
                    Hyprland.dispatch(`workspace ${targetId}`)
                }
            } else if (wheel.angleDelta.y < 0) {
                // Scroll down - next workspace
                const targetId = findNextWorkspace(1)
                if (targetId !== currentId) {
                    Hyprland.dispatch(`workspace ${targetId}`)
                }
            }
        }
    }
    
    // Refresh workspaces when they change
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "createworkspace" || event.name === "destroyworkspace") {
                Hyprland.refreshWorkspaces()
            }
        }
    }
}