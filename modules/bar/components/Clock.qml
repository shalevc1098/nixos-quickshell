import qs.common
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    
    property string time: ""
    
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    
    Row {
        id: row
        spacing: 6
        anchors.centerIn: parent
        
        Text {
            text: "󰥔"  // Clock icon
            font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            color: Appearance.m3colors.on_surface_variant
        }
        
        Text {
            text: root.time
            font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Appearance.m3colors.on_surface
        }
    }
    
    Process {
        id: dateProc
        command: ["date", "+%H:%M"]
        running: true
        
        stdout: StdioCollector {
            onStreamFinished: root.time = this.text.trim()
        }
    }
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: dateProc.running = true
    }
}