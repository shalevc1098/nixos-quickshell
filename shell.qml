//@ pragma UseQApplication

import "./modules/bar"
import "./modules/notifications"
import "./modules/powermenu"
import "./modules/overview"
import "./services"
import Quickshell
import QtQuick

ShellRoot {
    property bool enableBar: true
    property bool enableNotifications: true
    property bool enableOverview: true
    
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
    }
    
    // PowerMenu - separate from bar
    PowerMenu {
        id: powerMenu
    }
    
    // Overview - workspace and window switcher
    Overview {
        id: overview
    }
    
    LazyLoader {
        id: barLoader
        active: enableBar
        component: Bar {
            onPowerMenuRequested: {
                console.log("Shell received powerMenuRequested signal")
                powerMenu.show()
            }
        }
    }
    
    NotificationManager {}
}