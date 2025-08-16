pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    property bool enabled: false
    property int connectedDevices: 0
    property string connectedDeviceName: ""
    property var connectedDevicesList: []
    
    // Auto-refresh timer
    Timer {
        interval: 5000  // Update every 5 seconds
        running: true
        repeat: true
        triggeredOnStart: true
        
        onTriggered: {
            checkStatus()
        }
    }
    
    function checkStatus() {
        checkBluetoothStatus.running = true
    }
    
    function togglePower() {
        if (enabled) {
            disableBluetoothProcess.running = true
        } else {
            enableBluetoothProcess.running = true
        }
    }
    
    function openSettings() {
        bluetoothSettingsProcess.running = true
    }
    
    // Check if Bluetooth is enabled
    Process {
        id: checkBluetoothStatus
        command: ["sh", "-c", "bluetoothctl show | grep 'Powered: yes' && echo 'ON' || echo 'OFF'"]
        
        stdout: StdioCollector {
            onDataChanged: {
                const output = String(data)
                enabled = output.includes("ON")
                if (enabled) {
                    checkConnectedDevices.running = true
                } else {
                    connectedDevices = 0
                    connectedDeviceName = ""
                    connectedDevicesList = []
                }
            }
        }
    }
    
    // Check connected devices
    Process {
        id: checkConnectedDevices
        command: ["sh", "-c", "bluetoothctl devices Connected"]
        
        stdout: StdioCollector {
            onDataChanged: {
                const output = String(data)
                const lines = output.trim().split("\n").filter(line => line.length > 0)
                connectedDevices = lines.length
                connectedDevicesList = []
                
                if (connectedDevices > 0) {
                    // Parse all connected devices
                    for (let line of lines) {
                        const parts = line.split(" ")
                        if (parts.length >= 3) {
                            const deviceName = parts.slice(2).join(" ")
                            const deviceMac = parts[1]
                            connectedDevicesList.push({
                                name: deviceName,
                                mac: deviceMac
                            })
                        }
                    }
                    
                    // Set the first device as the primary one
                    if (connectedDevicesList.length > 0) {
                        connectedDeviceName = connectedDevicesList[0].name
                    }
                } else {
                    connectedDeviceName = ""
                }
            }
        }
    }
    
    // Enable Bluetooth
    Process {
        id: enableBluetoothProcess
        command: ["bluetoothctl", "power", "on"]
        
        onRunningChanged: {
            if (!running) {
                // Process completed, refresh status
                checkStatus()
            }
        }
    }
    
    // Disable Bluetooth
    Process {
        id: disableBluetoothProcess
        command: ["bluetoothctl", "power", "off"]
        
        onRunningChanged: {
            if (!running) {
                // Process completed, refresh status
                checkStatus()
            }
        }
    }
    
    // Open Bluetooth settings
    Process {
        id: bluetoothSettingsProcess
        command: ["blueman-manager"]
    }
    
    // Disconnect a specific device
    function disconnectDevice(mac) {
        disconnectDeviceProcess.command = ["bluetoothctl", "disconnect", mac]
        disconnectDeviceProcess.running = true
    }
    
    Process {
        id: disconnectDeviceProcess
        command: []
        
        onRunningChanged: {
            if (!running) {
                // Refresh status after disconnect
                checkStatus()
            }
        }
    }
}