import qs.common
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    
    required property var panelWindow
    property string searchText: ""
    
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
    readonly property var monitorData: HyprlandData.monitors.find(m => m.id === monitor?.id)
    readonly property var toplevels: ToplevelManager.toplevels
    readonly property var windows: HyprlandData.windowList
    readonly property var windowByAddress: HyprlandData.windowByAddress
    readonly property bool monitorIsFocused: (Hyprland.focusedMonitor?.name == monitor?.name)
    
    property bool sizeReady: monitor && monitor.width > 0 && monitor.height > 0 && monitor.scale > 0
    
    onMonitorChanged: {
        console.log("Monitor changed:", monitor?.name, "Scale:", monitor?.scale, "Dimensions:", monitor?.width, "x", monitor?.height)
        if (sizeReady) {
            // Force size recalculation
            Qt.callLater(() => {
                root.implicitWidthChanged()
                root.implicitHeightChanged()
            })
        }
    }
    
    onMonitorDataChanged: {
        // console.log("MonitorData changed:", monitorData?.name, "Transform:", monitorData?.transform, "Reserved:", monitorData?.reserved)
    }
    
    onSizeReadyChanged: {
        if (sizeReady) {
            console.log("Size is now ready, forcing recalculation")
            // Force immediate recalculation
            root.implicitWidthChanged()
            root.implicitHeightChanged()
        }
    }
    
    // Grid configuration
    readonly property int rows: 2
    readonly property int columns: 5
    readonly property int workspacesShown: rows * columns
    readonly property int workspaceGroup: Math.floor((monitor?.activeWorkspace?.id - 1) / workspacesShown)
    
    // Proper scaling like End's
    readonly property real scale: 0.15
    
    // Workspace dimensions with monitor transform handling
    readonly property real workspaceImplicitWidth: {
        if (!monitor || monitor.width === 0 || monitor.scale === 0) {
            return 256 * scale  // Default fallback size
        }
        return (monitorData?.transform % 2 === 1) ? 
            ((monitor.height - (monitorData?.reserved[0] || 0) - (monitorData?.reserved[2] || 0)) * scale / monitor.scale) :
            ((monitor.width - (monitorData?.reserved[0] || 0) - (monitorData?.reserved[2] || 0)) * scale / monitor.scale)
    }
    readonly property real workspaceImplicitHeight: {
        if (!monitor || monitor.height === 0 || monitor.scale === 0) {
            return 144 * scale  // Default fallback size
        }
        return (monitorData?.transform % 2 === 1) ? 
            ((monitor.width - (monitorData?.reserved[1] || 0) - (monitorData?.reserved[3] || 0)) * scale / monitor.scale) :
            ((monitor.height - (monitorData?.reserved[1] || 0) - (monitorData?.reserved[3] || 0)) * scale / monitor.scale)
    }
    
    readonly property real workspaceSpacing: 5
    readonly property real padding: 10
    
    // Z-index layering
    readonly property int workspaceZ: 0
    readonly property int windowZ: 1
    readonly property int windowDraggingZ: 99999
    
    // Drag state
    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1
    
    // Colors - using actual theme colors like End's
    readonly property color defaultWorkspaceColor: Appearance.m3colors.surface_container_low
    readonly property color hoveredWorkspaceColor: Appearance.m3colors.surface_container
    readonly property color hoveredBorderColor: Appearance.m3colors.surface_container_high
    readonly property color activeBorderColor: Appearance.m3colors.secondary
    
    readonly property real calculatedWidth: (columns * workspaceImplicitWidth + (columns - 1) * workspaceSpacing + padding * 2) + 20
    readonly property real calculatedHeight: (rows * workspaceImplicitHeight + (rows - 1) * workspaceSpacing + padding * 2) + 20
    
    implicitWidth: sizeReady ? calculatedWidth : 252
    implicitHeight: sizeReady ? calculatedHeight : 89
    
    // Force actual size to match calculated size when ready
    width: sizeReady ? calculatedWidth : 252
    height: sizeReady ? calculatedHeight : 89
    
    Component.onCompleted: {
        console.log("=== OverviewWidget Initial Sizing Debug ===")
        console.log("Monitor:", monitor?.name, "Scale:", monitor?.scale)
        console.log("Monitor dimensions:", monitor?.width, "x", monitor?.height)
        console.log("MonitorData transform:", monitorData?.transform)
        console.log("Workspace implicit dimensions:", workspaceImplicitWidth, "x", workspaceImplicitHeight)
        console.log("Calculated implicitWidth:", implicitWidth)
        console.log("Calculated implicitHeight:", implicitHeight)
        console.log("Actual width:", width, "height:", height)
        console.log("==========================================")
    }
    
    onVisibleChanged: {
        if (visible) {
            console.log("=== OverviewWidget VISIBLE ===")
            console.log("Monitor:", monitor?.name, "Scale:", monitor?.scale)
            console.log("Size ready:", sizeReady)
            console.log("Current size:", width, "x", height)
            console.log("Calculated size:", calculatedWidth, "x", calculatedHeight)
            console.log("==============================")
        }
    }
    
    onImplicitWidthChanged: {
        console.log("ImplicitWidth changed to:", implicitWidth, "Actual width:", width)
    }
    
    onImplicitHeightChanged: {
        console.log("ImplicitHeight changed to:", implicitHeight, "Actual height:", height)
    }
    
    onWidthChanged: {
        console.log("Width changed to:", width, "ImplicitWidth:", implicitWidth)
    }
    
    onHeightChanged: {
        console.log("Height changed to:", height, "ImplicitHeight:", implicitHeight)
    }
    
    // Elevation shadow placeholder (will implement StyledRectangularShadow later)
    Rectangle {
        id: shadowPlaceholder
        anchors.fill: overviewBackground
        anchors.margins: -2
        radius: overviewBackground.radius + 2
        color: "transparent"
        opacity: 0.2
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.1)
        z: -1
    }
    
    Rectangle {
        id: overviewBackground
        anchors.fill: parent
        anchors.margins: 10
        
        implicitWidth: workspaceColumnLayout.implicitWidth + padding * 2
        implicitHeight: workspaceColumnLayout.implicitHeight + padding * 2
        
        radius: 8 * scale + padding
        color: Appearance.m3colors.surface
        border.width: 1
        border.color: Appearance.m3colors.outline_variant
        
        // Workspace column layout
        ColumnLayout {
            id: workspaceColumnLayout
            z: root.workspaceZ
            anchors.centerIn: parent
            spacing: workspaceSpacing
            
            Repeater {
                model: root.rows
                
                delegate: RowLayout {
                    id: row
                    property int rowIndex: index
                    spacing: workspaceSpacing
                    
                    Repeater {
                        model: root.columns
                        
                        Rectangle {
                            id: workspace
                            property int colIndex: index
                            property int workspaceValue: root.workspaceGroup * workspacesShown + rowIndex * root.columns + colIndex + 1
                            property bool hoveredWhileDragging: false
                            
                            // Get windows for this workspace using HyprlandData.windowList
                            property var workspaceClients: {
                                if (!windows) return []
                                
                                return windows.filter(win => win && win.workspace && win.workspace.id === workspaceValue)
                            }
                            property bool hasWindows: workspaceClients.length > 0
                            
                            // Update when window data changes
                            Connections {
                                target: root
                                function onWindowByAddressChanged() {
                                    // Force property re-evaluation
                                    workspace.workspaceClientsChanged()
                                }
                            }
                            
                            
                            implicitWidth: root.workspaceImplicitWidth
                            implicitHeight: root.workspaceImplicitHeight
                            
                            radius: 8 * scale
                            color: hoveredWhileDragging ? root.hoveredWorkspaceColor : root.defaultWorkspaceColor
                            border.width: 2
                            border.color: hoveredWhileDragging ? root.hoveredBorderColor : "transparent"
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                            
                            // Content - show workspace number when empty, app icons when has windows
                            Item {
                                anchors.fill: parent
                                anchors.margins: 8
                                
                                // Workspace number (shown when no windows)
                                Text {
                                    visible: !workspace.hasWindows
                                    anchors.centerIn: parent
                                    text: workspaceValue.toString()
                                    font.pixelSize: Math.min(root.workspaceImplicitWidth, root.workspaceImplicitHeight) * monitor.scale * root.scale
                                    font.weight: Font.DemiBold
                                    color: ColorUtils.transparentize(Appearance.m3colors.on_surface, 0.8)
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                // App icons grid (shown when has windows)
                                Grid {
                                    visible: workspace.hasWindows
                                    anchors.centerIn: parent
                                    columns: Math.min(3, Math.ceil(Math.sqrt(workspace.workspaceClients?.length ?? 0)))
                                    rows: Math.min(3, Math.ceil((workspace.workspaceClients?.length ?? 0) / columns))
                                    spacing: 2
                                    
                                    Repeater {
                                        model: Math.min(9, workspace.workspaceClients?.length ?? 0)
                                        
                                        Item {
                                            width: 48
                                            height: 48
                                            
                                            Image {
                                                id: appIcon
                                                anchors.fill: parent
                                                source: {
                                                    if (!workspace.workspaceClients || index >= workspace.workspaceClients.length) return ""
                                                    
                                                    const win = workspace.workspaceClients[index]
                                                    const iconName = win?.class || ""
                                                    
                                                    if (!iconName) return ""
                                                    
                                                    // Try to get icon from CustomIconLoader first
                                                    const customIcon = CustomIconLoader.getIconSource(iconName.toLowerCase())
                                                    if (customIcon) return customIcon
                                                    
                                                    // Try to get system icon
                                                    const systemIcon = Quickshell.iconPath(iconName.toLowerCase(), "")
                                                    if (systemIcon) return systemIcon
                                                    
                                                    // Fallback to theme icon
                                                    return "image://icon/" + iconName.toLowerCase()
                                                }
                                                fillMode: Image.PreserveAspectFit
                                                smooth: true
                                                mipmap: true
                                                asynchronous: true
                                                
                                                // Fallback to text if icon fails
                                                Text {
                                                    visible: parent.status === Image.Error || parent.source === ""
                                                    anchors.centerIn: parent
                                                    text: {
                                                        if (!workspace.workspaceClients || index >= workspace.workspaceClients.length) return ""
                                                        const win = workspace.workspaceClients[index]
                                                        return (win?.class || "?").substring(0, 1).toUpperCase()
                                                    }
                                                    font.pixelSize: 10
                                                    font.family: "SF Pro Display"
                                                    font.weight: Font.Medium
                                                    color: ColorUtils.transparentize(Appearance.m3colors.on_surface, 0.5)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: workspaceMouseArea
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                
                                onClicked: {
                                    if (root.draggingTargetWorkspace === -1) {
                                        GlobalStates.overviewOpen = false
                                        Hyprland.dispatch(`workspace ${workspaceValue}`)
                                    }
                                }
                            }
                            
                            DropArea {
                                anchors.fill: parent
                                onEntered: {
                                    root.draggingTargetWorkspace = workspaceValue
                                    if (root.draggingFromWorkspace == root.draggingTargetWorkspace) return
                                    hoveredWhileDragging = true
                                }
                                onExited: {
                                    hoveredWhileDragging = false
                                    if (root.draggingTargetWorkspace == workspaceValue) root.draggingTargetWorkspace = -1
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Windows and active workspace indicator container
        Item {
            id: windowSpace
            anchors.centerIn: parent
            implicitWidth: workspaceColumnLayout.implicitWidth
            implicitHeight: workspaceColumnLayout.implicitHeight
            
            // Window repeater for all windows in current workspace group
            Repeater {
                model: {
                    if (!ToplevelManager.toplevels) return []
                    
                    return ToplevelManager.toplevels.values.filter((toplevel) => {
                        if (!toplevel || !toplevel.HyprlandToplevel) return false
                        const address = `0x${toplevel.HyprlandToplevel.address}`
                        const win = windowByAddress[address]
                        if (!win) return false
                        
                        const inWorkspaceGroup = (root.workspaceGroup * root.workspacesShown < win.workspace?.id && 
                                                 win.workspace?.id <= (root.workspaceGroup + 1) * root.workspacesShown)
                        return inWorkspaceGroup
                    })
                }
                
                delegate: OverviewWindow {
                    id: windowDelegate
                    required property var modelData
                    
                    property var address: modelData.HyprlandToplevel ? `0x${modelData.HyprlandToplevel.address}` : null
                    
                    toplevel: modelData
                    windowData: address ? windowByAddress[address] : null
                    monitorData: windowData ? HyprlandData.monitors.find(m => m.id === windowData.monitor) : null
                    scale: root.scale
                    availableWorkspaceWidth: root.workspaceImplicitWidth
                    availableWorkspaceHeight: root.workspaceImplicitHeight
                    widgetMonitorId: root.monitor?.id || 0
                    
                    property int workspaceColIndex: windowData ? ((windowData.workspace.id - 1) % root.columns) : 0
                    property int workspaceRowIndex: windowData ? Math.floor((windowData.workspace.id - 1) % root.workspacesShown / root.columns) : 0
                    xOffset: (root.workspaceImplicitWidth + workspaceSpacing) * workspaceColIndex
                    yOffset: (root.workspaceImplicitHeight + workspaceSpacing) * workspaceRowIndex
                    
                    z: pressed ? root.windowDraggingZ : root.windowZ
                    
                    Drag.active: pressed
                    Drag.hotSpot.x: targetWindowWidth / 2
                    Drag.hotSpot.y: targetWindowHeight / 2
                    
                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        drag.target: parent
                        
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        
                        onPressed: (mouse) => {
                            if (!parent.windowData) return
                            root.draggingFromWorkspace = parent.windowData.workspace.id
                            parent.pressed = true
                            parent.Drag.source = parent
                            parent.Drag.hotSpot.x = mouse.x
                            parent.Drag.hotSpot.y = mouse.y
                        }
                        
                        onReleased: {
                            const targetWorkspace = root.draggingTargetWorkspace
                            parent.pressed = false
                            parent.Drag.active = false
                            root.draggingFromWorkspace = -1
                            
                            if (targetWorkspace !== -1 && parent.windowData && targetWorkspace !== parent.windowData.workspace.id) {
                                Hyprland.dispatch(`movetoworkspacesilent ${targetWorkspace}, address:${parent.windowData.address}`)
                            } else {
                                parent.x = parent.initX
                                parent.y = parent.initY
                            }
                        }
                        
                        onClicked: (event) => {
                            if (!parent.windowData) return
                            
                            if (event.button === Qt.LeftButton) {
                                GlobalStates.overviewOpen = false
                                Hyprland.dispatch(`focuswindow address:${parent.windowData.address}`)
                                event.accepted = true
                            } else if (event.button === Qt.MiddleButton) {
                                Hyprland.dispatch(`closewindow address:${parent.windowData.address}`)
                                event.accepted = true
                            }
                        }
                    }
                }
            }
            
            // Active workspace indicator
            Rectangle {
                id: focusedWorkspaceIndicator
                property int activeWorkspaceInGroup: monitor?.activeWorkspace?.id - (root.workspaceGroup * root.workspacesShown)
                property int activeWorkspaceRowIndex: Math.floor((activeWorkspaceInGroup - 1) / root.columns)
                property int activeWorkspaceColIndex: (activeWorkspaceInGroup - 1) % root.columns
                
                x: (root.workspaceImplicitWidth + workspaceSpacing) * activeWorkspaceColIndex
                y: (root.workspaceImplicitHeight + workspaceSpacing) * activeWorkspaceRowIndex
                z: root.windowZ
                
                width: root.workspaceImplicitWidth
                height: root.workspaceImplicitHeight
                
                color: "transparent"
                radius: 8 * scale
                border.width: 2
                border.color: root.activeBorderColor
                
                Behavior on x {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                
                Behavior on y {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
    
    // Launch first search result (placeholder)
    function launchFirstResult() {
        console.log("Launch first result for:", searchText)
    }
}