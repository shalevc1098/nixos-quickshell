import qs.common
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    implicitWidth: distroIcon.implicitWidth
    implicitHeight: distroIcon.implicitHeight
    
    property string distroId: ""
    property var distroIcons: ({
        "arch": "󰣇",
        "nixos": "󱄅",
        "ubuntu": "󰕈",
        "debian": "󰣚",
        "fedora": "󰣛",
        "manjaro": "󱘊",
        "endeavouros": "󰣇",
        "pop": "󰰾",
        "mint": "󰣭",
        "opensuse": "󰣱",
        "gentoo": "󰣨",
        "void": "󰕆",
        "alpine": "󰂚"
    })
    
    Text {
        id: distroIcon
        text: {
            const icon = parent.distroIcons[parent.distroId]
            return `${icon} ` || "󰌽"  // Default Linux icon if distro not found
        }
        font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
        font.pixelSize: 18
        color: Appearance.m3colors.primary
        anchors.centerIn: parent
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
    
    Process {
        id: distroProc
        command: ["sh", "-c", "grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '\"'"]
        running: true
        
        stdout: StdioCollector {
            onStreamFinished: {
                distroId = this.text.trim().toLowerCase()
            }
        }
    }
    
    Component.onCompleted: {
        distroProc.running = true
    }
}