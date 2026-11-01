pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Layout of the desktop widgets (CLOCK, CALENDAR, WEATHER, SYSTEM, MUSIC,
// TASKS, PDA panel), set on the DESKTOP WIDGETS page of STATION SETUP and
// kept in ~/.local/state/station/desktop.json. Positions are pixels on the screen.
Singleton {
    id: root

    // Every widget, in the order the setup page lists them
    readonly property var order: ["clock", "calendar", "weather", "system", "music", "tasks", "pda"]
    readonly property var names: ({
        clock: "CLOCK",
        calendar: "CALENDAR",
        weather: "WEATHER",
        system: "SYSTEM",
        music: "MUSIC",
        tasks: "TASKS",
        pda: "PDA PANEL"
    })
    // Sizes on screen (the task card grows with its list, 230 is typical)
    readonly property var sizes: ({
        clock: Qt.size(360, 144),
        calendar: Qt.size(360, 276),
        weather: Qt.size(372, 216),
        system: Qt.size(372, 204),
        music: Qt.size(448, 284),
        tasks: Qt.size(284, 230),
        pda: Qt.size(756, 208)
    })
    // The canvas layout: the right column next to the windows. Clock and
    // calendar on the left, weather and system on the right above MUSIC
    // and TASKS, 24 px apart.
    readonly property var defaults: ({
        column: true,
        clock: { visible: true, x: 1140, y: 72, seconds: false, h24: true, week: true },
        calendar: { visible: true, x: 1140, y: 240, monday: true, weekNumbers: true },
        weather: { visible: true, x: 1524, y: 72, city: "Berlin", lat: 52.52437, lon: 13.41053, place: "BERLIN", fahrenheit: false },
        system: { visible: true, x: 1524, y: 312, graph: true },
        music: { visible: true, x: 1140, y: 540, visualizer: true },
        tasks: { visible: true, x: 1612, y: 540, showDone: true },
        pda: { visible: true, x: 1140, y: 848 }
    })

    property var layout: defaults

    readonly property var clock: widget("clock")
    readonly property var calendar: widget("calendar")
    readonly property var weather: widget("weather")
    readonly property var system: widget("system")
    readonly property var music: widget("music")
    readonly property var tasks: widget("tasks")
    readonly property var pda: widget("pda")
    // Hyprland keeps the right column free on every workspace (hypr/station/look.lua)
    readonly property bool column: layout.column ?? true

    function widget(key) {
        return Object.assign({}, defaults[key], layout[key] ?? {});
    }

    function update(key, patch) {
        const next = Object.assign({}, layout);
        next[key] = Object.assign(widget(key), patch);
        layout = next;
        saveTimer.restart();
    }

    function setColumn(on) {
        layout = Object.assign({}, layout, { column: on });
        saveTimer.restart();
        Quickshell.execDetached(["station", "desktop", "column", on ? "on" : "off"]);
    }

    function reset() {
        const columnChanged = !column;
        layout = JSON.parse(JSON.stringify(defaults));
        saveTimer.restart();
        if (columnChanged)
            Quickshell.execDetached(["station", "desktop", "column", "on"]);
    }

    // From scripts:
    //   qs ipc call desktop move music 24 600
    //   qs ipc call desktop display tasks false
    //   qs ipc call desktop reset
    //   qs ipc call desktop option clock seconds true
    IpcHandler {
        target: "desktop"

        function option(name: string, key: string, value: string): void {
            if (!root.defaults[name])
                return;
            const v = value === "true" ? true : value === "false" ? false : isNaN(Number(value)) ? value : Number(value);
            const patch = {};
            patch[key] = v;
            root.update(name, patch);
        }

        function move(name: string, x: int, y: int): void {
            if (root.defaults[name])
                root.update(name, { x: x, y: y });
        }

        function display(name: string, on: bool): void {
            if (root.defaults[name])
                root.update(name, { visible: on });
        }

        function column(on: bool): void {
            root.setColumn(on);
        }

        function reset(): void {
            root.reset();
        }
    }

    FileView {
        id: file
        path: Theme.stateDir + "/desktop.json"
        printErrors: false
        onLoaded: {
            try {
                root.layout = JSON.parse(text());
            } catch (e) {
                root.layout = root.defaults;
            }
        }
    }

    // Dragging changes the layout many times a second; write once it rests
    Timer {
        id: saveTimer
        interval: 400
        onTriggered: file.setText(JSON.stringify(root.layout, null, 2) + "\n")
    }
}
