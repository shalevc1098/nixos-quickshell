import qs.common
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

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
                    if (!ToplevelManager.toplevels) {
                        console.log("Window repeater: No ToplevelManager.toplevels")
                        return []
                    }
                    
                    const filtered = ToplevelManager.toplevels.values.filter((toplevel) => {
                        if (!toplevel || !toplevel.HyprlandToplevel) return false
                        const address = `0x${toplevel.HyprlandToplevel.address}`
                        const win = windowByAddress[address]
                        if (!win) return false
                        
                        const workspaceId = win.workspace?.id
                        const groupStart = root.workspaceGroup * root.workspacesShown
                        const groupEnd = (root.workspaceGroup + 1) * root.workspacesShown
                        const inWorkspaceGroup = (groupStart < workspaceId && workspaceId <= groupEnd)
                        
                        return inWorkspaceGroup
                    })
                    return filtered
                }
                
                delegate: Item {
                    id: window
                    required property var modelData
                    
                    property var address: modelData.HyprlandToplevel ? `0x${modelData.HyprlandToplevel.address}` : null
                    property var windowData: address ? windowByAddress[address] : null
                    property var monitorData: windowData ? HyprlandData.monitors.find(m => m.id === windowData.monitor) : null
                    
                    // Calculate workspace offset like end4's
                    property int workspaceColIndex: windowData ? ((windowData.workspace.id - 1) % root.columns) : 0
                    property int workspaceRowIndex: windowData ? Math.floor((windowData.workspace.id - 1) % root.workspacesShown / root.columns) : 0
                    property real xOffset: (root.workspaceImplicitWidth + workspaceSpacing) * workspaceColIndex
                    property real yOffset: (root.workspaceImplicitHeight + workspaceSpacing) * workspaceRowIndex
                    
                    // Smart cross-monitor positioning with proportional scaling
                    property real initX: {
                        if (!windowData || !monitorData) return xOffset
                        
                        const windowMonitor = monitorData
                        const overviewMonitor = root.monitorData
                        
                        if (!overviewMonitor) return xOffset
                        
                        // Calculate relative position as a percentage of monitor width
                        const windowMonitorWorkspaceWidth = windowMonitor.width - (windowMonitor.reserved?.[0] || 0) - (windowMonitor.reserved?.[2] || 0)
                        const relativeX = (windowData.at[0] - (windowMonitor.x || 0) - (windowMonitor.reserved?.[0] || 0))
                        const relativeXPercent = relativeX / windowMonitorWorkspaceWidth
                        
                        // For cross-monitor, scale proportionally to fit within workspace (both directions)
                        if (windowMonitor.id !== overviewMonitor.id) {
                            // Scale proportionally to fit within this overview's workspace
                            const scaledX = relativeXPercent * root.workspaceImplicitWidth
                            
                            // Apply monitor scale adjustment only when scaling up (making bigger)
                            const windowScale = windowMonitor.scale || 1
                            const overviewScale = overviewMonitor.scale || 1
                            let finalScaledX = scaledX
                            
                            if (overviewScale < windowScale) {
                                // Making things bigger: apply scale adjustment
                                const scaleAdjustment = windowScale - overviewScale
                                finalScaledX = scaledX * (1 + scaleAdjustment)
                            }
                            // If making things smaller: use original proportional scaling (no adjustment)
                            
                            // Clamp within the actual workspace bounds (relative to xOffset)
                            const workspaceMinX = xOffset
                            const workspaceMaxX = xOffset + root.workspaceImplicitWidth - 20
                            const finalX = Math.max(Math.min(finalScaledX + xOffset, workspaceMaxX), workspaceMinX)
                            
                            return finalX
                        }
                        
                        // Same monitor: use normal positioning
                        return Math.max(relativeX * root.scale, 0) + xOffset
                    }
                    property real initY: {
                        if (!windowData || !monitorData) return yOffset
                        
                        const windowMonitor = monitorData
                        const overviewMonitor = root.monitorData
                        
                        if (!overviewMonitor) return yOffset
                        
                        // Calculate relative position as a percentage of monitor height
                        const windowMonitorWorkspaceHeight = windowMonitor.height - (windowMonitor.reserved?.[1] || 0) - (windowMonitor.reserved?.[3] || 0)
                        const relativeY = (windowData.at[1] - (windowMonitor.y || 0) - (windowMonitor.reserved?.[1] || 0))
                        const relativeYPercent = relativeY / windowMonitorWorkspaceHeight
                        
                        // For cross-monitor, scale proportionally to fit within workspace (both directions)
                        if (windowMonitor.id !== overviewMonitor.id) {
                            // Scale proportionally to fit within this overview's workspace
                            const scaledY = relativeYPercent * root.workspaceImplicitHeight
                            
                            // Apply monitor scale adjustment only when scaling up (making bigger)
                            const windowScale = windowMonitor.scale || 1
                            const overviewScale = overviewMonitor.scale || 1
                            let finalScaledY = scaledY
                            
                            if (overviewScale < windowScale) {
                                // Making things bigger: apply scale adjustment
                                const scaleAdjustment = windowScale - overviewScale
                                finalScaledY = scaledY * (1 + scaleAdjustment)
                            }
                            // If making things smaller: use original proportional scaling (no adjustment)
                            
                            // Clamp within the actual workspace bounds (relative to yOffset)
                            const workspaceMinY = yOffset
                            const workspaceMaxY = yOffset + root.workspaceImplicitHeight - 20
                            const finalY = Math.max(Math.min(finalScaledY + yOffset, workspaceMaxY), workspaceMinY)
                            
                            return finalY
                        }
                        
                        // Same monitor: use normal positioning
                        return Math.max(relativeY * root.scale, 0) + yOffset
                    }
                    
                    
                    property bool hovered: false
                    property bool pressed: false
                    property bool atInitPosition: (initX == x && initY == y)
                    
                    // End4's exact property bindings for automatic updates with cross-monitor scaling
                    x: initX
                    y: initY
                    width: {
                        if (!windowData) return 60
                        
                        let baseWidth = windowData.size[0]
                        
                        // Scale size proportionally for cross-monitor
                        if (monitorData && root.monitorData && monitorData.id !== root.monitorData.id) {
                            // Use proportional scaling instead of resolution ratio
                            const windowMonitorWorkspaceWidth = monitorData.width - (monitorData.reserved?.[0] || 0) - (monitorData.reserved?.[2] || 0)
                            const widthPercent = baseWidth / windowMonitorWorkspaceWidth
                            const scaledWidth = widthPercent * root.workspaceImplicitWidth
                            
                            // Apply monitor scale adjustment only when scaling up (making bigger)
                            const windowScale = monitorData.scale || 1
                            const overviewScale = root.monitorData.scale || 1
                            let finalWidth = scaledWidth
                            
                            if (overviewScale < windowScale) {
                                // Making things bigger: apply scale adjustment
                                const scaleAdjustment = windowScale - overviewScale
                                finalWidth = scaledWidth * (1 + scaleAdjustment)
                            }
                            // If making things smaller: use original proportional scaling (no adjustment)
                            
                            return finalWidth
                        }
                        
                        return baseWidth * root.scale
                    }
                    height: {
                        if (!windowData) return 40
                        
                        let baseHeight = windowData.size[1]
                        
                        // Scale size proportionally for cross-monitor
                        if (monitorData && root.monitorData && monitorData.id !== root.monitorData.id) {
                            // Use proportional scaling instead of resolution ratio
                            const windowMonitorWorkspaceHeight = monitorData.height - (monitorData.reserved?.[1] || 0) - (monitorData.reserved?.[3] || 0)
                            const heightPercent = baseHeight / windowMonitorWorkspaceHeight
                            const scaledHeight = heightPercent * root.workspaceImplicitHeight
                            
                            // Apply monitor scale adjustment only when scaling up (making bigger)
                            const windowScale = monitorData.scale || 1
                            const overviewScale = root.monitorData.scale || 1
                            let finalHeight = scaledHeight
                            
                            if (overviewScale < windowScale) {
                                // Making things bigger: apply scale adjustment
                                const scaleAdjustment = windowScale - overviewScale
                                finalHeight = scaledHeight * (1 + scaleAdjustment)
                            }
                            // If making things smaller: use original proportional scaling (no adjustment)
                            
                            return finalHeight
                        }
                        
                        return baseHeight * root.scale
                    }
                    opacity: windowData && monitorData ? (root.monitor?.id === windowData.monitor ? 1.0 : 0.4) : 0.4
                    
                    z: atInitPosition ? root.windowZ : root.windowDraggingZ
                    
                    // End4's smooth animations
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
                    Behavior on width {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on height {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    // Live window preview with icon overlay - best of both worlds
                    Item {
                        anchors.fill: parent
                        
                        // Rounded corners mask
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: window.width
                                height: window.height
                                radius: 8 * root.scale
                            }
                        }
                        
                        // Live window preview like end4's
                        ScreencopyView {
                            id: windowPreview
                            anchors.fill: parent
                            captureSource: modelData
                            live: true
                        }
                        
                        // Semi-transparent overlay for interactions
                        Rectangle {
                            anchors.fill: parent
                            radius: 8 * root.scale
                            color: window.pressed ? ColorUtils.transparentize(Appearance.m3colors.surface_container_highest, 0.3) : 
                                   window.hovered ? ColorUtils.transparentize(Appearance.m3colors.surface_container_high, 0.5) : 
                                   "transparent"
                            border.color: window.pressed ? Appearance.m3colors.primary : 
                                          (window.hovered ? Appearance.m3colors.outline : Appearance.m3colors.outline_variant)
                            border.width: window.pressed || window.hovered ? 1 : 0
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        // App icon overlay in center - transparent background
                        Item {
                            anchors.centerIn: parent
                            
                            property real iconSize: {
                                const minDimension = Math.min(window.width, window.height)
                                const targetSize = minDimension * 0.4 // 40% of window size - slightly smaller
                                return Math.max(targetSize, 20) // Minimum 20px
                            }
                            
                            width: iconSize
                            height: iconSize
                            
                            Image {
                                id: windowIcon
                                anchors.centerIn: parent
                                
                                width: parent.iconSize
                                height: parent.iconSize
                                
                                source: {
                                    if (!windowData) return ""
                                    return Quickshell.iconPath(AppSearch.guessIcon(windowData.class || ""), "image-missing")
                                }
                                
                                sourceSize: Qt.size(parent.iconSize, parent.iconSize)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                asynchronous: true
                                
                                Behavior on width {
                                    NumberAnimation { duration: 200 }
                                }
                                Behavior on height {
                                    NumberAnimation { duration: 200 }
                                }
                                
                                // Fallback text
                                Text {
                                    visible: parent.status === Image.Error || parent.source === ""
                                    anchors.centerIn: parent
                                    text: windowData ? (windowData.class || "?").substring(0, 1).toUpperCase() : "?"
                                    font.pixelSize: parent.width * 0.5
                                    font.family: "SF Pro Display"
                                    font.weight: Font.Medium
                                    color: Appearance.m3colors.on_surface
                                }
                            }
                        }
                    }
                    
                    // End4's drag and drop implementation
                    Drag.active: pressed
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2
                    
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
                                // Snap back to original position like end4's
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