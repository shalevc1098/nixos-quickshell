import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.DBusMenu

Item {
    id: root
    
    property var panelWindow: null  // Should be passed from Bar
    
    implicitWidth: trayRow.visible ? trayRow.implicitWidth : placeholderText.implicitWidth
    implicitHeight: 20
    
    // Custom menu component (using Scope and Loader like MPRIS popup)
    property bool menuOpen: false
    property var menuSourceRect: ({ x: 0, y: 0, width: 0, height: 0 })
    
    Scope {
        id: menuScope
        
        Loader {
            id: menuLoader
            active: root.menuOpen
            
            sourceComponent: SystemTrayMenu {
                id: customMenu
                menuOpener: root.currentMenuOpener
                sourceRect: root.menuSourceRect
                
                Component.onCompleted: {
                    visible = true
                }
                
                onVisibleChanged: {
                    if (!visible) {
                        root.menuOpen = false
                        root.currentMenuOpener = null
                    }
                }
            }
        }
    }
    
    // Property to store menu opener for extraction
    property var currentMenuOpener: null
    
    // Function to show custom menu at specific position
    function showCustomMenu(trayItem, mouseArea, menuOpener, menuAnchor) {
        if (!trayItem) {
            return false
        }
        
        console.log("showCustomMenu called for trayItem:", trayItem.id, "hasMenu:", trayItem.hasMenu)
        
        try {
            if (!menuOpener || !menuOpener.children) {
                console.log("No menuOpener or children")
                return false
            }
            
            // Store the menu opener so our menu component can access it
            root.currentMenuOpener = menuOpener
            
            // Calculate position relative to the tray icon
            const mapped = root.panelWindow.mapFromItem(mouseArea, 0, 0)
            const rect = {
                x: mapped.x,
                y: mapped.y,
                width: mouseArea.width,
                height: mouseArea.height
            }
            
            // Set properties and open menu
            root.menuSourceRect = rect
            root.menuOpen = true
            
            return true
        } catch (e) {
            console.log("Error showing custom menu:", e)
            return false
        }
    }
    
    // System tray logging removed - was for debugging only
    
    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 8
        
        Repeater {
            model: SystemTray.items
            
            delegate: Item {
                required property SystemTrayItem modelData
                
                width: 20
                height: 20
                
                // Show all tray items regardless of status
                // Status.Passive (0) = inactive but visible
                // Status.Active (1) = active 
                // Status.NeedsAttention (2) = needs attention
                visible: true
                
                // Menu anchor for context menus (fallback)
                QsMenuAnchor {
                    id: menuAnchor
                    menu: modelData.menu
                    anchor.window: root.panelWindow
                    
                    function updatePosition() {
                        if (!root.panelWindow) return
                        
                        try {
                            const mapped = root.panelWindow.mapFromItem(mouseArea, mouseArea.width / 2, 0)
                            if (mapped) {
                                anchor.rect.x = mapped.x
                                anchor.rect.y = 50 - 2  // Position slightly overlapping the bar
                            }
                        } catch (e) {
                            // Fallback: estimate position
                            let accumulatedX = 0
                            let current = mouseArea
                            
                            while (current && current !== root.panelWindow) {
                                accumulatedX += current.x
                                current = current.parent
                            }
                            
                            anchor.rect.x = accumulatedX + mouseArea.width / 2
                            anchor.rect.y = 50 - 2  // Position slightly overlapping the bar
                        }
                    }
                }
                
                // QsMenuOpener to access menu children - simplified like caelestia-dots
                QsMenuOpener {
                    id: menuOpener
                    menu: modelData.menu
                }
                
                
                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: CustomIconLoader.getIconSource(modelData.icon)
                    sourceSize.width: 32
                    sourceSize.height: 32
                    smooth: true
                    antialiasing: true
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    
                    onClicked: (mouse) => {
                        console.log("Tray item clicked:", mouse.button, "modelData.id:", modelData.id)
                        console.log("  menuOpener.children:", menuOpener.children)
                        console.log("  menuOpener.children.count:", menuOpener.children ? menuOpener.children.count : 0)
                        
                        if (mouse.button === Qt.LeftButton) {
                            // Left click - activate the item
                            if (modelData.onlyMenu && modelData.hasMenu) {
                                // If only menu, try custom menu first, fallback to default
                                console.log("Left click on menu-only item, showing custom menu")
                                if (!showCustomMenu(modelData, mouseArea, menuOpener, menuAnchor)) {
                                    menuAnchor.updatePosition()
                                    if (menuAnchor.anchor.window) {
                                        menuAnchor.open()
                                    }
                                }
                            } else {
                                // Otherwise, activate the item
                                console.log("Left click activation")
                                modelData.activate()
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            // Right click - ALWAYS show our custom menu first
                            console.log("Right click - showing custom menu")
                            if (!showCustomMenu(modelData, mouseArea, menuOpener, menuAnchor)) {
                                console.log("Custom menu failed, trying default")
                                // Only fallback to default if the app actually has a menu
                                if (modelData.hasMenu) {
                                    menuAnchor.updatePosition()
                                    if (menuAnchor.anchor.window) {
                                        menuAnchor.open()
                                    }
                                }
                            }
                        }
                    }
                    
                    onWheel: (wheel) => {
                        // Some apps support scroll events
                        if (modelData.scroll) {
                            modelData.scroll(wheel.angleDelta.x, wheel.angleDelta.y)
                        }
                    }
                    
                    StyledTooltip {
                        visible: parent.containsMouse
                        text: {
                            if (modelData.tooltipTitle && modelData.tooltipDescription) {
                                return `${modelData.tooltipTitle}\n${modelData.tooltipDescription}`
                            } else if (modelData.tooltipTitle) {
                                return modelData.tooltipTitle
                            } else if (modelData.title) {
                                return modelData.title
                            } else {
                                return modelData.id
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Show placeholder if no tray items
    Text {
        id: placeholderText
        anchors.centerIn: parent
        visible: SystemTray.items.values.length === 0
        text: "󰂜"  // Tray icon
        font.family: "SF Pro Display, JetBrainsMono Nerd Font Propo"
        font.pixelSize: 14
        color: Appearance.m3colors.on_surface_variant
        opacity: 0.3
    }
}