import qs.common
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root
    
    implicitWidth: mainRow.implicitWidth
    implicitHeight: mainRow.implicitHeight
    
    // Always visible to show "No media" state
    visible: true
    
    // Signal to open popup
    signal openPopup()
    
    // Timer to update position when playing - like end-4 does
    Timer {
        running: MprisService.activePlayer && MprisService.activePlayer.playbackState === MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: {
            if (MprisService.activePlayer) {
                MprisService.activePlayer.positionChanged()
            }
        }
    }
    
    // Mouse interaction for entire widget
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.LeftButton) {
                root.openPopup()
            } else if (event.button === Qt.MiddleButton) {
                MprisService.togglePlaying()
            } else if (event.button === Qt.BackButton) {
                MprisService.previous()
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                MprisService.next()
            }
        }
    }
    
    Row {
        id: mainRow
        spacing: 6
        anchors.centerIn: parent
        
        // Filled circular progress with play/pause icon
        Item {
            width: 24
            height: 24
            anchors.verticalCenter: parent.verticalCenter
            
            // Circular progress indicator - colorful version - directly like end-4
            CircularProgress {
                id: circularProgress
                anchors.fill: parent
                visible: MprisService.hasActivePlayer && MprisService.length > 0
                value: MprisService.progress  // Use the safe progress property from MprisService
                lineWidth: 2
                implicitSize: 24
                colPrimary: Appearance.m3colors.primary
                colSecondary: Appearance.m3colors.surface_container_high
                enableAnimation: false  // Disable animation for smooth progress
                fill: false  // No filled background, just the line
            }
            
            // Circle background when no media or no valid progress
            Rectangle {
                anchors.fill: parent
                visible: !MprisService.hasActivePlayer || MprisService.length <= 0
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Appearance.m3colors.surface_container_high
            }
            
            // Play/Pause icon in center
            Item {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (!MprisService.hasActivePlayer) return "󰝚"  // Music note when no media
                        return MprisService.isPlaying ? "󰏤" : "󰐊"  // Pause/Play icons
                    }
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 12
                    color: {
                        if (!MprisService.hasActivePlayer) return Appearance.m3colors.on_surface_variant
                        return Appearance.m3colors.on_surface
                    }
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    
                    // Fine-tune centering with small offset if needed
                    anchors.horizontalCenterOffset: {
                        if (!MprisService.hasActivePlayer) return 0
                        return MprisService.isPlaying ? 0 : 1
                    }
                }
            }
        }
        
        // Track info text - single line like end-4
        Text {
            id: trackText
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (!MprisService.hasActivePlayer) return "No media"
                let title = MprisService.trackTitle || "Unknown"
                let artist = MprisService.trackArtist || ""
                
                // Clean title (remove remaster/feat info if too long)
                if (title.includes(" (") && title.length > 25) {
                    title = title.substring(0, title.indexOf(" ("))
                }
                
                // Combine with bullet separator like end-4
                let combined = artist ? `${title} • ${artist}` : title
                
                // Truncate if too long
                if (combined.length > 35) combined = combined.substring(0, 35) + "..."
                return combined
            }
            font.family: "SF Pro Display"
            font.pixelSize: 12
            color: Appearance.m3colors.on_surface
            elide: Text.ElideRight
            
            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: trackText; property: "opacity"; to: 0; duration: 100 }
                    PropertyAction { target: trackText; property: "text" }
                    NumberAnimation { target: trackText; property: "opacity"; to: 1; duration: 100 }
                }
            }
        }
    }
    
    // Tooltip with full track info and time (only when media is playing)
    StyledTooltip {
        visible: parent.parent && parent.parent.isHovered && MprisService.hasActivePlayer
        text: {
            let info = MprisService.trackTitle || "Unknown"
            if (MprisService.trackArtist) info += `\n${MprisService.trackArtist}`
            if (MprisService.trackAlbum) info += `\nAlbum: ${MprisService.trackAlbum}`
            info += `\n${MprisService.positionText} / ${MprisService.lengthText}`
            return info
        }
        delay: 500
    }
}