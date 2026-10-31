pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Real music levels for the MUSIC widget from cava (PipeWire). cava only
// runs while something plays, the widget is shown and its visualizer is on.
Singleton {
    id: root

    // 0.0 - 1.0 per bar, empty while cava is not running
    property var levels: []
    property bool available: false
    readonly property bool wanted: available && Desktop.music.visible && Desktop.music.visualizer && Player.playing

    onWantedChanged: if (!wanted) levels = []

    Process {
        command: ["sh", "-c", "command -v cava"]
        running: true
        onExited: code => root.available = code === 0
    }

    Process {
        command: ["cava", "-p", Quickshell.shellPath("scripts/cava.conf")]
        running: root.wanted
        stdout: SplitParser {
            onRead: data => root.levels = data.split(";").filter(s => s !== "").map(v => Math.min(1, Number(v) / 100))
        }
    }
}
