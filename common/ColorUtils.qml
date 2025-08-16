pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    // Mix two colors by a given percentage
    function mix(color1, color2, percentage = 0.5) {
        var c1 = Qt.color(color1)
        var c2 = Qt.color(color2)
        return Qt.rgba(
            percentage * c1.r + (1 - percentage) * c2.r,
            percentage * c1.g + (1 - percentage) * c2.g,
            percentage * c1.b + (1 - percentage) * c2.b,
            percentage * c1.a + (1 - percentage) * c2.a
        )
    }

    // Transparentize a color by a given percentage
    function transparentize(color, percentage = 1) {
        var c = Qt.color(color)
        return Qt.rgba(c.r, c.g, c.b, c.a * (1 - percentage))
    }

    // Adapt color1 to the accent (hue and saturation) of color2
    function adaptToAccent(color1, color2) {
        var c1 = Qt.color(color1)
        var c2 = Qt.color(color2)
        
        var hue = c2.hslHue
        var sat = c2.hslSaturation
        var light = c1.hslLightness
        var alpha = c1.a
        
        return Qt.hsla(hue, sat, light, alpha)
    }

    // Apply alpha to a color
    function applyAlpha(color, alpha) {
        var c = Qt.color(color)
        var a = Math.max(0, Math.min(1, alpha))
        return Qt.rgba(c.r, c.g, c.b, a)
    }
}