pragma Singleton
pragma ComponentBehavior: Bound

import qs.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string filePath: "/home/shalev/.local/quickshell/colors.json"

    function reapplyTheme() {
        themeFileView.reload()
        if (themeFileView.exists) {
            applyTheme(themeFileView.content)
        }
    }

    function applyColors(fileContent) {
        try {
            const colors = JSON.parse(fileContent)
            
            // Apply each color from the JSON to the m3colors object
            for (const key in colors) {
                if (Appearance.m3colors.hasOwnProperty(key)) {
                    Appearance.m3colors[key] = colors[key]
                }
            }
            
        } catch (error) {
        }
    }
    
    Timer {
        id: delayedFileRead
        interval: Config.hacks.arbitraryRaceConditionDelay
        repeat: false
        running: false
        onTriggered: {
            root.applyColors(themeFileView.text())
        }
    }
    
    FileView {
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            root.applyColors(fileContent)
        }
    }
}