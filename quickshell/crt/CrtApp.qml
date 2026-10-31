import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.widgets

// STATION SETUP with two pages:
// - CRT CALIBRATION (canvas board 03): try the effects on the test picture,
//   then APPLY writes them with `station crt write`. The colour world
//   switches right away.
// - DESKTOP WIDGETS (DesktopPage.qml): move, hide and set up the widgets.
// Open with Super+Shift+F12, the program select, `qs ipc call crt open` or
// `qs ipc call setup open desktop`.
FloatingWindow {
    id: win

    title: "STATION SETUP"
    visible: Panels.crt
    implicitWidth: 1320
    implicitHeight: 900
    color: Theme.surface

    onClosed: Panels.crt = false
    onVisibleChanged: {
        if (visible) {
            load();
            body.forceActiveFocus();
        }
    }

    readonly property var labels: ({
        scan: "SCANLINES",
        curve: "CURVATURE",
        glow: "GLOW",
        fringe: "COLOR FRINGE",
        vig: "VIGNETTE",
        noise: "NOISE",
        flick: "FLICKER"
    })
    readonly property var tints: ({ neutral: "#e8e6dc", amber: "#e9dca0", green: "#c2f0c2", red: "#ff8a73" })
    readonly property var options: [
        { key: "battery_subtle", label: "Drop to SUBTLE on battery" },
        { key: "fullscreen_off", label: "Turn off for fullscreen windows" },
        { key: "boot_flicker", label: "Power-on flicker at login" }
    ]

    // What the window edits; nothing changes on screen before APPLY
    property var draft: saved()
    property bool applied: false

    function saved() {
        return Object.assign({}, Station.values, {
            tint: Station.tint,
            battery_subtle: Station.batterySubtle,
            fullscreen_off: Station.fullscreenOff,
            boot_flicker: Station.bootFlicker
        });
    }

    function load() {
        draft = saved();
        applied = false;
    }

    function set(key, value) {
        const d = Object.assign({}, draft);
        d[key] = value;
        draft = d;
        applied = false;
    }

    function pickPreset(name) {
        const d = Object.assign({}, draft);
        Station.keys.forEach((k, i) => d[k] = Station.presets[name][i]);
        draft = d;
        applied = false;
    }

    // Factory settings: SUBTLE, neutral phosphor, the two savings options on
    function reset() {
        pickPreset("subtle");
        draft = Object.assign({}, draft, { tint: "neutral", battery_subtle: true, fullscreen_off: true, boot_flicker: false });
    }

    function apply() {
        const args = ["station", "crt", "write"];
        Station.keys.forEach(k => args.push(k + "=" + draft[k]));
        args.push("tint=" + draft.tint);
        options.forEach(o => args.push(o.key + "=" + (draft[o.key] ? "on" : "off")));
        Quickshell.execDetached(args);
        applied = true;
    }

    // The preset the draft matches, or "custom"
    readonly property string draftPreset: {
        for (const name of ["off", "work", "subtle", "full"]) {
            if (Station.keys.every((k, i) => draft[k] === Station.presets[name][i]))
                return name;
        }
        return "custom";
    }
    readonly property bool unsaved: JSON.stringify(draft) !== JSON.stringify(saved())

    // Rough cost on the UHD 620; curvature and flicker mean full redraws
    readonly property int gpuCells: {
        const d = draft;
        let score = (d.scan * 0.2 + d.curve * 0.3 + d.glow * 0.25 + d.fringe * 0.15 + d.noise * 0.1) / 10;
        if (d.curve > 0 || d.flick > 0)
            score = Math.max(score, 7);
        return Math.max(0, Math.min(10, Math.round(score)));
    }
    readonly property string gpuLabel: draftPreset === "off" ? "OFF" : gpuCells <= 2 ? "VERY LOW" : gpuCells <= 4 ? "LOW" : gpuCells <= 6 ? "MEDIUM" : "HIGH"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // [CRT CALIBRATION] DESKTOP WIDGETS  ////////  Qt 6 · QML  [X]
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            color: Theme.frame

            Row {
                id: titleRow
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Rectangle {
                    width: 6
                    height: 22
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.bg
                }

                Repeater {
                    model: [
                        { key: "crt", label: "CRT CALIBRATION" },
                        { key: "desktop", label: "DESKTOP WIDGETS" }
                    ]

                    Rectangle {
                        id: tab

                        required property var modelData
                        readonly property bool current: (Panels.setupPage === "desktop" ? "desktop" : "crt") === modelData.key

                        width: tabLabel.implicitWidth + 24
                        height: 42
                        anchors.verticalCenter: parent.verticalCenter
                        color: current ? Theme.bg : "transparent"
                        Accessible.role: Accessible.PageTab
                        Accessible.name: modelData.label

                        PText {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: tab.modelData.label
                            color: tab.current ? Theme.frame : Theme.bg
                            font.pixelSize: 28
                            font.underline: !tab.current && tabMouse.containsMouse
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Panels.setupPage = tab.modelData.key
                        }
                    }
                }
            }

            Hatch {
                anchors.left: titleRow.right
                anchors.right: qtLabel.left
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                height: 22
                color: Theme.bg
                opacity: 0.45
            }

            PText {
                id: qtLabel
                anchors.right: closeButton.left
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "Qt 6 · QML"
                color: Theme.bg
                font.pixelSize: 24
            }

            Rectangle {
                id: closeButton
                anchors.right: parent.right
                width: 42
                height: 42
                color: closeMouse.containsMouse ? Theme.accent : Theme.bg
                Accessible.role: Accessible.Button
                Accessible.name: "Close"

                Icon {
                    anchors.centerIn: parent
                    name: "close"
                    size: 18
                    stroke: 3
                    color: closeMouse.containsMouse ? Theme.bg : Theme.frame
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Panels.crt = false
                }
            }
        }

        // One page per topic, picked with the tabs in the header
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: Panels.setupPage === "desktop" ? 1 : 0

            // CRT CALIBRATION
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                RowLayout {
                    id: body

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 32
                    Layout.rightMargin: 32
                    Layout.topMargin: 26
                    Layout.bottomMargin: 26
                    spacing: 40
                    focus: true
                    Keys.onEscapePressed: Panels.crt = false

                    // Preview, preset, GPU load, colour world
                    ColumnLayout {
                        Layout.preferredWidth: 520
                        Layout.fillWidth: false
                        Layout.alignment: Qt.AlignTop
                        spacing: 12

                        Section {
                            text: "PREVIEW"
                        }

                        CrtScreen {
                            Layout.preferredWidth: 520
                            Layout.preferredHeight: 360
                            values: win.draft
                            phosphor: win.tints[win.draft.tint] ?? Theme.fg
                        }

                        Section {
                            Layout.topMargin: 6
                            text: "PRESET"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: ["off", "work", "subtle", "full"]

                                Btn {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 52
                                    text: Station.presetNames[modelData]
                                    fontSize: 24
                                    active: win.draftPreset === modelData
                                    outline: Theme.line
                                    onClicked: win.pickPreset(modelData)
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 6

                            Caps {
                                text: "ESTIMATED GPU LOAD"
                                font.letterSpacing: 2
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            PText {
                                text: win.gpuLabel
                                color: win.gpuCells >= 6 ? Theme.accent : Theme.frame
                                font.pixelSize: 24
                            }
                        }

                        Segments {
                            Layout.fillWidth: true
                            implicitHeight: 20
                            count: 10
                            gap: 4
                            value: win.gpuCells
                            on: win.gpuCells >= 6 ? Theme.accent : Theme.frame
                        }

                        PText {
                            text: "Intel UHD Graphics 620 · estimate"
                            color: Theme.muted
                            font.pixelSize: 22
                        }

                        Section {
                            Layout.topMargin: 6
                            text: "COLOR WORLD"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: ["amber", "red", "green", "violet"]

                                Choice {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    text: modelData.toUpperCase()
                                    swatch: Theme.swatches[modelData]
                                    active: Theme.name === modelData
                                    onClicked: Station.setTheme(modelData)
                                }
                            }
                        }

                        // Lets the column (and the page) grow to the window height
                        Item {
                            Layout.fillHeight: true
                        }
                    }

                    // Parameters, phosphor colour, behaviour
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 10

                        Section {
                            text: "PARAMETERS"
                        }

                        Repeater {
                            model: Station.keys

                            RowLayout {
                                id: param

                                required property string modelData

                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                spacing: 16

                                PText {
                                    Layout.preferredWidth: 180
                                    text: win.labels[param.modelData]
                                }

                                Segments {
                                    Layout.fillWidth: true
                                    implicitHeight: 26
                                    count: 20
                                    gap: 4
                                    value: (win.draft[param.modelData] ?? 0) / 5
                                    interactive: true
                                    onPicked: cells => win.set(param.modelData, cells * 5)
                                }

                                PText {
                                    Layout.preferredWidth: 76
                                    horizontalAlignment: Text.AlignRight
                                    text: (win.draft[param.modelData] ?? 0) + " %"
                                }
                            }
                        }

                        Section {
                            Layout.topMargin: 8
                            text: "PHOSPHOR COLOR"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: ["neutral", "amber", "green", "red"]

                                Choice {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 50
                                    fontSize: 24
                                    text: modelData.toUpperCase()
                                    swatch: win.tints[modelData]
                                    active: win.draft.tint === modelData
                                    onClicked: win.set("tint", modelData)
                                }
                            }
                        }

                        Section {
                            Layout.topMargin: 8
                            text: "BEHAVIOR"
                        }

                        Repeater {
                            model: win.options

                            Item {
                                id: option

                                required property var modelData
                                readonly property bool on: win.draft[modelData.key] ?? false

                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                Accessible.role: Accessible.CheckBox
                                Accessible.name: modelData.label
                                Accessible.checked: on

                                Rectangle {
                                    id: box
                                    width: 22
                                    height: 22
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "transparent"
                                    border.width: 2
                                    border.color: Theme.frame

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        color: option.on ? Theme.frame : "transparent"
                                    }
                                }

                                PText {
                                    anchors.left: box.right
                                    anchors.leftMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: option.modelData.label
                                    font.pixelSize: 25
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.set(option.modelData.key, !option.on)
                                }
                            }
                        }

                        Row {
                            Layout.topMargin: 4
                            spacing: 10

                            PText {
                                text: "TOGGLE"
                                color: Theme.muted
                                font.pixelSize: 25
                                rightPadding: 6
                            }

                            Repeater {
                                model: ["SUPER", "+", "F12"]

                                Rectangle {
                                    required property string modelData
                                    readonly property bool key: modelData !== "+"

                                    width: keyText.implicitWidth + (key ? 20 : 0)
                                    height: 34
                                    color: "transparent"
                                    border.width: key ? 2 : 0
                                    border.color: Theme.muted

                                    PText {
                                        id: keyText
                                        anchors.centerIn: parent
                                        text: parent.modelData
                                        color: parent.key ? Theme.fg : Theme.muted
                                        font.pixelSize: 25
                                    }
                                }
                            }
                        }
                    }
                }

                // Status, RESET, APPLY
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    color: Theme.line
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74
                    Layout.leftMargin: 32
                    Layout.rightMargin: 32
                    spacing: 10

                    PText {
                        Layout.fillWidth: true
                        font.pixelSize: 23
                        elide: Text.ElideRight
                        text: win.applied && !win.unsaved ? "APPLIED · " + (Station.presetNames[Station.preset] ?? "") + " IS ON SCREEN"
                            : win.unsaved ? "NOT APPLIED · writes ~/.local/state/station/crt/"
                            : "ON SCREEN · " + (Station.presetNames[Station.shown] ?? "") + (Station.temporary ? " (SAVED: " + Station.presetNames[Station.preset] + ")" : "")
                        color: win.unsaved ? Theme.muted : Theme.frame
                    }

                    Btn {
                        implicitHeight: 48
                        text: "RESET"
                        padding: 20
                        outline: Theme.muted
                        onClicked: win.reset()
                    }

                    Btn {
                        implicitHeight: 48
                        text: "APPLY"
                        padding: 26
                        active: true
                        onClicked: win.apply()
                    }
                }
            }

            // DESKTOP WIDGETS
            DesktopPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
