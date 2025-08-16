pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    // Store brightness for each monitor
    property var monitors: ({})
    property bool initialized: false
    
    // Initialize monitors on startup
    Component.onCompleted: {
        detectMonitors()
    }
    
    // Periodically check for external brightness changes (e.g., from monitor buttons)
    // Timer {
    //     interval: 10000  // Check every 10 seconds
    //     running: true
    //     repeat: true
    //     onTriggered: {
    //         // Silently update brightness for all monitors
    //         for (let displayNum in monitors) {
    //             updateBrightnessForDisplay(parseInt(displayNum))
    //         }
    //     }
    // }
    
    function detectMonitors() {
        detectMonitorsProcess.running = true
    }
    
    // Manual refresh function
    function refreshAllMonitors() {
        for (let displayNum in monitors) {
            updateBrightnessForDisplay(parseInt(displayNum))
        }
    }
    
    // Get brightness for a specific screen
    function getBrightnessForScreen(screenName) {
        // Map screen name (like "DP-5") to display number
        const displayNum = getDisplayNumberForScreen(screenName)
        if (displayNum > 0 && monitors[displayNum]) {
            return monitors[displayNum].brightness
        }
        return -1 // No default - return invalid value
    }
    
    function getDeviceForScreen(screenName) {
        const displayNum = getDisplayNumberForScreen(screenName)
        if (displayNum > 0 && monitors[displayNum]) {
            return monitors[displayNum].device
        }
        return "Monitor"
    }
    
    function isAvailableForScreen(screenName) {
        const displayNum = getDisplayNumberForScreen(screenName)
        return displayNum > 0 && monitors[displayNum] !== undefined
    }
    
    function getDisplayNumberForScreen(screenName) {
        // Extract display number from screen name
        // DP-5 -> Display 1, DP-6 -> Display 2, etc.
        for (let displayNum in monitors) {
            if (monitors[displayNum].connector && monitors[displayNum].connector.includes(screenName)) {
                return parseInt(displayNum)
            }
        }
        return 0
    }
    
    function setBrightnessForScreen(screenName, value) {
        const displayNum = getDisplayNumberForScreen(screenName)
        if (displayNum > 0) {
            setBrightnessForDisplay(displayNum, value)
        }
    }
    
    function increaseBrightnessForScreen(screenName, amount = 5) {
        const displayNum = getDisplayNumberForScreen(screenName)
        if (displayNum > 0 && monitors[displayNum]) {
            const newValue = Math.min(monitors[displayNum].brightness + amount, 100)
            setBrightnessForDisplay(displayNum, newValue)
        }
    }
    
    function decreaseBrightnessForScreen(screenName, amount = 5) {
        const displayNum = getDisplayNumberForScreen(screenName)
        if (displayNum > 0 && monitors[displayNum]) {
            const newValue = Math.max(monitors[displayNum].brightness - amount, 0)
            setBrightnessForDisplay(displayNum, newValue)
        }
    }
    
    function setBrightnessForDisplay(displayNum, value) {
        if (value < 0) value = 0
        if (value > 100) value = 100
        
        // Update the stored value
        const updatedMonitors = Object.assign({}, monitors)
        if (!updatedMonitors[displayNum]) {
            updatedMonitors[displayNum] = {}
        }
        updatedMonitors[displayNum] = Object.assign({}, updatedMonitors[displayNum], {
            brightness: value
        })
        monitors = updatedMonitors
        monitorsChanged()
        
        // Send the command to hardware
        const process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["ddcutil", "setvcp", "10", "${value}", "--display", "${displayNum}", "--noverify", "--sleep-multiplier", "0.1"]
                onRunningChanged: {
                    if (!running) {
                        destroy()
                    }
                }
            }
        `, root)
        process.running = true
    }
    
    function updateBrightnessForDisplay(displayNum) {
        const process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["ddcutil", "getvcp", "10", "--display", "${displayNum}", "--brief", "--noverify", "--sleep-multiplier", "0.1"]
                stdout: StdioCollector {
                    onDataChanged: {
                        const output = String(data).trim()
                        const vcpParts = output.split(/\\s+/)
                        
                        if (vcpParts.length >= 5 && vcpParts[0] === "VCP") {
                            const currentValue = parseInt(vcpParts[3])
                            const maxValue = parseInt(vcpParts[4])
                            
                            if (!isNaN(currentValue) && !isNaN(maxValue) && maxValue > 0) {
                                const newBrightness = Math.round((currentValue / maxValue) * 100)
                                // Create a new object to trigger property change
                                const updatedMonitors = Object.assign({}, root.monitors)
                                if (!updatedMonitors[${displayNum}]) {
                                    updatedMonitors[${displayNum}] = {}
                                }
                                updatedMonitors[${displayNum}] = Object.assign({}, updatedMonitors[${displayNum}], {
                                    brightness: newBrightness
                                })
                                root.monitors = updatedMonitors
                                root.monitorsChanged()
                            }
                        }
                    }
                }
                onRunningChanged: {
                    if (!running) destroy()
                }
            }
        `, root)
        process.running = true
    }
    
    // Detect all monitors
    Process {
        id: detectMonitorsProcess
        command: ["sh", "-c", "ddcutil detect --brief --noverify --sleep-multiplier 0.1 2>/dev/null || true"]
        
        stdout: StdioCollector {
            onDataChanged: {
                const output = String(data)
                const lines = output.split("\n")
                
                let currentDisplay = 0
                let tempMonitors = {}
                
                for (let line of lines) {
                    if (line.startsWith("Display ")) {
                        currentDisplay = parseInt(line.replace("Display ", ""))
                        if (!isNaN(currentDisplay)) {
                            tempMonitors[currentDisplay] = {
                                brightness: -1,  // No default - will be set when we read actual value
                                device: "Display " + currentDisplay,
                                connector: "",
                                monitor: ""
                            }
                        }
                    } else if (currentDisplay > 0) {
                        if (line.includes("DRM connector:")) {
                            const parts = line.split(":")
                            if (parts.length > 1) {
                                const connector = parts[1].trim()
                                tempMonitors[currentDisplay].connector = connector
                            }
                        } else if (line.includes("Monitor:")) {
                            const parts = line.split(":")
                            if (parts.length > 1) {
                                const monitor = parts[1].trim()
                                tempMonitors[currentDisplay].monitor = monitor
                                tempMonitors[currentDisplay].device = monitor || ("Display " + currentDisplay)
                            }
                        }
                    }
                }
                
                root.monitors = tempMonitors
                
                // Get initial brightness for each monitor sequentially
                const displays = Object.keys(tempMonitors).map(n => parseInt(n))
                let index = 0
                
                function fetchNext() {
                    if (index < displays.length) {
                        const displayNum = displays[index]
                        // Fetch brightness for display
                        root.updateBrightnessForDisplay(displayNum)
                        index++
                        // Fetch next after a small delay
                        Qt.callLater(fetchNext)
                    }
                }
                
                Qt.callLater(fetchNext)
            }
        }
    }
}