import qs.common
import qs.widgets
import QtQuick
import QtQuick.Controls
import Quickshell

PopupBox {
    id: popupBox
    
    popupWidth: 200  // Space for 4 icons per row at ~50px each
    popupHeight: 100  // Space for about 2 rows
    xOffset: 0  // Center under the arrow
    
    content: Component {
        Item {
            anchors.fill: parent
            
            // Grid for tray icons (empty for now)
            Grid {
                id: trayGrid
                anchors.fill: parent
                anchors.margins: 12
                columns: 4
                spacing: 8
                
                // Placeholder text for now
                Text {
                    text: "Tray icons will go here"
                    font.family: "SF Pro Display"
                    font.pixelSize: 12
                    color: Appearance.m3colors.on_surface_variant
                }
            }
        }
    }
}