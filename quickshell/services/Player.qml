pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The media player for the music widget (Spotify, kew, a browser, ...):
// the one that is playing, otherwise the first one.
Singleton {
    id: root

    readonly property var players: Array.from(Mpris.players.values)
    readonly property var current: players.find(p => p.isPlaying) ?? players[0] ?? null

    readonly property bool playing: current?.isPlaying ?? false
    readonly property string title: current?.trackTitle || "NO SIGNAL"
    readonly property string artist: current?.trackArtist ?? ""
    readonly property string album: current?.trackAlbum ?? ""
    readonly property string source: (current?.identity ?? "").toLowerCase()
    readonly property real length: current?.length ?? 0
    readonly property real position: current?.position ?? 0

    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
    }

    // MPRIS does not push the position, so ask for it while playing
    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.current?.positionChanged()
    }
}
