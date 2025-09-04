pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root
    
    // Current active player
    property MprisPlayer activePlayer: null
    property bool hasActivePlayer: activePlayer !== null
    
    // Player information
    property string trackTitle: activePlayer?.trackTitle ?? ""
    property string trackArtist: activePlayer?.trackArtist ?? ""
    property string trackAlbum: activePlayer?.trackAlbum ?? ""
    property string trackArtUrl: activePlayer?.trackArtUrl ?? ""
    property int playbackState: activePlayer?.playbackState ?? MprisPlaybackState.Stopped
    // Quickshell's MprisPlayer already converts to seconds internally
    property real position: activePlayer?.position ?? 0
    property real length: activePlayer?.length ?? 0
    property real volume: activePlayer?.volume ?? 1.0
    
    // Computed properties
    property bool isPlaying: playbackState === MprisPlaybackState.Playing
    property bool isPaused: playbackState === MprisPlaybackState.Paused
    property bool isStopped: playbackState === MprisPlaybackState.Stopped
    property real progress: {
        if (!activePlayer || length <= 0 || !isFinite(position) || !isFinite(length)) return 0
        return Math.max(0, Math.min(1, position / length))
    }
    
    // Format time from seconds to MM:SS
    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "0:00"
        const minutes = Math.floor(seconds / 60)
        const secs = Math.floor(seconds % 60)
        return `${minutes}:${secs.toString().padStart(2, '0')}`
    }
    
    property string positionText: formatTime(position)
    property string lengthText: formatTime(length)
    
    // Player controls
    function play() {
        if (activePlayer) activePlayer.play()
    }
    
    function pause() {
        if (activePlayer) activePlayer.pause()
    }
    
    function togglePlaying() {
        if (activePlayer) activePlayer.togglePlaying()
    }
    
    function next() {
        if (activePlayer) activePlayer.next()
    }
    
    function previous() {
        if (activePlayer) activePlayer.previous()
    }
    
    function seek(offset) {
        // Quickshell handles the conversion internally
        if (activePlayer) activePlayer.seek(offset)
    }
    
    function setPosition(newPosition) {
        // Quickshell handles the conversion internally
        if (activePlayer) activePlayer.position = newPosition
    }
    
    function setVolume(newVolume) {
        if (activePlayer) activePlayer.volume = Math.max(0, Math.min(1, newVolume))
    }
    
    // Monitor for player changes periodically
    Timer {
        interval: 2000  // Check every 2 seconds
        running: true
        repeat: true
        onTriggered: updateActivePlayer()
    }
    
    Component.onCompleted: {
        updateActivePlayer()
        initialRefreshTimer.start()
    }
    
    // Timer to refresh position after initial load (workaround for Firefox MPRIS bug)
    Timer {
        id: initialRefreshTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (activePlayer) {
                // Force refresh of position/length
                activePlayer.positionChanged()
            }
        }
    }
    
    function updateActivePlayer() {
        // Find the first playing player, or the first player if none are playing
        let playing = null
        let firstPlayer = null
        
        for (let i = 0; i < Mpris.players.values.length; i++) {
            const player = Mpris.players.values[i]
            if (!firstPlayer) firstPlayer = player
            
            if (player.playbackState === MprisPlaybackState.Playing) {
                playing = player
                break
            }
        }
        
        let previousPlayer = activePlayer
        activePlayer = playing || firstPlayer
        
        if (activePlayer) {
            // If we got a new player, refresh its data after a short delay
            if (previousPlayer !== activePlayer) {
                initialRefreshTimer.restart()
            }
        }
    }
    
}