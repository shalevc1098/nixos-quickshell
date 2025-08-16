pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root
    
    property var monitors: []
    property var windowList: []
    property var windowByAddress: ({})
    property var addresses: []
    property var layers: []
    
    property var workspaceBiggestWindow: ({})
    
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: root.update()
    }
    
    function update() {
        updateMonitors()
        updateWindows()
        updateLayers()
        calculateBiggestWindows()
    }
    
    function updateMonitors() {
        const newMonitors = []
        if (!Hyprland.monitors) {
            root.monitors = newMonitors
            return
        }
        for (const monitor of Hyprland.monitors.values) {
            if (!monitor) continue
            newMonitors.push({
                id: monitor.id,
                name: monitor.name,
                x: monitor.x,
                y: monitor.y,
                width: monitor.width,
                height: monitor.height,
                scale: monitor.scale,
                transform: monitor.transform,
                reserved: [0, 0, 0, 0], // top, right, bottom, left
                activeWorkspace: monitor.activeWorkspace?.id || 1
            })
        }
        root.monitors = newMonitors
    }
    
    function updateWindows() {
        const newWindowList = []
        const newWindowByAddress = {}
        const newAddresses = []
        
        
        if (!Hyprland.toplevels) {
            root.windowList = newWindowList
            root.windowByAddress = newWindowByAddress
            root.addresses = newAddresses
            return
        }
        
        for (const toplevel of Hyprland.toplevels.values) {
            if (!toplevel) continue
            
            
            // Get data from lastIpcObject which contains the actual client info
            const ipcData = toplevel.lastIpcObject || {}
            
            const windowData = {
                address: toplevel.address,
                at: [ipcData.at?.[0] || 0, ipcData.at?.[1] || 0],
                size: [ipcData.size?.[0] || 0, ipcData.size?.[1] || 0],
                workspace: {
                    id: toplevel.workspace?.id || ipcData.workspace?.id || 1,
                    name: toplevel.workspace?.name || ipcData.workspace?.name || "1"
                },
                floating: ipcData.floating || false,
                monitor: toplevel.monitor?.id || ipcData.monitor || 0,
                class: ipcData.class || "",
                title: toplevel.title || ipcData.title || "",
                pid: ipcData.pid || 0,
                xwayland: ipcData.xwayland || false,
                pinned: ipcData.pinned || false,
                fullscreen: ipcData.fullscreen || false,
                fullscreenClient: ipcData.fullscreenClient || false
            }
            
            newWindowList.push(windowData)
            newWindowByAddress[toplevel.address] = windowData
            newAddresses.push(toplevel.address)
        }
        
        root.windowList = newWindowList
        root.windowByAddress = newWindowByAddress
        root.addresses = newAddresses
    }
    
    function updateLayers() {
        // Placeholder for layer data if needed
        root.layers = []
    }
    
    function calculateBiggestWindows() {
        const biggestByWorkspace = {}
        
        for (const window of root.windowList) {
            const wsId = window.workspace.id
            const windowArea = window.size[0] * window.size[1]
            
            if (!biggestByWorkspace[wsId] || windowArea > biggestByWorkspace[wsId].area) {
                biggestByWorkspace[wsId] = {
                    address: window.address,
                    area: windowArea
                }
            }
        }
        
        root.workspaceBiggestWindow = biggestByWorkspace
    }
    
    // Connect to Hyprland events
    Connections {
        target: Hyprland
        
        function onClientsChanged() {
            root.update()
        }
        
        function onMonitorsChanged() {
            root.update()
        }
        
        function onWorkspacesChanged() {
            root.update()
        }
    }
    
    Component.onCompleted: {
        root.update()
    }
}