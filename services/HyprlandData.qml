pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

/**
 * Provides access to real-time Hyprland data using direct hyprctl commands.
 * Based on end4's exact approach for live position updates.
 */
Singleton {
    id: root
    
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var monitors: []
    property var workspaceBiggestWindow: ({})
    
    function updateWindowList() {
        getClients.running = true
    }
    
    function updateMonitors() {
        getMonitors.running = true
    }
    
    function updateAll() {
        updateWindowList()
        updateMonitors()
    }
    
    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = root.windowList.filter(w => w.workspace.id == workspaceId)
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0)
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0)
            return winArea > maxArea ? win : maxWin
        }, null)
    }
    
    Component.onCompleted: {
        updateAll()
    }
    
    // End4's key insight: Listen to ALL Hyprland events for real-time updates
    Connections {
        target: Hyprland
        
        function onRawEvent(event) {
            // console.log("Hyprland raw event:", event.name)
            updateAll()
        }
    }
    
    // Direct hyprctl command for live window data - End4's approach
    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                root.windowList = JSON.parse(clientsCollector.text)
                let tempWinByAddress = {}
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i]
                    tempWinByAddress[win.address] = win
                }
                root.windowByAddress = tempWinByAddress
                root.addresses = root.windowList.map(win => win.address)
                
                // Calculate biggest windows for workspaces
                calculateBiggestWindows()
            }
        }
    }
    
    // Monitor data using hyprctl
    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                root.monitors = JSON.parse(monitorsCollector.text)
            }
        }
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
}