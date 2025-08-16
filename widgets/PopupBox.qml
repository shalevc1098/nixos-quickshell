import qs.common
import QtQuick
import QtQuick.Controls
import Quickshell

PopupWindow {
    id: popupBox
    
    // Required properties
    property var anchorWindow: null  // The parent window to anchor to
    property var anchorItem: null    // The item to position relative to (e.g., bellBubble)
    property bool showing: false     // Controls visibility
    
    // Customizable properties
    property int popupWidth: 400
    property int popupHeight: 300
    property int maxHeight: 500
    property int cornerRadius: 12
    property int xOffset: 0  // Additional x offset for fine-tuning position
    property int yOffset: 5  // Gap between anchor and popup
    property bool autoHeight: false  // If true, height adjusts to content
    
    // Content loader
    default property alias content: contentLoader.sourceComponent
    
    // Calculate anchor position
    anchor.window: anchorWindow
    anchor.rect.x: {
        if (!anchorItem || !anchorItem.parent) return 100
        // Get the absolute position of the anchor item
        var parent = anchorItem.parent
        var itemX = parent.x + anchorItem.x
        var itemCenterX = itemX + anchorItem.width / 2
        return itemCenterX - popupBox.implicitWidth / 2 + xOffset
    }
    anchor.rect.y: anchorWindow ? anchorWindow.implicitHeight + yOffset : 48
    
    implicitWidth: popupWidth
    implicitHeight: autoHeight ? Math.min(maxHeight, contentLoader.implicitHeight + 20) : popupHeight
    
    visible: showing && anchorWindow !== null
    color: "transparent"
    
    // Container with slide animation
    Item {
        anchors.fill: parent
        clip: true // Clip the sliding content
        
        Rectangle {
            id: backgroundRect
            width: parent.width
            height: parent.height
            radius: cornerRadius
            color: Appearance.m3colors.surface_container
            border.width: 1
            border.color: Appearance.m3colors.surface_container_high
            
            // Slide animation using y position
            y: popupBox.showing ? 0 : -height
            
            Behavior on y {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            
            // Content wrapper with fade animation
            Item {
                anchors.fill: parent
                anchors.margins: 10
                opacity: popupBox.showing ? 1 : 0
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
                
                Loader {
                    id: contentLoader
                    anchors.fill: parent
                }
            }
        }
    }
}