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
            console.warn("FractionalScalingFix: No component provided")
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
                    console.log("FractionalScalingFix: Timer triggered")
                    if (!targetComponent) {
                        console.warn("FractionalScalingFix: No target component")
                        return
                    }
                    
                    // Apply "to" values (temporary fix)
                    for (const prop in fixConfig) {
                        const config = fixConfig[prop]
                        if (config && config.to !== undefined) {
                            console.log("FractionalScalingFix: Applying", prop, "=", config.to)
                            targetComponent[prop] = config.to
                        }
                    }
                    
                    // Schedule restore to "from" values
                    Qt.callLater(() => {
                        console.log("FractionalScalingFix: Restoring to specified values")
                        for (const prop in fixConfig) {
                            const config = fixConfig[prop]
                            if (config && config.from !== undefined) {
                                console.log("FractionalScalingFix: Restoring", prop, "=", config.from)
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
                        console.log("FractionalScalingFix: Signal", prop, "changed to", currentValue)
                        
                        // Check if we should trigger
                        // null means any change, array means specific values
                        if (acceptedValues === null || 
                            (Array.isArray(acceptedValues) && acceptedValues.includes(currentValue))) {
                            console.log("FractionalScalingFix: Triggering timer for", prop, "=", currentValue)
                            timer.restart()
                        }
                    })
                }
            }
        }
        
        return timer
    }
}