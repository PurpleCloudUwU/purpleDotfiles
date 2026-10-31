pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Which panel is open, plus the OSD. The GlobalShortcuts are bound in
// hypr/station/binds.lua as "quickshell:<name>".
Singleton {
    id: root

    property bool launcher: false
    property bool quick: false
    property bool power: false
    // STATION SETUP is a normal window, closeAll() leaves it alone
    property bool crt: false
    // Its page: "crt" or "desktop"
    property string setupPage: "crt"

    // A panel closed by clicking outside must not reopen from the same click
    // on its bar button
    property real closedAt: 0

    function closeAll() {
        launcher = false;
        quick = false;
        power = false;
    }

    function dismissed() {
        closedAt = Date.now();
        closeAll();
    }

    function toggle(name) {
        const open = !root[name];
        if (open && Date.now() - closedAt < 300)
            return;
        closeAll();
        root[name] = open;
    }

    // --- OSD (volume and brightness)
    property string osdKind: ""
    property int osdValue: 0
    property bool osdVisible: false

    function osd(kind, value) {
        osdKind = kind;
        osdValue = value;
        osdVisible = true;
        osdTimer.restart();
    }

    Timer {
        id: osdTimer
        interval: 1400
        onTriggered: root.osdVisible = false
    }

    // No volume OSD for the values Pipewire reports at login
    property bool ready: false

    Timer {
        interval: 3000
        running: true
        onTriggered: root.ready = true
    }

    Connections {
        target: Sys

        function onVolumeChanged() {
            if (root.ready)
                root.osd("volume", Sys.volume);
        }

        function onMutedChanged() {
            if (root.ready)
                root.osd("volume", Sys.muted ? 0 : Sys.volume);
        }
    }

    GlobalShortcut {
        name: "launcher"
        description: "Program select"
        onPressed: root.toggle("launcher")
    }

    GlobalShortcut {
        name: "quick"
        description: "PDA quick access"
        onPressed: root.toggle("quick")
    }

    GlobalShortcut {
        name: "power"
        description: "Power menu"
        onPressed: root.toggle("power")
    }

    GlobalShortcut {
        name: "crt"
        description: "CRT calibration"
        onPressed: root.crt = !root.crt
    }

    GlobalShortcut {
        name: "dismiss"
        description: "Dismiss notifications"
        onPressed: Notifs.clear()
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggle("launcher");
        }
    }

    IpcHandler {
        target: "quick"

        function toggle(): void {
            root.toggle("quick");
        }

        function open(): void {
            root.closeAll();
            root.quick = true;
        }
    }

    IpcHandler {
        target: "setup"

        // qs ipc call setup open desktop
        function open(page: string): void {
            root.setupPage = page === "desktop" ? "desktop" : "crt";
            root.crt = true;
        }
    }

    IpcHandler {
        target: "osd"

        function brightness(value: int): void {
            Sys.brightness = value;
            root.osd("brightness", value);
        }
    }
}
