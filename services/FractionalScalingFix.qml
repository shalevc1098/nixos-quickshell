pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root
    
    // Dynamic fix that monitors properties and applies temporary changes
    // Usage: FractionalScalingFix.attach(component, {
    //     triggers: { visible: [true], width: null },  // null = any change
    //     fix: { color: { from: "transparent", to: "#01000000" } },  // from/to values
    //     delay: 10  // ms before applying fix
    // })
    function attach(component, config = {}) {
        if (!component) {
            return null
        }
        
        const triggers = config.triggers || { visible: [true] }
        const fix = config.fix || {}
        const delay = config.delay || 10
        
        // Create timer for delayed fix
        const timer = Qt.createQmlObject(`
            import QtQuick
            Timer {
                id: fixTimer
                interval: ${delay}
                running: false
                repeat: false
                
                property var targetComponent
                property var fixConfig: ({})
                
                onTriggered: {
                    if (!targetComponent) {
                        return
                    }
                    
                    // Apply "to" values (temporary fix)
                    for (const prop in fixConfig) {
                        const config = fixConfig[prop]
                        if (config && config.to !== undefined) {
                            targetComponent[prop] = config.to
                        }
                    }
                    
                    // Schedule restore to "from" values
                    Qt.callLater(() => {
                        for (const prop in fixConfig) {
                            const config = fixConfig[prop]
                            if (config && config.from !== undefined) {
                                targetComponent[prop] = config.from
                            }
                        }
                    })
                }
            }
        `, component)
        
        // Set timer properties
        timer.targetComponent = component
        timer.fixConfig = fix
        
        
        // Connect triggers
        for (const prop in triggers) {
            if (component.hasOwnProperty(prop)) {
                const signal = component[prop + "Changed"]
                const acceptedValues = triggers[prop]
                
                if (signal) {
                    signal.connect(() => {
                        const currentValue = component[prop]
                        
                        // Check if we should trigger
                        // null means any change, array means specific values
                        if (acceptedValues === null || 
                            (Array.isArray(acceptedValues) && acceptedValues.includes(currentValue))) {
                            timer.restart()
                        }
                    })
                }
            }
        }
        
        return timer
    }
}