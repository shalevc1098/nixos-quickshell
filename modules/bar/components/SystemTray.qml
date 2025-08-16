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
    property var menuItems: []
    property var menuSourceRect: ({ x: 0, y: 0, width: 0, height: 0 })
    
    Scope {
        id: menuScope
        
        Loader {
            id: menuLoader
            active: root.menuOpen
            
            sourceComponent: SystemTrayMenu {
                id: customMenu
                menuItems: root.menuItems
                sourceRect: root.menuSourceRect
                
                Component.onCompleted: {
                    visible = true
                }
                
                onVisibleChanged: {
                    if (!visible) {
                        root.menuOpen = false
                    }
                }
            }
        }
    }
    
    // Function to create app-specific menu items
    function createAppSpecificMenu(trayItem, menuAnchor) {
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
                // For blueman, try to use the default menu instead
                // since it has many dynamic options based on connected devices
                return [
                    {
                        type: "action",
                        text: "Open Default Blueman Menu",
                        icon: "󰂯",
                        enabled: true,
                        action: function() { 
                            // Close our menu and open the default one
                            root.menuOpen = false
                            Qt.callLater(() => {
                                if (menuAnchor) {
                                    menuAnchor.updatePosition()
                                    menuAnchor.open()
                                }
                            })
                        }
                    },
                    {
                        type: "separator",
                        text: "",
                        enabled: false
                    },
                    {
                        type: "action",
                        text: "Open Bluetooth Settings",
                        icon: "󰂯",
                        enabled: true,
                        action: function() { 
                            trayItem.activate()
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
    function showCustomMenu(trayItem, mouseArea, menuOpener, menuAnchor) {
        if (!trayItem) {
            return false
        }
        
        console.log("showCustomMenu called for trayItem:", trayItem.id, "hasMenu:", trayItem.hasMenu)
        
        try {
            let items = []
            
            // Use the extractedItems collected by the Repeater
            if (menuOpener && menuOpener.extractedItems && menuOpener.extractedItems.length > 0) {
                console.log("Using", menuOpener.extractedItems.length, "pre-extracted DBus menu items")
                items = menuOpener.extractedItems
            }
            
            // If no items found, use app-specific menu as fallback
            if (items.length === 0) {
                console.log("No DBus menu items found, using app-specific menu as fallback")
                items = createAppSpecificMenu(trayItem, menuAnchor)
            } else {
                console.log("Successfully using", items.length, "DBus menu items")
            }
            
            console.log("Menu items to show:", items.length)
            
            // Calculate position relative to the tray icon
            const mapped = root.panelWindow.mapFromItem(mouseArea, 0, 0)
            const rect = {
                x: mapped.x,
                y: mapped.y,
                width: mouseArea.width,
                height: mouseArea.height
            }
            
            // Set properties and open menu
            root.menuItems = items
            root.menuSourceRect = rect
            root.menuOpen = true
            
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
        
        // Try different ways to get the count
        let count = 0
        if (childrenModel.count !== undefined) {
            count = childrenModel.count
        } else {
            // Try to iterate with a reasonable maximum
            for (let i = 0; i < 100; i++) {
                try {
                    const item = childrenModel.get(i)
                    if (item) {
                        count++
                    } else {
                        break
                    }
                } catch (e) {
                    break
                }
            }
        }
        
        console.log("Extracting from opener, detected count:", count)
        
        for (let i = 0; i < count; i++) {
            try {
                // ObjectModel uses get() method
                const child = childrenModel.get(i)
                
                if (!child) {
                    console.log(`Child ${i} is null`)
                    continue
                }
                
                console.log(`Processing DBusMenuItem ${i}:`)
                console.log(`  Text: ${child.text}`)
                console.log(`  Enabled: ${child.enabled}`)
                console.log(`  IsSeparator: ${child.isSeparator}`)
                
                // Check if it's a separator
                if (child.isSeparator) {
                    items.push({
                        type: "separator",
                        text: "",
                        enabled: false
                    })
                } else {
                    // DBusMenuItem has these properties available:
                    // text, enabled, isSeparator, icon, hasChildren, buttonType, checkState
                    // and methods: triggered(), opened(), closed(), display(), updateLayout()
                    const text = child.text || `Item ${i + 1}`
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
                            // DBusMenuItem has triggered() signal/method
                            try {
                                // The triggered() signal needs to be emitted
                                child.triggered()
                                console.log("DBusMenuItem triggered successfully")
                            } catch (e) {
                                console.log("Error triggering DBusMenuItem:", e)
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
                    property var extractedItems: []
                    
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
                            
                            // Try to call menu methods that might be available
                            try {
                                if (menu.getLayout) {
                                    console.log("Trying getLayout...")
                                    const layout = menu.getLayout()
                                    console.log("Layout result:", layout)
                                }
                            } catch (e) {
                                console.log("getLayout not available or failed:", e)
                            }
                            
                            try {
                                if (menu.items) {
                                    console.log("Menu.items:", menu.items)
                                }
                            } catch (e) {
                                console.log("menu.items not available:", e)
                            }
                        }
                        
                        console.log("Children model:", children)
                        if (children) {
                            console.log("Children count:", children.count || 0)
                            
                            // Try direct iteration if children is a list
                            try {
                                for (let i = 0; i < children.length; i++) {
                                    console.log(`Direct child ${i}:`, children[i])
                                }
                            } catch (e) {
                                console.log("Direct iteration failed:", e)
                            }
                        }
                    }
                    
                    onChildrenChanged: {
                        console.log("MenuOpener children changed for:", modelData.id)
                        console.log("New children:", children)
                        // Clear old items when menu changes
                        extractedItems = []
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
                
                // Use a Repeater to collect DBus menu items
                Repeater {
                    id: menuRepeater
                    model: menuOpener.children
                    delegate: Item {
                        Component.onCompleted: {
                            if (modelData) {
                                console.log("DBus menu item found:", modelData.text)
                                
                                // Create a menu item object from the DBusMenuItem
                                // Treat empty text items as separators too
                                const isEmptyText = !modelData.text || modelData.text.trim() === ""
                                const isSeparator = modelData.isSeparator || isEmptyText
                                
                                // Skip consecutive separators
                                if (isSeparator && menuOpener.extractedItems && menuOpener.extractedItems.length > 0) {
                                    const lastItem = menuOpener.extractedItems[menuOpener.extractedItems.length - 1]
                                    if (lastItem.type === "separator") {
                                        console.log("Skipping consecutive separator")
                                        return  // Skip this separator since the previous item was also a separator
                                    }
                                }
                                
                                const menuItem = {
                                    type: isSeparator ? "separator" : "action",
                                    text: modelData.text || "",
                                    icon: modelData.icon || "", // Keep the icon path from DBus
                                    enabled: modelData.enabled !== false,
                                    hasSubmenu: modelData.hasChildren || false,
                                    dbusItem: modelData,  // Keep reference to the original item
                                    action: function() {
                                        console.log("Menu item clicked:", modelData.text)
                                        try {
                                            modelData.triggered()
                                            console.log("DBusMenuItem triggered successfully")
                                        } catch (e) {
                                            console.log("Error triggering DBusMenuItem:", e)
                                        }
                                    }
                                }
                                
                                // Add to the extracted items array
                                if (!menuOpener.extractedItems) {
                                    menuOpener.extractedItems = []
                                }
                                menuOpener.extractedItems.push(menuItem)
                                console.log("Added item to extractedItems, total:", menuOpener.extractedItems.length)
                            }
                        }
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