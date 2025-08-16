pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: appearance
    
    // Material 3 color scheme with default values
    property QtObject m3colors: QtObject {
        property color background: "#0b141b"
        property color error: "#ffb4ab"
        property color error_container: "#93000a"
        property color inverse_on_surface: "#293138"
        property color inverse_primary: "#00658f"
        property color inverse_surface: "#dae4ed"
        property color on_background: "#dae4ed"
        property color on_error: "#690005"
        property color on_error_container: "#ffdad6"
        property color on_primary: "#00344c"
        property color on_primary_container: "#c7e7ff"
        property color on_primary_fixed: "#001e2e"
        property color on_primary_fixed_variant: "#004c6d"
        property color on_secondary: "#1c314b"
        property color on_secondary_container: "#d3e4ff"
        property color on_secondary_fixed: "#041c35"
        property color on_secondary_fixed_variant: "#344863"
        property color on_surface: "#dae4ed"
        property color on_surface_variant: "#bec8d0"
        property color on_tertiary: "#212e5a"
        property color on_tertiary_container: "#dce1ff"
        property color on_tertiary_fixed: "#091844"
        property color on_tertiary_fixed_variant: "#384572"
        property color outline: "#89929a"
        property color outline_variant: "#3f484f"
        property color primary: "#85cfff"
        property color primary_container: "#004c6d"
        property color primary_fixed: "#c7e7ff"
        property color primary_fixed_dim: "#85cfff"
        property color scrim: "#000000"
        property color secondary: "#b3c8e9"
        property color secondary_container: "#344863"
        property color secondary_fixed: "#d3e4ff"
        property color secondary_fixed_dim: "#b3c8e9"
        property color shadow: "#000000"
        property color surface: "#0b141b"
        property color surface_bright: "#313a41"
        property color surface_container: "#182127"
        property color surface_container_high: "#222b32"
        property color surface_container_highest: "#2d363d"
        property color surface_container_low: "#141d23"
        property color surface_container_lowest: "#070f15"
        property color surface_dim: "#0b141b"
        property color surface_tint: "#85cfff"
        property color surface_variant: "#3f484f"
        property color tertiary: "#b8c4fa"
        property color tertiary_container: "#384572"
        property color tertiary_fixed: "#dce1ff"
        property color tertiary_fixed_dim: "#b8c4fa"
    }
}