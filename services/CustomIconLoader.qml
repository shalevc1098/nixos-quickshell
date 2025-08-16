pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function parseCustomIconPath(iconPath) {
        const pathMatch = iconPath.match(/^(.+?)\?path=(.+)$/)
        if (pathMatch && pathMatch.length >= 3) {
            return {
                iconName: pathMatch[1],
                customPath: pathMatch[2],
                isCustomPath: true
            }
        }
        return {
            iconName: iconPath,
            customPath: "",
            isCustomPath: false
        }
    }

    function resolveIconPath(iconName, customPath) {
        if (!customPath) return iconName
        
        // Clean any image:// prefix from icon name
        let cleanIconName = iconName
        if (cleanIconName.startsWith("image://icon/")) {
            cleanIconName = cleanIconName.substring("image://icon/".length)
        }
        
        // Try common icon extensions (PNG first for Nix store icons)
        const extensions = ["png", "svg", "xpm", "ico"]
        const basePath = customPath.replace(/\/$/, "") // Remove trailing slash
        
        for (const ext of extensions) {
            const fullPath = `${basePath}/${cleanIconName}.${ext}`
            if (fileExists(fullPath)) {
                return `file://${fullPath}`
            }
        }
        
        // Try without extension
        const directPath = `${basePath}/${cleanIconName}`
        if (fileExists(directPath)) {
            return `file://${directPath}`
        }
        
        // Fallback to original iconName for system icon lookup
        return cleanIconName
    }

    function fileExists(path) {
        // Remove file:// prefix if present
        const cleanPath = path.replace(/^file:\/\//, "")
        
        // For Nix store paths, assume the file exists if the path looks valid
        // FileView might have permission issues with /nix/store
        if (cleanPath.startsWith("/nix/store/")) {
            // Just return true for now, let QML's Image component handle the actual loading
            return true
        }
        
        const fileView = Qt.createQmlObject(`
            import Quickshell.Io
            FileView {
                path: "${cleanPath}"
            }
        `, root)
        
        const exists = fileView.exists
        fileView.destroy()
        return exists
    }

    function getIconSource(iconPath, fallbackIcon = "application-x-executable") {
        if (!iconPath) return fallbackIcon
        
        // Handle image://icon/ prefix that QML might add
        let cleanPath = iconPath.toString()
        if (cleanPath.startsWith("image://icon/")) {
            cleanPath = cleanPath.substring("image://icon/".length)
        }
        
        const parsed = parseCustomIconPath(cleanPath)
        
        if (parsed.isCustomPath) {
            // Clean the icon name of any image:// prefix as well
            let cleanIconName = parsed.iconName
            if (cleanIconName.startsWith("image://icon/")) {
                cleanIconName = cleanIconName.substring("image://icon/".length)
            }
            
            const resolvedPath = resolveIconPath(cleanIconName, parsed.customPath)
            
            // If we found a file path, return it
            if (resolvedPath.startsWith("file://")) {
                return resolvedPath
            }
            
            // If custom path didn't work, try system icon with clean name
            return `image://icon/${cleanIconName}`
        }
        
        // For non-custom paths, ensure we return a proper icon URL
        if (!parsed.iconName.startsWith("image://") && !parsed.iconName.startsWith("file://") && !parsed.iconName.startsWith("/")) {
            return `image://icon/${parsed.iconName}`
        }
        
        return parsed.iconName || fallbackIcon
    }

    function logIconInfo(iconPath) {
        const parsed = parseCustomIconPath(iconPath)
        console.log("Icon info for:", iconPath)
        console.log("  - Icon name:", parsed.iconName)
        console.log("  - Custom path:", parsed.customPath)
        console.log("  - Is custom path:", parsed.isCustomPath)
        
        if (parsed.isCustomPath) {
            const resolved = resolveIconPath(parsed.iconName, parsed.customPath)
            console.log("  - Resolved to:", resolved)
        }
    }
}