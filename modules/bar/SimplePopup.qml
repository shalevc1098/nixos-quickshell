import qs.common
import qs.widgets
import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    id: simplePopupScope
    
    property alias barWindow: simplePopup.barWindow
    property alias bellBubble: simplePopup.bellBubble
    property alias showing: simplePopup.showing
    
    // Debug shortcut to test bell popup
    GlobalShortcut {
        appid: "quickshell"
        name: "bellPopupToggle"
        description: "Toggle bell popup"
        
        onPressed: {
            simplePopup.showing = !simplePopup.showing
            console.log("Bell popup toggled, showing:", simplePopup.showing)
        }
    }

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
                
                Component.onCompleted: {
                    console.log("SimplePopup text loaded: Hello World")
                }
            }
        }
    }
}
}