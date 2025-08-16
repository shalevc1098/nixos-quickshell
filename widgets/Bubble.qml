import qs.common
import QtQuick

Rectangle {
    id: bubble
    
    default property alias content: contentLoader.sourceComponent
    property int horizontalPadding: 16
    property int verticalPadding: 6
    property int fixedHeight: 35
    
    signal clicked(var mouse)
    
    width: contentLoader.width + horizontalPadding * 2
    height: fixedHeight  // Fixed height for all bubbles
    radius: 20
    color: Appearance.m3colors.surface_container
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onClicked: (mouse) => {
            bubble.clicked(mouse)
        }
    }
    
    Loader {
        id: contentLoader
        anchors.centerIn: parent
        
        // Pass hover state to content
        property bool isHovered: mouseArea.containsMouse
    }
}