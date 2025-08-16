import qs.common
import QtQuick
import QtQuick.Controls
import Quickshell

PopupWindow {
    id: root
    
    property var trayItem: null
    property var menuItems: []
    property var sourceRect: ({ x: 0, y: 0, width: 0, height: 0 })
    
    // Auto-size to content (ensure minimum size)
    implicitWidth: Math.max(200, menuColumn.implicitWidth + 16)
    implicitHeight: Math.max(100, menuColumn.implicitHeight + 16)
    
    // Position below the tray icon
    anchor.rect.x: sourceRect.x - (implicitWidth / 2) + (sourceRect.width / 2)
    anchor.rect.y: sourceRect.y + sourceRect.height + 4
    
    color: "transparent"
    
    Component.onCompleted: {
        console.log("SystemTrayMenu created, anchor.window:", anchor.window)
    }
    
    // Main menu container
    Rectangle {
        anchors.fill: parent
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
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2
            
            Repeater {
                model: root.menuItems
                
                onItemAdded: (index, item) => {
                    console.log("Menu item added at index:", index)
                }
                
                delegate: Rectangle {
                    width: menuColumn.width
                    height: menuItem.type === "separator" ? 9 : 32
                    color: menuItem.type === "separator" ? "transparent" : 
                           (mouseArea.containsMouse ? Appearance.m3colors.surface_container_highest : "transparent")
                    radius: 4
                    
                    property var menuItem: modelData
                    
                    // Regular menu item content
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        visible: menuItem.type !== "separator"
                        
                        // Icon (if available)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: menuItem.icon || ""
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 14
                            color: Appearance.m3colors.on_surface
                            visible: text !== ""
                        }
                        
                        // Text
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: menuItem.text || ""
                            font.family: "SF Pro Display"
                            font.pixelSize: 13
                            color: menuItem.enabled !== false ? Appearance.m3colors.on_surface : Appearance.m3colors.on_surface_variant
                        }
                    }
                    
                    // Separator line for separators
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: Appearance.m3colors.surface_container
                        visible: menuItem.type === "separator"
                    }
                    
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: menuItem.type !== "separator"
                        enabled: menuItem.type !== "separator"
                        cursorShape: menuItem.enabled !== false ? Qt.PointingHandCursor : Qt.ArrowCursor
                        
                        onClicked: {
                            if (menuItem.enabled !== false && menuItem.action) {
                                menuItem.action()
                            }
                            root.visible = false
                        }
                    }
                    
                    // Hover animation
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }
        }
    }
    
    // Close menu when clicking outside
    MouseArea {
        anchors.fill: parent
        z: -10
        onClicked: root.visible = false
    }
    
    // Function to show the menu with items
    function showMenu(items, rect) {
        console.log("SystemTrayMenu.showMenu called with", items.length, "items")
        console.log("Source rect:", rect)
        console.log("Anchor window:", anchor.window)
        
        // Hide any existing menu first
        if (visible) {
            visible = false
        }
        
        menuItems = items || []
        sourceRect = rect || { x: 0, y: 0, width: 0, height: 0 }
        
        // Debug the menu size and position
        console.log("Menu size:", implicitWidth, "x", implicitHeight)
        console.log("Menu position:", anchor.rect.x, ",", anchor.rect.y)
        console.log("Setting visible to true")
        
        // Use Qt.callLater to ensure the menu items are set before showing
        Qt.callLater(() => {
            visible = true
            console.log("Menu visible:", visible)
        })
    }
    
    // Hide menu
    function hideMenu() {
        visible = false
    }
}