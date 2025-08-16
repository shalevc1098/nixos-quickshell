import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root
    
    property var panelWindow: null  // Should be passed from Bar
    
    implicitWidth: trayRow.visible ? trayRow.implicitWidth : placeholderText.implicitWidth
    implicitHeight: 20
    
    // Custom menu component
    SystemTrayMenu {
        id: customMenu
        anchor.window: root.panelWindow
    }
    
    // Function to create app-specific menu items
    function createAppSpecificMenu(trayItem) {
        const appId = trayItem.id || ""
        console.log("Creating app-specific menu for:", appId)
        
        // Create menu items based on the app type
        switch (appId) {
            case "spotify-client":
            case "spotify":
                return [
                    {
                        type: "action",
                        text: "Show Spotify",
                        icon: "󰓇",
                        enabled: true,
                        action: function() { 
                            trayItem.activate()
                        }
                    },
                    {
                        type: "action",
                        text: "Play/Pause",
                        icon: "󰐊",
                        enabled: true,
                        action: function() {
                            // Use playerctl or similar for media control
                            console.log("Play/Pause clicked")
                        }
                    },
                    {
                        type: "separator",
                        text: "",
                        enabled: false
                    },
                    {
                        type: "action",
                        text: "Quit Spotify",
                        icon: "󰅖",
                        enabled: true,
                        action: function() {
                            console.log("Quit Spotify clicked")
                        }
                    }
                ]
                
            case "blueman":
            case "blueman-applet":
                return [
                    {
                        type: "action",
                        text: "Open Bluetooth Manager",
                        icon: "󰂯",
                        enabled: true,
                        action: function() { 
                            trayItem.activate()
                        }
                    },
                    {
                        type: "action",
                        text: "Toggle Bluetooth",
                        icon: "󰂲",
                        enabled: true,
                        action: function() {
                            console.log("Toggle Bluetooth clicked")
                        }
                    },
                    {
                        type: "separator",
                        text: "",
                        enabled: false
                    },
                    {
                        type: "action",
                        text: "Exit",
                        icon: "󰅖",
                        enabled: true,
                        action: function() {
                            console.log("Exit Blueman clicked")
                        }
                    }
                ]
                
            case "discord":
            case "vesktop":
                return [
                    {
                        type: "action",
                        text: "Show Discord",
                        icon: "󰙯",
                        enabled: true,
                        action: function() { 
                            trayItem.activate()
                        }
                    },
                    {
                        type: "action",
                        text: "Toggle Mute",
                        icon: "󰖁",
                        enabled: true,
                        action: function() {
                            console.log("Toggle mute clicked")
                        }
                    },
                    {
                        type: "separator",
                        text: "",
                        enabled: false
                    },
                    {
                        type: "action",
                        text: "Quit Discord",
                        icon: "󰅖",
                        enabled: true,
                        action: function() {
                            console.log("Quit Discord clicked")
                        }
                    }
                ]
                
            default:
                // Generic menu for unknown apps
                return [
                    {
                        type: "action",
                        text: "Show Application",
                        icon: "󰍉",
                        enabled: true,
                        action: function() { 
                            trayItem.activate()
                        }
                    },
                    {
                        type: "separator",
                        text: "",
                        enabled: false
                    },
                    {
                        type: "action",
                        text: "Open Default Menu",
                        icon: "󰍉",
                        enabled: trayItem.hasMenu,
                        action: function() {
                            console.log("Opening default menu fallback")
                            // This will trigger the default menu
                            if (trayItem.hasMenu) {
                                // Use the QsMenuAnchor as fallback
                                const mouseArea = arguments[0] // Will be passed when called
                                if (mouseArea && mouseArea.parent && mouseArea.parent.menuAnchor) {
                                    mouseArea.parent.menuAnchor.updatePosition()
                                    mouseArea.parent.menuAnchor.open()
                                }
                            }
                        }
                    },
                    {
                        type: "action",
                        text: "Exit",
                        icon: "󰅖",
                        enabled: true,
                        action: function() {
                            console.log("Exit application clicked")
                        }
                    }
                ]
        }
    }
    
    
    // Function to show custom menu at specific position
    function showCustomMenu(trayItem, mouseArea, menuOpener) {
        if (!trayItem) {
            return false
        }
        
        console.log("showCustomMenu called for trayItem:", trayItem.id, "hasMenu:", trayItem.hasMenu)
        
        try {
            let menuItems = []
            
            // Try to get items from the menuOpener first
            if (menuOpener && menuOpener.children) {
                console.log("Trying to extract from menuOpener.children")
                menuItems = extractMenuFromOpener(menuOpener)
            }
            
            // If no items found, use app-specific menu
            if (menuItems.length === 0) {
                console.log("Using app-specific menu as fallback")
                menuItems = createAppSpecificMenu(trayItem)
            }
            
            console.log("Menu items to show:", menuItems.length)
            
            // Calculate position relative to the tray icon
            const mapped = root.panelWindow.mapFromItem(mouseArea, 0, 0)
            const rect = {
                x: mapped.x,
                y: mapped.y,
                width: mouseArea.width,
                height: mouseArea.height
            }
            
            customMenu.showMenu(menuItems, rect)
            return true
        } catch (e) {
            console.log("Error showing custom menu:", e)
            return false
        }
    }
    
    // Function to extract menu items from QsMenuOpener
    function extractMenuFromOpener(opener) {
        if (!opener || !opener.children) {
            console.log("No opener or children")
            return []
        }
        
        const items = []
        const childrenModel = opener.children
        const count = childrenModel.count || 0
        
        console.log("Extracting from opener, children count:", count)
        
        for (let i = 0; i < count; i++) {
            try {
                // ObjectModel uses get() method
                const child = childrenModel.get(i)
                
                if (!child) {
                    console.log(`Child ${i} is null`)
                    continue
                }
                
                console.log(`Processing child ${i}:`, child)
                console.log(`Child properties:`, Object.getOwnPropertyNames(child))
                
                // Check if it's a separator
                if (child.isSeparator || child.separator) {
                    items.push({
                        type: "separator",
                        text: "",
                        enabled: false
                    })
                } else {
                    // Extract menu item properties - QsMenuEntry properties
                    const text = child.text || child.label || child.title || `Item ${i + 1}`
                    const enabled = child.enabled !== false
                    const hasChildren = child.hasChildren || false
                    const icon = child.icon || ""
                    
                    items.push({
                        type: "action",
                        text: text,
                        icon: icon,
                        enabled: enabled,
                        hasSubmenu: hasChildren,
                        action: function() {
                            console.log("Menu item clicked:", text)
                            // QsMenuEntry has trigger() method
                            if (child.trigger) {
                                console.log("Triggering menu item")
                                child.trigger()
                            } else if (child.activate) {
                                console.log("Activating menu item")
                                child.activate()
                            } else {
                                console.log("No trigger method found for item")
                            }
                        }
                    })
                }
            } catch (e) {
                console.log(`Error processing child ${i}:`, e)
            }
        }
        
        console.log("Extracted items:", items.length)
        return items
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
                
                // QsMenuOpener to access menu children
                QsMenuOpener {
                    id: menuOpener
                    menu: modelData.menu
                    
                    property var menuChildren: children
                    property bool menuLoaded: false
                    
                    onMenuChanged: {
                        console.log("MenuOpener menu changed for:", modelData.id)
                        console.log("Menu object:", menu)
                        
                        if (menu) {
                            console.log("Menu type:", typeof menu)
                            console.log("Menu properties/methods:", Object.getOwnPropertyNames(menu))
                            
                            // Try to access menu internals
                            for (let prop in menu) {
                                try {
                                    const value = menu[prop]
                                    const type = typeof value
                                    if (type === "function") {
                                        console.log(`  ${prop}: [function]`)
                                    } else if (type === "object" && value) {
                                        console.log(`  ${prop}: [object]`, value.constructor ? value.constructor.name : "")
                                    } else {
                                        console.log(`  ${prop}:`, value)
                                    }
                                } catch (e) {
                                    console.log(`  ${prop}: [error accessing]`)
                                }
                            }
                        }
                        
                        console.log("Children model:", children)
                        if (children) {
                            console.log("Children count:", children.count || 0)
                        }
                    }
                    
                    onChildrenChanged: {
                        console.log("MenuOpener children changed for:", modelData.id)
                        console.log("New children:", children)
                        if (children) {
                            const count = children.count || 0
                            console.log("Children count:", count)
                            
                            // Try to access individual items
                            for (let i = 0; i < count; i++) {
                                try {
                                    const item = children.get(i)
                                    console.log(`Child ${i}:`, item)
                                    if (item) {
                                        console.log("Item type:", typeof item)
                                        console.log("Item properties:", Object.getOwnPropertyNames(item))
                                        
                                        // Try to log specific properties
                                        if (item.text) console.log("  - text:", item.text)
                                        if (item.label) console.log("  - label:", item.label)
                                        if (item.icon) console.log("  - icon:", item.icon)
                                        if (item.enabled !== undefined) console.log("  - enabled:", item.enabled)
                                        if (item.isSeparator !== undefined) console.log("  - isSeparator:", item.isSeparator)
                                    }
                                } catch (e) {
                                    console.log(`Error accessing child ${i}:`, e)
                                }
                            }
                        }
                    }
                    
                    Component.onCompleted: {
                        console.log("MenuOpener completed for:", modelData.id)
                        console.log("Initial menu:", menu)
                        console.log("Initial children:", children)
                        
                        // Delay checking for children after component is ready
                        Qt.callLater(() => {
                            if (children && children.count > 0) {
                                console.log("Children available after delay for:", modelData.id)
                                console.log("Children count:", children.count)
                            }
                        })
                    }
                    
                    // Function to get menu items
                    function getMenuItems() {
                        const items = []
                        if (children && children.count > 0) {
                            for (let i = 0; i < children.count; i++) {
                                const item = children.get(i)
                                if (item) {
                                    items.push(item)
                                }
                            }
                        }
                        return items
                    }
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
                        
                        if (mouse.button === Qt.LeftButton) {
                            // Left click - activate the item
                            if (modelData.onlyMenu && modelData.hasMenu) {
                                // If only menu, try custom menu first, fallback to default
                                console.log("Left click on menu-only item, showing custom menu")
                                if (!showCustomMenu(modelData, mouseArea, menuOpener)) {
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
                            if (!showCustomMenu(modelData, mouseArea, menuOpener)) {
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