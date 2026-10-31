pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower

// CRT screen and theme: reads what `station` saved, runs `station` to change
// it, and switches the CRT down while on battery or in fullscreen (the two
// options from the calibration board). The CRT app will talk to this later.
//
//   qs ipc call crt preset subtle        qs ipc call theme set amber
//   qs ipc call crt toggle               qs ipc call theme next
Singleton {
    id: root

    property var crt: ({})

    readonly property string preset: crt.preset ?? "subtle"
    readonly property string tint: crt.tint ?? "neutral"
    readonly property bool batterySubtle: (crt.battery_subtle ?? "on") === "on"
    readonly property bool fullscreenOff: (crt.fullscreen_off ?? "on") === "on"
    readonly property bool heavy: preset === "full" || (preset === "custom" && (Number(crt.curve) > 0 || Number(crt.flick) > 0))
    readonly property bool fullscreen: Hyprland.focusedWorkspace?.hasFullscreen ?? false

    // A preset shown instead of the saved one, or "" for the saved one
    readonly property string temporary: {
        if (preset === "off")
            return "";
        if (fullscreenOff && fullscreen)
            return "off";
        if (batterySubtle && UPower.onBattery && heavy)
            return "subtle";
        return "";
    }
    readonly property string shown: temporary || preset
    readonly property var presetNames: ({ off: "OFF", work: "WORK", subtle: "SUBTLE", full: "FULL TUBE", custom: "CUSTOM" })

    function run(args) {
        Quickshell.execDetached(["station"].concat(args));
    }

    function setPreset(name) {
        run(["crt", name]);
    }

    function setTheme(name) {
        run(["theme", name]);
    }

    function applyTemporary() {
        run(temporary ? ["crt", "apply", temporary] : ["crt", "apply"]);
    }

    onTemporaryChanged: applyTemporary()

    FileView {
        id: crtFile
        path: Theme.stateDir + "/crt.conf"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.crt = Theme.parseKv(text())
    }

    // Hyprland forgets runtime changes when it reloads, so a running
    // preset has to be sent again
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "configreloaded" && root.temporary)
                root.applyTemporary();
        }
    }

    IpcHandler {
        target: "station"

        function refresh(): void {
            Theme.refresh();
            crtFile.reload();
        }

        // `station reload`: QML files replaced by "git pull" are not always
        // noticed by the file watcher
        function reload(): void {
            Quickshell.reload(true);
        }
    }

    IpcHandler {
        target: "crt"

        function preset(name: string): void {
            root.setPreset(name);
        }

        function toggle(): void {
            root.run(["crt", "toggle"]);
        }

        function tint(name: string): void {
            root.run(["crt", "tint", name]);
        }

        function set(key: string, value: int): void {
            root.run(["crt", "set", key, String(value)]);
        }

        function status(): string {
            return "preset=" + root.preset + " shown=" + root.shown + " tint=" + root.tint;
        }
    }

    IpcHandler {
        target: "theme"

        function set(name: string): void {
            root.setTheme(name);
        }

        function next(): void {
            root.setTheme("next");
        }

        function get(): string {
            return Theme.name;
        }
    }
}
