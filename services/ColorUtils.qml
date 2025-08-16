pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    function mix(color1, color2, ratio) {
        const r1 = color1.r
        const g1 = color1.g
        const b1 = color1.b
        const a1 = color1.a
        
        const r2 = color2.r
        const g2 = color2.g
        const b2 = color2.b
        const a2 = color2.a
        
        return Qt.rgba(
            r1 * (1 - ratio) + r2 * ratio,
            g1 * (1 - ratio) + g2 * ratio,
            b1 * (1 - ratio) + b2 * ratio,
            a1 * (1 - ratio) + a2 * ratio
        )
    }
    
    function transparentize(color, amount) {
        return Qt.rgba(color.r, color.g, color.b, color.a * (1 - amount))
    }
    
    function darken(color, amount) {
        const factor = 1 - amount
        return Qt.rgba(
            color.r * factor,
            color.g * factor,
            color.b * factor,
            color.a
        )
    }
    
    function lighten(color, amount) {
        const factor = 1 + amount
        return Qt.rgba(
            Math.min(color.r * factor, 1),
            Math.min(color.g * factor, 1),
            Math.min(color.b * factor, 1),
            color.a
        )
    }
}