import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root
    
    implicitWidth: 620  // Max width to accommodate expanded search
    implicitHeight: 48  // Just the search bar height
    
    property alias searchText: searchField.text
    property alias searchingText: searchField.text
    property bool showResults: searchingText !== ""
    property string mathResult: ""
    signal searchSubmitted()
    
    function focusSearch() {
        searchField.focus = true
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
            
            placeholderText: "Search, calculate or run"
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
                root.searchSubmitted()
            }
            
            Keys.onEnterPressed: {
                root.searchSubmitted()
            }
            
            Keys.onEscapePressed: {
                GlobalStates.overviewOpen = false
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
                
                // Model with dummy search results
                model: ListModel {
                    id: searchModel
                }
                
                delegate: SearchItem {
                    required property var model
                    width: appResults.width
                    entry: model
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
    
    // Timer for delayed search operations
    Timer {
        id: searchTimer
        interval: 300
        onTriggered: performSearch()
    }
    
    // Math calculation process
    Process {
        id: mathProcess
        property list<string> baseCommand: ["qalc", "-t"]
        function calculateExpression(expression) {
            mathProcess.running = false
            mathProcess.command = baseCommand.concat(expression)
            mathProcess.running = true
        }
        stdout: StdioCollector {
            onDataChanged: {
                root.mathResult = String(data).trim()
            }
        }
    }
    
    // Watch for search text changes
    Connections {
        target: searchField
        function onTextChanged() {
            searchTimer.restart()
        }
    }
    
    function performSearch() {
        searchModel.clear()
        
        if (searchingText === "") return
        
        // Dummy app results
        searchModel.append({
            name: "Firefox",
            clickActionName: "Launch",
            type: "App",
            icon: "firefox",
            iconText: "",
            fontType: "main",
            execute: function() {
                Quickshell.execDetached(["firefox"])
                GlobalStates.overviewOpen = false
            }
        })
        
        searchModel.append({
            name: "Visual Studio Code",
            clickActionName: "Launch",
            type: "App",
            icon: "code",
            iconText: "",
            fontType: "main",
            execute: function() {
                Quickshell.execDetached(["code"])
                GlobalStates.overviewOpen = false
            }
        })
        
        searchModel.append({
            name: "Terminal",
            clickActionName: "Launch",
            type: "App",
            icon: "utilities-terminal",
            iconText: "",
            fontType: "main",
            execute: function() {
                Quickshell.execDetached(["kitty"])
                GlobalStates.overviewOpen = false
            }
        })
        
        // Add command result
        searchModel.append({
            name: searchingText,
            clickActionName: "Run",
            type: "Run command",
            iconText: "",
            fontType: "monospace",
            execute: function() {
                Quickshell.execDetached(["bash", "-c", searchingText])
                GlobalStates.overviewOpen = false
            }
        })
        
        // Start math calculation
        const startsWithNumber = /^\d/.test(searchingText)
        if (startsWithNumber) {
            mathProcess.calculateExpression(searchingText)
            // Add math result
            searchModel.append({
                name: mathResult || "Calculating...",
                clickActionName: "Copy",
                type: "Math result",
                iconText: "󰃬",
                fontType: "monospace",
                execute: function() {
                    if (mathResult) {
                        Quickshell.clipboardText = mathResult
                        GlobalStates.overviewOpen = false
                    }
                }
            })
        }
        
        // Add web search
        searchModel.append({
            name: searchingText,
            clickActionName: "Search",
            type: "Search the web",
            iconText: "󰍉",
            fontType: "main",
            execute: function() {
                Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(searchingText))
                GlobalStates.overviewOpen = false
            }
        })
        
        // Add some action examples
        searchModel.append({
            name: "Dark Mode",
            clickActionName: "Run",
            type: "Action",
            iconText: "󰌑",
            fontType: "main",
            execute: function() {
                // Placeholder for dark mode toggle
                GlobalStates.overviewOpen = false
            }
        })
        
        searchModel.append({
            name: "Settings",
            clickActionName: "Open",
            type: "System",
            icon: "preferences-system",
            iconText: "",
            fontType: "main",
            execute: function() {
                Quickshell.execDetached(["systemsettings5"])
                GlobalStates.overviewOpen = false
            }
        })
    }
}  // Item (root)