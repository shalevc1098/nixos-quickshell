pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    property var options: ({
        overview: {
            enable: true,
            scale: 0.15,
            rows: 2,
            columns: 5
        },
        search: {
            nonAppResultDelay: 200,
            prefix: {
                clipboard: "clip:",
                emojis: "emoji:",
                action: "action:"
            },
            engineBaseUrl: "https://www.google.com/search?q=",
            excludedSites: []
        },
        apps: {
            terminal: "foot"
        },
        hacks: {
            arbitraryRaceConditionDelay: 50
        }
    })
    
    property var sizes: ({
        searchWidth: 600,
        searchWidthCollapsed: 400,
        elevationMargin: 10
    })
    
    property var animation: ({
        elementMove: {
            type: Easing.OutCubic,
            bezierCurve: [0.4, 0.0, 0.2, 1.0]
        },
        elementMoveFast: {
            duration: 200,
            type: Easing.OutCubic
        }
    })
    
    property var rounding: ({
        large: 12,
        screenRounding: 8
    })
    
    property var font: ({
        pixelSize: {
            small: 14,
            huge: 20
        },
        family: {
            main: "SF Pro Display"
        }
    })
    
    property string configPath: Quickshell.homeDir + "/.config/quickshell/config.json"
    
    FileView {
        id: configFile
        path: root.configPath
        
        onTextChanged: {
            try {
                const parsed = JSON.parse(text)
                mergeConfig(parsed)
            } catch (e) {
                console.warn("Failed to parse config.json:", e)
            }
        }
    }
    
    function mergeConfig(userConfig) {
        if (!userConfig) return
        
        function merge(target, source) {
            for (const key in source) {
                if (source[key] !== null && typeof source[key] === 'object' && !Array.isArray(source[key])) {
                    if (!target[key]) target[key] = {}
                    merge(target[key], source[key])
                } else {
                    target[key] = source[key]
                }
            }
        }
        
        merge(root.options, userConfig.options || {})
        merge(root.sizes, userConfig.sizes || {})
        merge(root.animation, userConfig.animation || {})
        merge(root.rounding, userConfig.rounding || {})
        merge(root.font, userConfig.font || {})
    }
    
    Component.onCompleted: {
        if (!configFile.exists) {
            console.log("Config file not found, using defaults")
        }
    }
}