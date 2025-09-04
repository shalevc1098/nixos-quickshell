pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root
    
    // Overview state
    property bool overviewOpen: false
    
    // Other global states we might need
    property bool mediaControlsOpen: false
    property bool powerMenuOpen: false
    
    // Toggle functions
    function toggleOverview() {
        overviewOpen = !overviewOpen
    }
    
    function closeAll() {
        overviewOpen = false
        mediaControlsOpen = false
        powerMenuOpen = false
    }
}