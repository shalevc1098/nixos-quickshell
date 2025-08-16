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
        
        if (!Hyprland.clients) {
            root.windowList = newWindowList
            root.windowByAddress = newWindowByAddress
            root.addresses = newAddresses
            return
        }
        
        for (const client of Hyprland.clients.values) {
            if (!client) continue
            
            const windowData = {
                address: client.address,
                at: [client.x, client.y],
                size: [client.width, client.height],
                workspace: {
                    id: client.workspace?.id || 1,
                    name: client.workspace?.name || "1"
                },
                floating: client.floating,
                monitor: client.monitor?.id || 0,
                class: client.class_ || "",
                title: client.title || "",
                pid: client.pid,
                xwayland: client.xwayland,
                pinned: client.pinned,
                fullscreen: client.fullscreen,
                fullscreenClient: client.fullscreenClient
            }
            
            newWindowList.push(windowData)
            newWindowByAddress[client.address] = windowData
            newAddresses.push(client.address)
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