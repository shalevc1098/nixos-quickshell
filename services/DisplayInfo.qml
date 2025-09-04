pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    // Map of screen name to physical resolution
    property var physicalResolutions: ({
        "DP-5": { width: 3840, height: 2160 },
        "DP-6": { width: 1920, height: 1080 }
    })
    
    // Get scaling factor for a screen
    function getScalingFactor(screenName, logicalWidth, logicalHeight) {
        const physical = physicalResolutions[screenName]
        if (!physical) {
            return 1.0
        }
        
        const scaleX = physical.width / logicalWidth
        const scaleY = physical.height / logicalHeight
        
        // Use the average of X and Y scaling (they should be the same)
        const scale = (scaleX + scaleY) / 2
        
        
        return scale
    }
    
    // Get scaled dimensions for full screen coverage
    function getFullScreenDimensions(screenName, logicalWidth, logicalHeight) {
        const scale = getScalingFactor(screenName, logicalWidth, logicalHeight)
        
        // For scaled displays, we need to use the physical resolution
        // to ensure full coverage
        const physical = physicalResolutions[screenName]
        if (physical && scale > 1.0) {
            // Return physical dimensions when scaled
            return {
                width: physical.width / scale * scale,  // This ensures we cover the full screen
                height: physical.height / scale * scale
            }
        }
        
        // For non-scaled displays, use logical dimensions
        return {
            width: logicalWidth,
            height: logicalHeight
        }
    }
    
    Component.onCompleted: {
        // Try to auto-detect physical resolutions from xrandr
        detectPhysicalResolutions()
    }
    
    Process {
        id: xrandrProcess
        command: ["sh", "-c", "xrandr | grep ' connected'"]
        
        stdout: StdioCollector {
            onDataChanged: {
                const lines = String(data).split('\n')
                const newResolutions = {}
                
                for (const line of lines) {
                    if (!line.includes(' connected')) continue
                    
                    // Parse line like: "DP-5 connected 3840x2160+0+0 ..."
                    const parts = line.split(' ')
                    const name = parts[0]
                    const resMatch = parts[2].match(/(\d+)x(\d+)/)
                    
                    if (resMatch) {
                        newResolutions[name] = {
                            width: parseInt(resMatch[1]),
                            height: parseInt(resMatch[2])
                        }
                    }
                }
                
                if (Object.keys(newResolutions).length > 0) {
                    root.physicalResolutions = newResolutions
                }
            }
        }
    }
    
    function detectPhysicalResolutions() {
        xrandrProcess.running = true
    }
}