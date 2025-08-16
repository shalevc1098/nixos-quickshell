import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

FocusScope {
    id: root
    
    implicitWidth: 620  // Max width to accommodate expanded search
    implicitHeight: 48  // Just the search bar height
    
    property alias searchText: searchField.text
    property alias searchingText: searchField.text
    property bool showResults: searchingText !== ""
    property string mathResult: ""
    property var searchResults: []
    signal searchSubmitted()
    
    function focusSearch() {
        searchField.forceActiveFocus()
        // Enable animation after initial focus
        expandAnimationTimer.start()
    }
    
    function clearSearch() {
        searchField.clear()
    }
    
    function setSearchingText(text) {
        searchField.text = text
    }
    
    function focusFirstItem() {
        // Placeholder for search results focus
    }
    
    function disableExpandAnimation() {
        searchWidthBehavior.enabled = false
    }
    
    function cancelSearch() {
        searchField.clear()
        searchWidthBehavior.enabled = true
    }
    
    // Timer to enable animation after initial load
    Timer {
        id: expandAnimationTimer
        interval: 100
        repeat: false
        onTriggered: searchWidthBehavior.enabled = true
    }
    
    ColumnLayout {
        id: columnLayout
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        spacing: 10
        
        // Search bar container
        Rectangle {
            id: searchBar
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: searchField.implicitWidth + 40 + 32 // TextField width + margins + icon
            implicitHeight: 48
            
            radius: 24
            color: Appearance.m3colors.surface_container_low
            border.width: 1
            border.color: Appearance.m3colors.outline_variant
            
            RowLayout {
                anchors.fill: parent
                spacing: 5
            
            // Search icon
            Text {
                Layout.leftMargin: 15
                text: "󰍉"
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 20
                color: Appearance.m3colors.on_surface
            }
            
            // Search input
            TextField {
                id: searchField
                focus: true
                Layout.rightMargin: 15
                Layout.fillHeight: true
                implicitWidth: searchingText === "" ? 260 : 450
                padding: 15
                
                Behavior on implicitWidth {
                    id: searchWidthBehavior
                    enabled: false
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutExpo
                    }
                }
            
            placeholderText: "Search"
            font.family: "SF Pro Display"
            font.pixelSize: 14
            color: searchField.activeFocus ? Appearance.m3colors.on_surface : Appearance.m3colors.on_surface_variant
            placeholderTextColor: Appearance.m3colors.outline
            
            background: null
            
            // Custom cursor
            cursorDelegate: Rectangle {
                width: 1
                color: searchField.activeFocus ? Appearance.m3colors.primary : "transparent"
                visible: searchField.cursorVisible
                radius: 0.5
            }
            
            Keys.onReturnPressed: {
                if (appResults.count > 0) {
                    const selectedIndex = appResults.currentIndex >= 0 ? appResults.currentIndex : 0
                    const selectedItem = searchModel.values[selectedIndex]
                    if (selectedItem) {
                        root.launchSearchResult(selectedItem)
                    }
                }
            }
            
            Keys.onEnterPressed: {
                if (appResults.count > 0) {
                    const selectedIndex = appResults.currentIndex >= 0 ? appResults.currentIndex : 0
                    const selectedItem = searchModel.values[selectedIndex]
                    if (selectedItem) {
                        root.launchSearchResult(selectedItem)
                    }
                }
            }
            
            Keys.onEscapePressed: {
                GlobalStates.overviewOpen = false
            }
            
            Keys.onDownPressed: {
                if (appResults.count > 0) {
                    appResults.currentIndex = Math.min(appResults.currentIndex + 1, appResults.count - 1)
                }
            }
            
            Keys.onUpPressed: {
                if (appResults.count > 0) {
                    appResults.currentIndex = Math.max(appResults.currentIndex - 1, 0)
                }
            }
        }  // TextField
        }  // RowLayout
    }  // Rectangle (searchBar)
        
        // Separator
        Rectangle {
            visible: root.showResults
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: searchBar.width
            height: 1
            color: Appearance.m3colors.outline_variant
        }
        
        // Results container with background
        Rectangle {
            id: resultsContainer
            visible: root.showResults
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: searchBar.width
            implicitHeight: Math.min(400, appResults.contentHeight + 20)
            
            radius: 12
            color: Appearance.m3colors.surface_container_low
            border.width: 1
            border.color: Appearance.m3colors.outline_variant
            
            // App results ListView
            ListView {
                id: appResults
                anchors.fill: parent
                anchors.margins: 10
                clip: true
                spacing: 2
                highlightMoveDuration: 100
                
                // Highlight component for selected item
                highlight: Rectangle {
                    radius: 8
                    color: Appearance.m3colors.primary
                    opacity: 0.1
                }
                
                // Disable default add/remove animations
                add: null
                remove: null
                
                // Keep the current index updated
                onCountChanged: {
                    if (count > 0) currentIndex = 0
                }
                
                Connections {
                    target: root
                    function onSearchingTextChanged() {
                        if (appResults.count > 0)
                            appResults.currentIndex = 0;
                    }
                }
                
                // Model with search results
                model: ScriptModel {
                    id: searchModel
                    values: root.searchResults
                }
                
                delegate: SearchItem {
                    required property var modelData
                    width: appResults.width
                    entry: modelData
                    query: root.searchingText
                }
            }
        }
        
        // Results container - temporarily removed
        // Rectangle {
        //     id: resultsContainer
        //     Layout.alignment: Qt.AlignHCenter
        //     visible: root.showResults
        //     
        //     width: 450 + 40 + 32  // Match expanded search bar width (TextField + margins + icon)
        //     height: Math.min(400, appResults.contentHeight + 20)
        //     radius: 12
        //     color: Appearance.m3colors.surface
        //     border.width: 1
        //     border.color: Appearance.m3colors.outline_variant
        //     clip: true
        //     
        //     // Fade in animation
        //     opacity: visible ? 1 : 0
        //     Behavior on opacity {
        //         NumberAnimation {
        //             duration: 200
        //             easing.type: Easing.OutCubic
        //         }
        //     }
        //     
        //     // Scale animation
        //     scale: visible ? 1 : 0.95
        //     Behavior on scale {
        //         NumberAnimation {
        //             duration: 200
        //             easing.type: Easing.OutBack
        //         }
        //     }
        //     
        //     ListView {
        //         id: appResults
        //         anchors.fill: parent
        //         anchors.margins: 10
        //         clip: true
        //         spacing: 2
        //         highlightMoveDuration: 100
        //         
        //         onCountChanged: {
        //             if (count > 0) currentIndex = 0
        //         }
        //         
        //         model: ListModel {
        //             id: searchModel
        //         }
        //         
        //         delegate: SearchItem {
        //             required property var model
        //             width: appResults.width
        //             entry: model
        //             query: root.searchingText
        //         }
        //     }
        // }  // Rectangle (resultsContainer)
    }  // ColumnLayout
    
    // Function to handle launching search results
    function launchSearchResult(item) {
        if (!item) return
        
        if (item.execute && typeof item.execute === 'function') {
            // Item has an execute function (like DesktopEntry)
            item.execute()
            GlobalStates.overviewOpen = false
        } else if (item.commandText) {
            // Run command
            Quickshell.execDetached(["bash", "-c", item.commandText])
            GlobalStates.overviewOpen = false
        } else if (item.mathResultText && item.mathResultText !== "Calculating...") {
            // Copy math result
            Quickshell.clipboardText = item.mathResultText
            GlobalStates.overviewOpen = false
        } else if (item.webSearchQuery) {
            // Open web search
            Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(item.webSearchQuery))
            GlobalStates.overviewOpen = false
        }
    }
    
    // Timer for delayed search operations
    Timer {
        id: searchTimer
        interval: Config.search.nonAppResultDelay
        onTriggered: performSearch()
    }
    
    // Check if a command exists
    Process {
        id: commandChecker
        property string fullCommand: ""
        property string checkedWord: ""
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && commandChecker.fullCommand === root.searchingText) {
                // Command is valid, add it to results
                const commandResultObject = {
                    name: commandChecker.fullCommand,
                    clickActionName: "Run",
                    type: "Run command",
                    iconText: "󰅬",
                    fontType: "monospace",
                    execute: () => {
                        Quickshell.execDetached(["bash", "-c", commandChecker.fullCommand])
                        GlobalStates.overviewOpen = false
                    }
                }
                
                // Add to existing results after apps, before web search
                let newResults = root.searchResults.slice()
                // Insert before web search (which is always last)
                newResults.splice(newResults.length - 1, 0, commandResultObject)
                root.searchResults = newResults
            }
        }
        
        function checkCommand(firstWord) {
            if (!firstWord || firstWord.includes('/') || firstWord.includes('\\')) {
                return
            }
            commandChecker.fullCommand = root.searchingText
            commandChecker.checkedWord = firstWord
            commandChecker.command = ["bash", "-c", `command -v "${firstWord}"`]
            commandChecker.running = false
            commandChecker.running = true
        }
    }
    
    // Math calculation process (disabled for now)
    // Process {
    //     id: mathProcess
    //     property list<string> baseCommand: ["qalc", "-t"]
    //     function calculateExpression(expression) {
    //         mathProcess.running = false
    //         mathProcess.command = baseCommand.concat(expression)
    //         mathProcess.running = true
    //     }
    //     stdout: StdioCollector {
    //         onDataChanged: {
    //             root.mathResult = String(data).trim()
    //         }
    //     }
    // }
    
    // Watch for search text changes
    Connections {
        target: searchField
        function onTextChanged() {
            searchTimer.restart()
        }
    }
    
    function performSearch() {
        if (searchingText === "") {
            root.searchResults = []
            return
        }
        
        // Check for clipboard search prefix
        if (root.searchingText.startsWith(Config.search.prefix.clipboard)) {
            // Clipboard search
            const searchString = root.searchingText.slice(Config.search.prefix.clipboard.length)
            root.searchResults = Cliphist.search(searchString).map(entry => {
                return {
                    cliphistRawString: entry,
                    name: entry.replace(/^\s*\S+\s+/, ""),
                    clickActionName: "",
                    type: `#${entry.match(/^\s*(\S+)/)?.[1] || ""}`,
                    execute: () => {
                        Cliphist.copy(entry)
                    },
                    actions: [
                        {
                            name: "Delete",
                            icon: "delete",
                            execute: () => {
                                Cliphist.deleteEntry(entry)
                            }
                        }
                    ]
                }
            }).filter(Boolean)
            return
        }
        
        let results = []
        
        // Search for real applications
        const appResults = AppSearch.search(searchingText)
        results = results.concat(appResults.map(entry => {
            entry.clickActionName = "Launch";
            entry.type = "App";
            return entry;
        }))
        
        // Check if it's a valid command
        const firstWord = searchingText.split(' ')[0]
        if (firstWord && firstWord.length > 0) {
            // Start checking if command exists
            commandChecker.checkCommand(firstWord)
        }
        
        // Add web search
        results.push({
            name: searchingText,
            clickActionName: "Search",
            type: "Search the web",
            iconText: "󰍉",
            fontType: "main",
            execute: () => {
                let url = Config.search.engineBaseUrl + encodeURIComponent(searchingText)
                for (let site of Config.search.excludedSites) {
                    url += encodeURIComponent(` -site:${site}`)
                }
                Qt.openUrlExternally(url)
                GlobalStates.overviewOpen = false
            }
        })
        
        // Set the search results
        root.searchResults = results
    }
}  // Item (root)