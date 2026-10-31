import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.widgets

// "STATION: PROGRAM SELECT" (canvas board 02). Page 1 holds the station's
// own programs, the following pages every installed app. Typing searches,
// ↑↓ select, PgUp/PgDn (or ←→ with an empty search) turn pages, Enter
// starts, Esc closes.
PanelWindow {
    id: win

    visible: Panels.launcher
    screen: Wm.focusedScreen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.withAlpha(Theme.bg, 0.74)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "station-launcher"

    readonly property int perPage: 8
    readonly property var favorites: [
        { name: "TERMINAL", hint: "foot", icon: "terminal", cmd: ["station", "open", "terminal"] },
        { name: "BROWSER", hint: "web", icon: "globe", cmd: ["station", "open", "browser"] },
        { name: "FILES", hint: "yazi", icon: "folder", cmd: ["station", "open", "files"] },
        { name: "EDITOR", hint: "nvim", icon: "pencil", cmd: ["station", "open", "editor"] },
        { name: "MUSIC", hint: "spotify", icon: "music", cmd: ["station", "open", "music"] },
        { name: "SYSTEM MONITOR", hint: "btop", icon: "bars", cmd: ["station", "open", "monitor"] },
        { name: "CRT CALIBRATION", hint: "qs crt", icon: "tube", cmd: ["station", "open", "crt"] },
        { name: "MUSIC PLAYER", hint: "kew", icon: "music", cmd: ["station", "open", "player"] }
    ]
    readonly property var apps: Array.from(DesktopEntries.applications.values)
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))
        .map(e => ({
            name: e.name.toUpperCase(),
            hint: (e.command[0] ?? "").split("/").pop(),
            keywords: [e.genericName, e.comment].concat(Array.from(e.keywords ?? [])).join(" ").toLowerCase(),
            icon: "app",
            entry: e
        }))

    property string query: ""
    readonly property var items: {
        const all = favorites.concat(apps);
        const q = query.trim().toLowerCase();
        if (!q)
            return all;
        return all.filter(i => i.name.toLowerCase().includes(q) || i.hint.toLowerCase().includes(q) || (i.keywords ?? "").includes(q));
    }
    readonly property int pages: Math.max(1, Math.ceil(items.length / perPage))
    property int page: 0
    property int index: 0
    readonly property var pageItems: items.slice(page * perPage, page * perPage + perPage)

    onQueryChanged: {
        page = 0;
        index = 0;
    }

    onVisibleChanged: {
        if (visible) {
            search.text = "";
            page = 0;
            index = 0;
            search.forceActiveFocus();
        }
    }

    function turn(delta) {
        page = (page + delta + pages) % pages;
        index = Math.min(index, pageItems.length - 1);
    }

    function move(delta) {
        const next = index + delta;
        if (next < 0) {
            turn(-1);
            index = pageItems.length - 1;
        } else if (next >= pageItems.length) {
            turn(1);
            index = 0;
        } else {
            index = next;
        }
    }

    function launch(item) {
        if (!item)
            return;
        if (item.entry) {
            if (item.entry.runInTerminal)
                Quickshell.execDetached(["foot"].concat(Array.from(item.entry.command)));
            else
                item.entry.execute();
        } else {
            Quickshell.execDetached(item.cmd);
        }
        Panels.launcher = false;
    }

    function power(action) {
        Panels.launcher = false;
        Quickshell.execDetached(["station", "power", action]);
    }

    // A click next to the window closes it
    MouseArea {
        anchors.fill: parent
        onClicked: Panels.launcher = false
    }

    Rectangle {
        id: box

        width: 1000
        height: 760
        anchors.centerIn: parent
        color: Theme.surface
        border.width: 3
        border.color: Theme.frame

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 0

            // STATION: PROGRAM SELECT [ESC]
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                spacing: 0

                Rectangle {
                    Layout.fillHeight: true
                    implicitWidth: stationLabel.implicitWidth + 36
                    color: Theme.frame

                    PText {
                        id: stationLabel
                        anchors.centerIn: parent
                        text: "STATION:"
                        color: Theme.bg
                        font.pixelSize: 36
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    PText {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: "PROGRAM SELECT"
                        font.pixelSize: 36

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            color: Theme.accent
                        }
                    }
                }

                Btn {
                    Layout.fillHeight: true
                    text: "ESC"
                    fontSize: 30
                    padding: 22
                    active: true
                    fill: Theme.accent
                    onClicked: Panels.launcher = false
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 2
                color: Theme.line
            }

            // SEARCH ›
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                Layout.margins: 16
                Layout.topMargin: 14
                Layout.bottomMargin: 0
                color: "transparent"
                border.width: 2
                border.color: Theme.frame

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 14

                    PText {
                        text: "SEARCH ›"
                        color: Theme.muted
                        font.pixelSize: 30
                    }

                    TextInput {
                        id: search

                        Layout.fillWidth: true
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 30
                        cursorDelegate: Item {}
                        selectionColor: Theme.frame
                        selectedTextColor: Theme.bg
                        Accessible.role: Accessible.EditableText
                        Accessible.name: "Search programs"
                        onTextChanged: win.query = text

                        // Blinking block cursor
                        Rectangle {
                            x: search.cursorRectangle.x + 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 26
                            color: Theme.fg

                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: win.visible
                                PropertyAction { value: 1 }
                                PauseAnimation { duration: 550 }
                                PropertyAction { value: 0 }
                                PauseAnimation { duration: 550 }
                            }
                        }

                        Keys.onPressed: event => {
                            switch (event.key) {
                            case Qt.Key_Escape:
                                Panels.launcher = false;
                                break;
                            case Qt.Key_Up:
                                win.move(-1);
                                break;
                            case Qt.Key_Down:
                                win.move(1);
                                break;
                            case Qt.Key_PageUp:
                                win.turn(-1);
                                break;
                            case Qt.Key_PageDown:
                            case Qt.Key_Tab:
                                win.turn(1);
                                break;
                            case Qt.Key_Left:
                                if (text !== "")
                                    return;
                                win.turn(-1);
                                break;
                            case Qt.Key_Right:
                                if (text !== "")
                                    return;
                                win.turn(1);
                                break;
                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                                win.launch(win.pageItems[win.index]);
                                break;
                            default:
                                return;
                            }
                            event.accepted = true;
                        }
                    }

                    PText {
                        text: "SUPER + D"
                        color: Theme.muted
                        font.pixelSize: 24
                    }
                }
            }

            // [PREVIOUS PAGE] list | icons [NEXT PAGE]
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 16
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                spacing: 6

                PageTab {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 56
                    previous: true
                    onClicked: win.turn(-1)
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 4

                    Repeater {
                        model: win.perPage

                        Rectangle {
                            id: row

                            required property int index
                            readonly property var item: win.pageItems[index] ?? null
                            readonly property bool selected: item !== null && index === win.index

                            width: parent.width
                            height: 60
                            color: selected ? Theme.select : index % 2 === 0 ? Theme.surface2 : Theme.surface3

                            PText {
                                anchors.left: parent.left
                                anchors.leftMargin: 18
                                anchors.right: hint.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.item ? (row.selected ? "› " : "") + row.item.name : (row.index === 0 ? "NO MATCH" : "")
                                color: row.selected ? Theme.bg : row.item ? Theme.fg : Theme.muted
                                font.pixelSize: 32
                                elide: Text.ElideRight
                            }

                            PText {
                                id: hint
                                anchors.right: parent.right
                                anchors.rightMargin: 18
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.item?.hint ?? ""
                                color: row.selected ? Theme.bg : Theme.muted
                                font.pixelSize: 22
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: row.item !== null
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: win.index = row.index
                                onClicked: win.launch(row.item)
                            }
                        }
                    }
                }

                Column {
                    Layout.preferredWidth: 64
                    Layout.alignment: Qt.AlignTop
                    spacing: 4

                    Repeater {
                        model: win.perPage

                        Rectangle {
                            required property int index
                            readonly property var item: win.pageItems[index] ?? null

                            width: 64
                            height: 60
                            color: !item ? Theme.surface2 : index === win.index ? Theme.accent : Theme.frame

                            Icon {
                                visible: parent.item !== null
                                anchors.centerIn: parent
                                name: parent.item?.icon ?? "app"
                                color: Theme.bg
                            }
                        }
                    }
                }

                PageTab {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 56
                    previous: false
                    onClicked: win.turn(1)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 2
                color: Theme.line
            }

            // PAGE 1/3 · ... and the power buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                spacing: 8

                PText {
                    Layout.fillWidth: true
                    text: "PAGE " + (win.page + 1) + "/" + win.pages + " · ↑↓ SELECT · ENTER LAUNCH"
                    color: Theme.muted
                    font.pixelSize: 24
                    elide: Text.ElideRight
                }

                Btn {
                    implicitHeight: 44
                    text: "LOCK"
                    fontSize: 24
                    outline: Theme.muted
                    onClicked: win.power("lock")
                }

                Btn {
                    implicitHeight: 44
                    text: "LOG OUT"
                    fontSize: 24
                    outline: Theme.muted
                    onClicked: win.power("logout")
                }

                Btn {
                    implicitHeight: 44
                    text: "REBOOT"
                    fontSize: 24
                    outline: Theme.muted
                    onClicked: win.power("reboot")
                }

                Btn {
                    implicitHeight: 44
                    text: "OFF"
                    fontSize: 24
                    padding: 18
                    active: true
                    fill: Theme.accent
                    onClicked: win.power("off")
                }
            }
        }
    }
}
