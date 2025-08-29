import qs.common
import qs.widgets
import QtQuick

PopupBox {
    id: simplePopup
    
    property var barWindow: null
    property var bellBubble: null
    
    anchorWindow: barWindow
    anchorItem: bellBubble
    
    popupWidth: 200
    popupHeight: 80
    xOffset: 0  // No offset - center under bell
    
    content: Component {
        Item {
            anchors.fill: parent
            
            Text {
                anchors.centerIn: parent
                text: "Hello World"
                font.family: "SF Pro Display"
                font.pixelSize: 16
                color: Appearance.m3colors.on_surface
            }
        }
    }
}