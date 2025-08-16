import qs.common
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    
    property string icon: ""
    property string label: ""
    property var command: []
    property real screenSize: 1080  // Default screen size
    
    signal executed()
    
    // Scale button size based on screen dimensions
    implicitWidth: screenSize * 0.1  // 10% of smallest screen dimension
    implicitHeight: screenSize * 0.1
    
    Process {
        id: process
        command: root.command
    }
    
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: mouseArea.containsMouse ? 
               Appearance.m3colors.surface_container_high : 
               Appearance.m3colors.surface_container
        border.width: 2
        border.color: mouseArea.containsMouse ? 
                      Appearance.m3colors.primary : 
                      "transparent"
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
        
        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
        
        Column {
            anchors.centerIn: parent
            spacing: 8
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.icon
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: root.screenSize * 0.035  // Scale icon based on screen
                color: mouseArea.containsMouse ? 
                       Appearance.m3colors.primary : 
                       Appearance.m3colors.on_surface
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.label
                font.family: "SF Pro Display"
                font.pixelSize: root.screenSize * 0.014  // Scale label based on screen
                font.weight: Font.Medium
                color: Appearance.m3colors.on_surface_variant
            }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            process.startDetached()
            root.executed()
        }
    }
}