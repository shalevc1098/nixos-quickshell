import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.DBusMenu

Scope {
    id: trayExpandScope
    
    property var anchorWindow: null
    property var anchorItem: null
    property bool showing: false
    
    // Custom menu component (using Scope and Loader like SystemTray)
    property bool menuOpen: false
    property var menuSourceRect: ({ x: 0, y: 0, width: 0, height: 0 })
    property var currentMenuOpener: null
    
    Scope {
        id: menuScope
        
        Loader {
            id: menuLoader
            active: trayExpandScope.menuOpen
            
            sourceComponent: SystemTrayMenu {
                id: customMenu
                menuOpener: trayExpandScope.currentMenuOpener
                sourceRect: trayExpandScope.menuSourceRect
                
                Component.onCompleted: {
                    visible = true
                }
                
                onVisibleChanged: {
                    if (!visible) {
                        trayExpandScope.menuOpen = false
                        trayExpandScope.currentMenuOpener = null
                    }
                }
            }
        }
    }
    
    // Function to show custom menu at specific position (same as SystemTray)
    function showCustomMenu(trayItem, mouseArea, menuOpener, anchorWindow, mouseX, mouseY) {
        if (!trayItem) {
            return false
        }
        
        try {
            if (!menuOpener || !menuOpener.children) {
                return false
            }
            
            // Store the menu opener so our menu component can access it
            trayExpandScope.currentMenuOpener = menuOpener
            
            // Calculate position at mouse cursor
            const mapped = anchorWindow.mapFromItem(mouseArea, mouseX, mouseY)
            const rect = {
                x: mapped.x,
                y: mapped.y,
                width: 1,  // Use 1x1 rect for mouse position
                height: 1
            }
            
            // Set properties and open menu
            trayExpandScope.menuSourceRect = rect
            trayExpandScope.menuOpen = true
            
            return true
        } catch (e) {
            return false
        }
    }
    
    // Debug shortcut for testing the tray popup (remove this in production)
    GlobalShortcut {
        appid: "quickshell"
        name: "trayExpandToggle"
        description: "Toggle tray expand popup"
        
        onPressed: {
            trayExpandScope.showing = !trayExpandScope.showing
        }
    }
    
    // Debug shortcut to test menu display for first tray item
    GlobalShortcut {
        appid: "quickshell"
        name: "trayMenuTest"
        description: "Test tray menu display"
        
        onPressed: {
            if (SystemTray.items.values.length > 0) {
                const firstItem = SystemTray.items.values[0]
                
                if (firstItem.hasMenu) {
                    // Try different position values
                    
                    // Test with different coordinates and windows
                    firstItem.display(trayExpandScope.anchorWindow, 100, 100)
                    
                    // Also try with anchorWindow after a delay
                    Qt.callLater(() => {
                        firstItem.display(trayExpandScope.anchorWindow, 200, 200)
                    })
                }
            } else {
            }
        }
    }

    Loader {
        id: trayExpandLoader
        active: trayExpandScope.showing
        
        sourceComponent: PanelWindow {
            id: trayExpandWindow
            visible: true
            
            property int iconSize: 16  // Same as main tray
            property int cellSize: 28  // Compact cell size
            property int gridPadding: 6
            property int gridSpacing: 2  // Small gap like main tray
            property int columns: Math.min(4, SystemTray.items.values.length)  // Use actual count if less than 4
            
            property int popupWidth: columns * cellSize + (columns - 1) * gridSpacing + gridPadding * 2
            property int popupHeight: Math.ceil(SystemTray.items.values.length / columns) * cellSize + 
                         Math.max(0, Math.ceil(SystemTray.items.values.length / columns) - 1) * gridSpacing + 
                         gridPadding * 2
            
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            
            // Full screen for click-outside detection
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            
            // Click outside handler
            MouseArea {
                anchors.fill: parent
                onClicked: trayExpandScope.showing = false
            }
            
            // Popup container positioned at anchor
            Item {
                x: {
                    if (!trayExpandScope.anchorItem || !trayExpandScope.anchorWindow) return 100
                    
                    // Try to find the absolute position by walking up the parent chain
                    let totalX = 0
                    let current = trayExpandScope.anchorItem
                    
                    while (current && current !== trayExpandScope.anchorWindow) {
                        totalX += current.x || 0
                        current = current.parent
                    }
                    
                    // Calculate center position
                    const centerX = totalX + trayExpandScope.anchorItem.width / 2
                    const popupHalfWidth = trayExpandWindow.popupWidth / 2
                    return centerX - popupHalfWidth
                }
                y: 50  // Below the bar
                width: trayExpandWindow.popupWidth
                height: trayExpandWindow.popupHeight
                
                // Prevent clicks on popup from closing
                MouseArea {
                    anchors.fill: parent
                    // Just consume the click
                }
                
                // Background with popup appearance
                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: Appearance.m3colors.surface_container
                    border.width: 1
                    border.color: Appearance.m3colors.surface_container_high
                    
                    // Grid with dynamic sizing
                    Grid {
                        anchors.centerIn: parent
                        anchors.margins: trayExpandWindow.gridPadding
                        columns: trayExpandWindow.columns
                        spacing: trayExpandWindow.gridSpacing
                        
                        Repeater {
                            model: SystemTray.items
                            
                            Item {
                                required property SystemTrayItem modelData
                                
                                width: trayExpandWindow.cellSize
                                height: trayExpandWindow.cellSize
                                
                                // Menu anchor for context menus (fallback)
                                QsMenuAnchor {
                                    id: menuAnchor
                                    menu: modelData.menu
                                    anchor.window: trayExpandScope.anchorWindow
                                    
                                    function updatePosition() {
                                        if (!trayExpandScope.anchorWindow) return
                                        
                                        try {
                                            const mapped = trayExpandScope.anchorWindow.mapFromItem(mouseArea, mouseArea.width / 2, 0)
                                            if (mapped) {
                                                anchor.rect.x = mapped.x
                                                anchor.rect.y = 50 - 2  // Position slightly overlapping the bar
                                            }
                                        } catch (e) {
                                            // Fallback: estimate position
                                            let accumulatedX = 0
                                            let current = mouseArea
                                            
                                            while (current && current !== trayExpandScope.anchorWindow) {
                                                accumulatedX += current.x
                                                current = current.parent
                                            }
                                            
                                            anchor.rect.x = accumulatedX + mouseArea.width / 2
                                            anchor.rect.y = 50 - 2  // Position slightly overlapping the bar
                                        }
                                    }
                                }
                                
                                // QsMenuOpener to access menu children
                                QsMenuOpener {
                                    id: menuOpener
                                    menu: modelData.menu
                                }
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: mouseArea.containsMouse ? Appearance.m3colors.surface_container_highest : "transparent"
                                }
                                
                                Image {
                                    anchors.centerIn: parent
                                    width: trayExpandWindow.iconSize
                                    height: trayExpandWindow.iconSize
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
                                        if (mouse.button === Qt.RightButton) {
                                            // Right click - ALWAYS show our custom menu first
                                            if (!trayExpandScope.showCustomMenu(modelData, mouseArea, menuOpener, trayExpandScope.anchorWindow, mouse.x, mouse.y)) {
                                                // Only fallback to default if the app actually has a menu
                                                if (modelData.hasMenu) {
                                                    menuAnchor.updatePosition()
                                                    if (menuAnchor.anchor.window) {
                                                        menuAnchor.open()
                                                    }
                                                }
                                            }
                                        } else if (mouse.button === Qt.LeftButton) {
                                            // Left click - activate the item or show menu
                                            if (modelData.onlyMenu && modelData.hasMenu) {
                                                // If only menu, try custom menu first, fallback to default
                                                if (!trayExpandScope.showCustomMenu(modelData, mouseArea, menuOpener, trayExpandScope.anchorWindow, mouse.x, mouse.y)) {
                                                    menuAnchor.updatePosition()
                                                    if (menuAnchor.anchor.window) {
                                                        menuAnchor.open()
                                                    }
                                                }
                                            } else {
                                                // Otherwise, activate the item
                                                modelData.activate()
                                                trayExpandScope.showing = false
                                            }
                                        } else if (mouse.button === Qt.MiddleButton) {
                                            modelData.secondaryActivate()
                                        }
                                    }
                                }
                                
                                StyledTooltip {
                                    visible: mouseArea.containsMouse
                                    text: modelData.tooltipTitle || modelData.title || modelData.id
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}