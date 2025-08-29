import qs.common
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.DBusMenu

PanelWindow {
    id: root
    
    property var trayItem: null
    property var menuOpener: null  // Pass the QsMenuOpener instead of extracted items
    property var sourceRect: ({ x: 0, y: 0, width: 0, height: 0 })
    
    visible: true
    
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    
    // Make fullscreen to catch clicks outside (like MPRIS popup)
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    
    Component.onCompleted: {
        console.log("SystemTrayMenu created as PanelWindow")
    }
    
    // Fullscreen MouseArea to catch clicks outside
    MouseArea {
        anchors.fill: parent
        onClicked: {
            console.log("Click outside menu, closing")
            root.visible = false
        }
    }
    
    // Main menu container positioned at sourceRect with boundary checking
    Item {
        property int menuX: {
            // Center the menu on the source icon
            let x = sourceRect.x - menuContainer.width / 2 + sourceRect.width / 2
            
            // Check if menu goes off the right edge
            if (x + menuContainer.width > root.width) {
                x = root.width - menuContainer.width - 10  // 10px margin from edge
            }
            
            // Check if menu goes off the left edge
            if (x < 10) {
                x = 10  // 10px margin from edge
            }
            
            return x
        }
        
        property int menuY: {
            // Try to position below the bar
            let y = 50  // Bar height 48 + small gap 2
            
            // If menu would go off bottom, position above the bar
            if (y + menuContainer.height > root.height - 10) {
                y = sourceRect.y - menuContainer.height - 2  // Position above with 2px gap
            }
            
            return y
        }
        
        x: menuX
        y: menuY
        width: menuContainer.width
        height: menuContainer.height
        
        // MouseArea to prevent clicks on menu from closing
        MouseArea {
            anchors.fill: parent
            onClicked: {
                // Do nothing - just consume the click
            }
        }
        
        Rectangle {
            id: menuContainer
            width: Math.max(200, menuColumn.implicitWidth + 16)
            height: Math.max(100, menuColumn.implicitHeight + 16)
            color: Appearance.m3colors.surface_container_high
            radius: 8
            
            // Drop shadow effect
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                color: "transparent"
                radius: parent.radius + 2
                border.color: Appearance.m3colors.surface_container
                border.width: 1
                opacity: 0.3
                z: -1
            }
            
            Column {
                id: menuColumn
                x: 8
                y: 8
                width: parent.width - 16
                spacing: 2
            
            Repeater {
                model: root.menuOpener ? root.menuOpener.children : []
                
                onItemAdded: (index, item) => {
                    console.log("Menu item added at index:", index)
                }
                
                delegate: Loader {
                    required property var modelData  // DBusMenuItem from the model
                    required property int index
                    
                    // Filter out empty items and consecutive separators
                    active: {
                        // Skip empty non-separator items
                        if (!modelData.isSeparator && (!modelData.text || modelData.text.trim() === "")) {
                            return false
                        }
                        
                        // Check for consecutive separators
                        if (modelData.isSeparator && index > 0) {
                            // Access the values array to check previous item
                            let prevItem = root.menuOpener.children.values[index - 1]
                            if (prevItem && prevItem.isSeparator) {
                                console.log("Skipping consecutive separator at index", index)
                                return false
                            }
                        }
                        
                        return true
                    }
                    
                    sourceComponent: Rectangle {
                        width: menuColumn.width
                        height: modelData.isSeparator ? 9 : 32
                        color: modelData.isSeparator ? "transparent" : 
                               (mouseArea.containsMouse ? Appearance.m3colors.surface_container_highest : "transparent")
                        radius: 4
                    
                    // Regular menu item content
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        visible: !modelData.isSeparator
                        
                        // Icon (if available) - supports both font icons and image icons
                        Loader {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            active: modelData.icon && modelData.icon !== ""
                            
                            sourceComponent: {
                                // Check if it's an image path (freedesktop icon)
                                if (modelData.icon && modelData.icon.startsWith("image://")) {
                                    return imageIconComponent
                                } else if (modelData.icon && modelData.icon !== "") {
                                    return fontIconComponent
                                }
                                return null
                            }
                            
                            Component {
                                id: fontIconComponent
                                Text {
                                    text: modelData.icon
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 14
                                    color: modelData.enabled ? 
                                        Appearance.m3colors.on_surface : 
                                        Appearance.m3colors.on_surface_variant
                                }
                            }
                            
                            Component {
                                id: imageIconComponent
                                Item {
                                    width: 16
                                    height: 16
                                    
                                    Image {
                                        id: iconImage
                                        anchors.fill: parent
                                        source: modelData.icon
                                        sourceSize.width: 16
                                        sourceSize.height: 16
                                        smooth: true
                                        antialiasing: true
                                        visible: false  // Hidden, used as source for ColorOverlay
                                    }
                                    
                                    ColorOverlay {
                                        anchors.fill: iconImage
                                        source: iconImage
                                        color: modelData.enabled ? 
                                            Appearance.m3colors.on_surface : 
                                            Appearance.m3colors.on_surface_variant
                                    }
                                }
                            }
                        }
                        
                        // Text
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.text || ""
                            font.family: "SF Pro Display"
                            font.pixelSize: 13
                            color: modelData.enabled ? Appearance.m3colors.on_surface : Appearance.m3colors.on_surface_variant
                        }
                    }
                    
                    // Separator line for separators
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: Appearance.m3colors.outline_variant
                        opacity: 0.5
                        visible: modelData.isSeparator
                    }
                    
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: !modelData.isSeparator
                        enabled: !modelData.isSeparator && modelData.enabled
                        cursorShape: modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        
                        onClicked: {
                            console.log("Menu item clicked:", modelData.text)
                            if (modelData.enabled) {
                                console.log("Triggering DBusMenuItem for:", modelData.text)
                                try {
                                    modelData.triggered()
                                } catch (e) {
                                    console.log("Error triggering:", e)
                                }
                            }
                            root.visible = false
                        }
                    }
                    }  // Rectangle
                }  // sourceComponent
            }  // Loader delegate
            }  // Repeater
        }  // Column
    }  // menuContainer
}