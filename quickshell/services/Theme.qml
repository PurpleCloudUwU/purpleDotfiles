pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The active colour world. Reads ~/.local/state/station/theme and the
// matching palette from ~/.config/station/palettes/. Both files are
// watched, so `station theme <name>` recolours the shell right away.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/station"
    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"
    readonly property string dataDir: Quickshell.env("XDG_DATA_HOME") || home + "/.local/share"

    property string name: "violet"
    property var p: ({})

    // user@host for test pictures and labels
    readonly property string user: Quickshell.env("USER") || "user"
    property string host: "station"

    FileView {
        path: "/etc/hostname"
        printErrors: false
        onLoaded: root.host = text().trim() || "station"
    }

    // Violet until the palette file is read
    readonly property color bg: p.bg ?? "#0c0d14"
    readonly property color grid: p.grid ?? "#181a28"
    readonly property color surface: p.surface ?? "#12131d"
    readonly property color surface2: p.surface2 ?? "#1b1d2d"
    readonly property color surface3: p.surface3 ?? "#161826"
    readonly property color off: p.off ?? "#22243a"
    readonly property color line: p.line ?? "#2c2f47"
    readonly property color border: p.border ?? "#6e7194"
    readonly property color fg: p.fg ?? "#d9d6f2"
    readonly property color fg2: p.fg2 ?? "#a9c4ff"
    readonly property color muted: p.muted ?? "#8a8daa"
    readonly property color faint: p.faint ?? "#3a3d5c"
    readonly property color frame: p.frame ?? "#c9bfff"
    readonly property color accent: p.accent ?? "#9b7bff"
    readonly property color accent2: p.accent2 ?? "#5b8cff"
    readonly property color select: p.select ?? "#9b7bff"

    // Size of the top bar. 1.0 is the canvas (48 px high, 26 px text, 16 px
    // from the top edge); everything below the bar follows barBottom.
    // Hyprland's file manager rule (hypr/station/rules.lua) uses the window
    // top: barBottom + 24.
    readonly property real barScale: 0.75
    readonly property int barTop: Math.round(16 * barScale)
    readonly property int barHeight: Math.round(48 * barScale)
    readonly property int barBottom: barTop + barHeight

    // Swatches for the theme buttons (each theme's signature colour)
    readonly property var swatches: ({ amber: "#e9dca0", red: "#ff5b3a", green: "#c2f0c2", violet: "#9b7bff" })

    // Pocket, the game's display font, when it is installed; VT323 otherwise
    readonly property string font: Qt.fontFamilies().indexOf("Pocket") >= 0 ? "Pocket" : "VT323"
    // Small caps labels
    readonly property string labelFont: "Silkscreen"

    // key=value lines into an object (palettes and crt.conf)
    function parseKv(text) {
        const out = {};
        for (const line of text.split("\n")) {
            const m = line.match(/^([a-z0-9_]+)=(.*)$/);
            if (m)
                out[m[1]] = m[2].trim();
        }
        return out;
    }

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function refresh() {
        themeFile.reload();
        paletteFile.reload();
    }

    FileView {
        id: themeFile
        path: root.stateDir + "/theme"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.name = text().trim() || "violet"
    }

    FileView {
        id: paletteFile
        path: root.configDir + "/station/palettes/" + root.name + ".conf"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.p = root.parseKv(text())
    }
}
