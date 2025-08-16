pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    property QtObject overview: QtObject {
        property bool enable: true
        property real scale: 0.15
        property int rows: 2
        property int columns: 5
    }
    
    property QtObject search: QtObject {
        property int nonAppResultDelay: 200
        property string engineBaseUrl: "https://www.google.com/search?q="
        property var excludedSites: ["quora.com"]
        property bool sloppy: false
        property QtObject prefix: QtObject {
            property string action: "/"
            property string clipboard: ";"
            property string emojis: ":"
        }
    }
    
    property QtObject apps: QtObject {
        property string terminal: "foot"
    }
    
    property QtObject sizes: QtObject {
        property int searchWidth: 600
        property int searchWidthCollapsed: 400
        property int elevationMargin: 10
    }
    
    property QtObject animation: QtObject {
        property QtObject elementMove: QtObject {
            property int type: Easing.OutCubic
            property var bezierCurve: [0.4, 0.0, 0.2, 1.0]
        }
        property QtObject elementMoveFast: QtObject {
            property int duration: 200
            property int type: Easing.OutCubic
        }
    }
    
    property QtObject rounding: QtObject {
        property int large: 12
        property int screenRounding: 8
    }
    
    property QtObject font: QtObject {
        property QtObject pixelSize: QtObject {
            property int small: 14
            property int huge: 20
        }
        property QtObject family: QtObject {
            property string main: "SF Pro Display"
        }
    }

    property QtObject hacks: QtObject {
        property int arbitraryRaceConditionDelay: 20 // milliseconds
    }
}