import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Scope {
    id: root
    property bool mediaControlsOpen: false
    
    Loader {
        id: mediaControlsLoader
        active: root.mediaControlsOpen
        
        onActiveChanged: {
            if (active) {
            }
        }
        
        sourceComponent: PanelWindow {
            id: mediaControlsWindow
            visible: true
            
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            
            Component.onCompleted: {
                // Force initial position update when popup opens
                if (playerController.player) {
                    playerController.currentPosition = playerController.player.position || 0
                    playerController.currentLength = playerController.player.length || 0
                }
            }
            
            // Make fullscreen to catch clicks outside
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            
            // Fullscreen MouseArea to catch clicks outside
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.mediaControlsOpen = false
                }
            }
            
            // Main player control - positioned at top center
            Item {
                id: playerController
                anchors.top: parent.top
                anchors.topMargin: 60  // Bar height + larger gap to avoid overlap
                anchors.horizontalCenter: parent.horizontalCenter
                width: 440
                height: 160
                property var player: MprisService.activePlayer
                
                // Update player reference when active player changes
                Connections {
                    target: MprisService
                    function onActivePlayerChanged() {
                        playerController.player = MprisService.activePlayer
                        if (playerController.player) {
                            playerController.currentPosition = playerController.player.position
                            playerController.currentLength = playerController.player.length
                        }
                    }
                }
                
                // Update when player position/length changes
                Connections {
                    target: playerController.player
                    function onPositionChanged() {
                        playerController.currentPosition = playerController.player.position
                    }
                    function onLengthChanged() {
                        playerController.currentLength = playerController.player.length
                    }
                }
                
                property string artUrl: playerController.player?.trackArtUrl ?? ""
                property string artFileName: {
                    if (!artUrl || artUrl.length === 0) return ""
                    return Qt.md5(artUrl) + ".jpg"
                }
                property string artFilePath: {
                    if (!artFileName || artFileName.length === 0) return ""
                    return "/tmp/quickshell-albumart-" + artFileName
                }
                property bool artDownloaded: false
                property string currentArtPath: ""  // Store the actual downloaded file path
                property color artDominantColor: Appearance.m3colors.surface_container
                property real currentPosition: 0  // Track position separately
                property real currentLength: 0  // Track length separately
                
                // Initialize position when player is set
                onPlayerChanged: {
                    if (player) {
                        currentPosition = player.position || 0
                        currentLength = player.length || 0
                    }
                }
                property bool backgroundIsDark: artDominantColor.hslLightness < 0.5
                property bool needsHighContrast: artDominantColor.hslLightness < 0.3 || artDominantColor.hslLightness > 0.7
                
                // Color utility functions
                function mix(color1, color2, percentage) {
                    var c1 = Qt.color(color1)
                    var c2 = Qt.color(color2)
                    return Qt.rgba(
                        percentage * c1.r + (1 - percentage) * c2.r,
                        percentage * c1.g + (1 - percentage) * c2.g,
                        percentage * c1.b + (1 - percentage) * c2.b,
                        percentage * c1.a + (1 - percentage) * c2.a
                    )
                }
                
                function transparentize(color, percentage) {
                    var c = Qt.color(color)
                    return Qt.rgba(c.r, c.g, c.b, c.a * (1 - percentage))
                }
                
                function adaptToAccent(color1, color2) {
                    var c1 = Qt.color(color1)
                    var c2 = Qt.color(color2)
                    return Qt.hsla(c2.hslHue, c2.hslSaturation, c1.hslLightness, c1.a)
                }
                
                // Timer for position updates
                Timer {
                    running: playerController.player?.playbackState === MprisPlaybackState.Playing
                    interval: 1000
                    repeat: true
                    onTriggered: {
                        if (playerController.player) {
                            playerController.player.positionChanged()
                            // Force update of our tracked properties
                            playerController.currentPosition = playerController.player.position
                            playerController.currentLength = playerController.player.length
                        }
                    }
                }
                
                // Download album art
                onArtUrlChanged: {
                    if (artUrl.length === 0) {
                        artDominantColor = Appearance.m3colors.surface_container
                        artDownloaded = false
                        currentArtPath = ""
                        return
                    }
                    
                    // Calculate the file path directly
                    var fileName = Qt.md5(artUrl) + ".jpg"
                    var filePath = "/tmp/quickshell-albumart-" + fileName
                    
                    
                    // Reset state before download
                    artDownloaded = false
                    
                    // Update download properties before running
                    artDownloader.downloadPath = filePath
                    artDownloader.downloadUrl = artUrl
                    artDownloader.updateCommand()
                    artDownloader.running = true
                }
                
                Process {
                    id: artDownloader
                    property string downloadPath: ""
                    property string downloadUrl: ""
                    
                    function updateCommand() {
                        if (downloadPath && downloadUrl) {
                            command = ["bash", "-c", `[ -f '${downloadPath}' ] || curl -sSL '${downloadUrl}' -o '${downloadPath}'`]
                        } else {
                            command = ["echo", "No URL"]
                        }
                    }
                    
                    command: ["echo", "Not initialized"]
                    onExited: (exitCode, exitStatus) => {
                        if (exitCode === 0 && downloadPath) {
                            playerController.currentArtPath = downloadPath
                            playerController.artDownloaded = true
                            // Extract dominant color from downloaded image
                            colorQuantizer.source = Qt.resolvedUrl(downloadPath)
                        }
                    }
                }
                
                ColorQuantizer {
                    id: colorQuantizer
                    source: ""
                    depth: 0  // 2^0 = 1 color
                    rescaleSize: 1  // Rescale to 1x1 pixel for faster processing
                    onColorsChanged: {
                        if (colors && colors.length > 0) {
                            playerController.artDominantColor = colors[0]
                        }
                    }
                }
    
                // Blended colors based on album art - with contrast improvements
                property QtObject blendedColors: QtObject {
                    property color background: playerController.mix(Appearance.m3colors.surface_container, playerController.artDominantColor, playerController.backgroundIsDark ? 0.6 : 0.5)
                    property color surface: playerController.mix(Appearance.m3colors.surface_container_low, playerController.artDominantColor, 0.5)
                    property color primary: playerController.mix(playerController.adaptToAccent(Appearance.m3colors.primary, playerController.artDominantColor), playerController.artDominantColor, 0.5)
                    property color primaryHover: playerController.mix(playerController.adaptToAccent(Appearance.m3colors.primary, playerController.artDominantColor), playerController.artDominantColor, 0.5)
                    property color primaryActive: playerController.mix(playerController.adaptToAccent(Appearance.m3colors.primary, playerController.artDominantColor), playerController.artDominantColor, 0.5)
                    property color secondaryContainer: playerController.mix(Appearance.m3colors.secondary_container, playerController.artDominantColor, 0.5)
                    property color secondaryContainerHover: playerController.mix(Appearance.m3colors.surface_container_highest, playerController.artDominantColor, 0.5)
                    property color secondaryContainerActive: playerController.mix(Appearance.m3colors.surface_container_highest, playerController.artDominantColor, 0.5)
                    property color onPrimary: playerController.needsHighContrast ? (playerController.backgroundIsDark ? "#ffffff" : "#000000") : playerController.mix(playerController.adaptToAccent(Appearance.m3colors.on_primary, playerController.artDominantColor), playerController.artDominantColor, 0.5)
                    property color onSurface: playerController.needsHighContrast ? (playerController.backgroundIsDark ? "#ffffff" : "#000000") : playerController.mix(Appearance.m3colors.on_surface, playerController.artDominantColor, 0.3)
                    property color onSurfaceVariant: playerController.needsHighContrast ? (playerController.backgroundIsDark ? "#cccccc" : "#333333") : playerController.mix(Appearance.m3colors.on_surface_variant, playerController.artDominantColor, 0.5)
                    property color onSecondaryContainer: playerController.needsHighContrast ? (playerController.backgroundIsDark ? "#ffffff" : "#000000") : playerController.mix(Appearance.m3colors.on_secondary_container, playerController.artDominantColor, 0.5)
                }
    
                // MouseArea to prevent clicks on content from closing popup
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // Do nothing - just consume the click
                    }
                }
                
                // Shadow/elevation
                Rectangle {
                    anchors.fill: background
                    anchors.margins: -2
                    radius: 16
                    color: "transparent"
                    border.width: 0
                    
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowBlur: 0.5
                        shadowOpacity: 0.3
                        shadowVerticalOffset: 2
                    }
                }
    
                // Main background
                Rectangle {
                    id: background
                    anchors.fill: parent
                    anchors.margins: 8
                    radius: 18  // More rounded like end-4
                    color: playerController.blendedColors.background
                    clip: true
                    
                    // Blurred album art background with masking
                    Item {
                        anchors.fill: parent
                        
                        Rectangle {
                            id: maskRect
                            anchors.fill: parent
                            radius: background.radius
                            visible: false
                        }
            
                        Image {
                            id: blurredArt
                            anchors.fill: parent
                            source: playerController.artDownloaded && playerController.currentArtPath ? Qt.resolvedUrl(playerController.currentArtPath) : ""
                            sourceSize.width: parent.width
                            sourceSize.height: parent.height
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            cache: false
                            asynchronous: true
                        }
                        
                        MultiEffect {
                            id: blurredEffect
                            anchors.fill: parent
                            source: blurredArt
                            blurEnabled: true
                            blur: 1.0
                            blurMax: 100
                            saturation: 0.2
                            visible: false
                        }
                        
                        OpacityMask {
                            anchors.fill: parent
                            source: blurredEffect
                            maskSource: maskRect
                            visible: playerController.artDownloaded
                            opacity: 0.4
                        }
                        
                        // Overlay to ensure readability
                        Rectangle {
                            anchors.fill: parent
                            color: playerController.transparentize(playerController.blendedColors.background, 0.2)
                            radius: background.radius
                        }
                    }
        
                    // Content
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        // Album art
                        Rectangle {
                            id: artContainer
                            Layout.fillHeight: true
                            implicitWidth: height
                            radius: 12  // More rounded
                            color: playerController.transparentize(playerController.blendedColors.surface, 0.5)
                            clip: true
                            
                            Image {
                                anchors.fill: parent
                                anchors.margins: playerController.artDownloaded ? 0 : 16
                                source: playerController.artDownloaded && playerController.currentArtPath ? Qt.resolvedUrl(playerController.currentArtPath) : ""
                                fillMode: Image.PreserveAspectCrop
                                cache: false
                                asynchronous: true
                                
                                layer.enabled: playerController.artDownloaded
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: artContainer.width
                                        height: artContainer.height
                                        radius: artContainer.radius
                                    }
                                }
                            }
                            
                            // Fallback icon when no art
                            Text {
                                anchors.centerIn: parent
                                text: "󰝚"
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 32
                                color: playerController.blendedColors.onSurfaceVariant
                                visible: !playerController.artDownloaded
                            }
                        }
            
            // Info and controls
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 4
                
                // Track info
                Text {
                    Layout.fillWidth: true
                    text: playerController.player?.trackTitle || "No media playing"
                    font.family: "SF Pro Display"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: playerController.blendedColors.onSurfaceVariant
                    elide: Text.ElideRight
                }
                
                Text {
                    Layout.fillWidth: true
                    text: playerController.player?.trackArtist || ""
                    font.family: "SF Pro Display"
                    font.pixelSize: 12
                    color: playerController.blendedColors.onSurfaceVariant
                    elide: Text.ElideRight
                    visible: text !== ""
                }
                
                Item { Layout.fillHeight: true }
                
                // Time and progress
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    
                    // Time display
                    Text {
                        anchors.left: parent.left
                        anchors.bottom: progressRow.top
                        anchors.bottomMargin: 4
                        text: {
                            if (!playerController.player) return "0:00 / 0:00"
                            // Use our tracked properties that update via timer
                            return MprisService.formatTime(playerController.currentPosition) + " / " + MprisService.formatTime(playerController.currentLength)
                        }
                        font.family: "SF Pro Display"
                        font.pixelSize: 10
                        color: playerController.blendedColors.onSurfaceVariant
                    }
                    
                    // Progress bar with controls
                    RowLayout {
                        id: progressRow
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8
                        
                        // Previous button
                        Item {
                            width: 24
                            height: 24
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: prevMouseArea.containsMouse ? 
                                       Qt.rgba(playerController.blendedColors.primary.r, playerController.blendedColors.primary.g, playerController.blendedColors.primary.b, 0.2) : 
                                       "transparent"
                                
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "󰒮"
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 16
                                color: playerController.blendedColors.onSurfaceVariant
                            }
                            
                            MouseArea {
                                id: prevMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (playerController.player) {
                                        playerController.player.previous()
                                    }
                                }
                            }
                        }
                        
                        // Progress bar with wavy fill like end-4
                        ProgressBar {
                            Layout.fillWidth: true
                            implicitHeight: 4
                            from: 0
                            to: 1
                            value: {
                                if (!playerController.player || playerController.currentLength <= 0) return 0
                                // Use tracked properties that update via timer
                                const progress = playerController.currentPosition / playerController.currentLength
                                return Math.max(0, Math.min(1, isFinite(progress) ? progress : 0))
                            }
                            
                            background: Rectangle {
                                implicitHeight: 4
                                radius: 2
                                color: playerController.blendedColors.secondaryContainer
                            }
                            
                            contentItem: Item {
                                implicitHeight: 4
                                
                                Rectangle {
                                    width: parent.width * parent.parent.visualPosition
                                    height: parent.height
                                    radius: 2
                                    color: playerController.blendedColors.primary
                                    
                                    Behavior on width {
                                        NumberAnimation { 
                                            duration: 200
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Next button
                        Item {
                            width: 24
                            height: 24
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: nextMouseArea.containsMouse ? 
                                       Qt.rgba(playerController.blendedColors.primary.r, playerController.blendedColors.primary.g, playerController.blendedColors.primary.b, 0.2) : 
                                       "transparent"
                                
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "󰒭"
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 16
                                color: playerController.blendedColors.onSurfaceVariant
                            }
                            
                            MouseArea {
                                id: nextMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (playerController.player) {
                                        playerController.player.next()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Play/Pause button (floating on the right)
                    Item {
                        anchors.right: parent.right
                        anchors.bottom: progressRow.top
                        anchors.bottomMargin: 6
                        width: 40
                        height: 40
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: playerController.player?.playbackState === MprisPlaybackState.Playing ? 8 : 20
                            color: playerController.player?.playbackState === MprisPlaybackState.Playing ? playerController.blendedColors.secondaryContainer : playerController.blendedColors.secondaryContainer
                            
                            Behavior on radius {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                            
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: playMouseArea.containsMouse ? Qt.rgba(0, 0, 0, 0.1) : "transparent"
                                
                            }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: playerController.player?.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 20
                            color: playerController.player?.playbackState === MprisPlaybackState.Playing ? playerController.blendedColors.onSurfaceVariant : playerController.blendedColors.onSurfaceVariant
                        }
                        
                        MouseArea {
                            id: playMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: playerController.player?.togglePlaying()
                        }
                    }
                }
            }
        }
        
    }
            } // End of playerController Item
        } // End of PanelWindow
    } // End of Loader
} // End of Scope