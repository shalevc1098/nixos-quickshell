import qs.common
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell

Scope {
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
    property int yOffset: 0  // Gap between anchor and popup
    property bool autoHeight: false  // If true, height adjusts to content
    
    // Content property
    default property Component content: null
    
    Loader {
        id: popupLoader
        active: popupBox.showing
        
        sourceComponent: PanelWindow {
            id: popupWindow
            visible: true
            
            // Use the same screen as the anchor window
            screen: popupBox.anchorWindow ? popupBox.anchorWindow.screen : null
            
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            
            // Make fullscreen to catch clicks outside
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            
            // Fullscreen MouseArea to catch clicks outside
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    popupBox.showing = false
                }
            }
            
            // Main popup container - positioned relative to anchor
            Item {
                id: popupContainer
                
                // Calculate position relative to anchor within the screen-constrained popup window
                x: {
                    if (!popupBox.anchorItem || !popupBox.anchorWindow) {
                        console.log("PopupBox: Missing anchor references")
                        return 100
                    }
                    
                    // Calculate anchor item's position by walking up parent chain
                    let itemX = 0
                    let currentItem = popupBox.anchorItem
                    
                    // Walk up the parent chain until we reach the window
                    while (currentItem && currentItem !== popupBox.anchorWindow) {
                        if (currentItem.x !== undefined) {
                            itemX += currentItem.x
                        }
                        currentItem = currentItem.parent
                    }
                    
                    // Get anchor dimensions
                    const anchorWidth = popupBox.anchorItem.width || 0
                    const anchorCenterX = itemX + (anchorWidth / 2)
                    
                    // Calculate ideal centered position (relative to screen)
                    const idealX = anchorCenterX - (popupBox.popupWidth / 2) + popupBox.xOffset
                    
                    // Get screen dimensions  
                    const screen = popupBox.anchorWindow.screen || {}
                    const screenWidth = screen.width || 2560
                    const margin = 10
                    
                    // Calculate bounds within the screen (relative coordinates)
                    const minX = margin
                    const maxX = screenWidth - popupBox.popupWidth - margin
                    
                    // Apply smart positioning
                    let finalX = idealX
                    
                    // If ideal position is off-screen, adjust
                    if (idealX < minX) {
                        finalX = minX  // Stick to left edge
                    } else if (idealX > maxX) {
                        finalX = maxX  // Stick to right edge
                    }
                    
                    console.log("PopupBox X calc:",
                        "itemX:", itemX,
                        "anchorWidth:", anchorWidth,
                        "anchorCenterX:", anchorCenterX,
                        "idealX:", idealX,
                        "finalX:", finalX,
                        "screenWidth:", screenWidth,
                        "screen:", screen.name || "unknown")
                    
                    return finalX
                }
                
                y: {
                    if (!popupBox.anchorItem || !popupBox.anchorWindow) {
                        return 48 + popupBox.yOffset
                    }
                    
                    // Position below the bar (relative to screen since popup window is screen-constrained)
                    const barHeight = popupBox.anchorWindow.implicitHeight || 48
                    const finalY = barHeight + popupBox.yOffset
                    
                    console.log("PopupBox Y:", "barHeight:", barHeight, "finalY:", finalY)
                    return finalY
                }
                
                width: popupBox.popupWidth
                height: popupBox.autoHeight ? Math.min(popupBox.maxHeight, contentLoader.item ? contentLoader.item.implicitHeight + 20 : 100) : popupBox.popupHeight
                
                // MouseArea to prevent clicks on content from closing popup
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // Do nothing - just consume the click
                    }
                }
                
                // Shadow/elevation
                Rectangle {
                    anchors.fill: background
                    anchors.margins: -2
                    radius: popupBox.cornerRadius + 2
                    color: "transparent"
                    border.width: 0
                    
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowBlur: 0.5
                        shadowOpacity: 0.3
                        shadowVerticalOffset: 2
                    }
                }
                
                // Main background
                Rectangle {
                    id: background
                    anchors.fill: parent
                    anchors.margins: 8
                    radius: popupBox.cornerRadius
                    color: Appearance.m3colors.surface_container
                    clip: true
                    border.width: 1
                    border.color: Appearance.m3colors.surface_container_high
                    
                    // Content wrapper
                    Item {
                        anchors.fill: parent
                        anchors.margins: 10
                        
                        Loader {
                            id: contentLoader
                            sourceComponent: popupBox.content
                            anchors.fill: popupBox.autoHeight ? undefined : parent
                            width: parent.width
                            height: popupBox.autoHeight ? undefined : parent.height
                        }
                    }
                }
            }
        }
    }
}