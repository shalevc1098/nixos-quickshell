pragma Singleton
pragma ComponentBehavior: Bound

import qs.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values)
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var preppedNames: list.map(a => ({
        name: Fuzzy.prepare(`${a.name} `),
        entry: a
    }))

    readonly property var preppedIcons: list.map(a => ({
        name: Fuzzy.prepare(`${a.icon} `),
        entry: a
    }))
    
    Component.onCompleted: {
        console.log("AppSearch loaded", list.length, "applications")
    }
    
    function search(query) {
        if (!query || query.length === 0) return []
        
        // Use fuzzy search - exactly like End4
        return Fuzzy.go(query, preppedNames, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }
    
    // Function to launch an app by its ID
    function launchApp(appId, appExec) {
        console.log("Launching app with id:", appId, "exec:", appExec)
        
        // Try to find the app by ID and launch it
        for (const app of applications) {
            if (app.id === appId) {
                console.log("Found app, launching:", app.name)
                app.launch()
                GlobalStates.overviewOpen = false
                return
            }
        }
        
        // Fallback: launch using exec command
        if (appExec) {
            console.log("Fallback: launching with exec command:", appExec)
            const cleanExec = appExec.replace(/%[fFuUdDnNickvm]/g, '').trim()
            Quickshell.execDetached(["sh", "-c", cleanExec])
            GlobalStates.overviewOpen = false
        }
    }
}