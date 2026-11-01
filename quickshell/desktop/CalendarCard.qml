import QtQuick
import Quickshell
import qs.services
import qs.widgets

// CALENDAR: one month as a grid, today marked. The arrows or the mouse
// wheel change the month, a click on the month name goes back to today.
// Week start and week numbers are set in STATION SETUP.
Rectangle {
    id: root

    readonly property var cfg: Desktop.calendar
    readonly property bool monday: cfg.monday
    readonly property bool weeks: cfg.weekNumbers
    readonly property date today: clock.date
    // Months away from the current one
    property int offset: 0
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)

    color: Theme.surface
    border.width: 2
    border.color: Theme.border

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // The 42 days of the grid, from the week the month starts in
    readonly property var cells: {
        const first = shown;
        const lead = monday ? (first.getDay() + 6) % 7 : first.getDay();
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(new Date(first.getFullYear(), first.getMonth(), 1 - lead + i));
        return out;
    }
    readonly property int rows: cells[35].getMonth() === shown.getMonth() ? 6 : 5

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const start = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - start) / 86400000 + 1) / 7);
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    // Header: ◀ NOVEMBER 2026 ▶
    Rectangle {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 2
        height: 28
        color: Theme.surface2

        Repeater {
            model: [{ icon: "left", step: -1, label: "Previous month" }, { icon: "right", step: 1, label: "Next month" }]

            Item {
                id: arrow

                required property var modelData

                anchors.verticalCenter: parent.verticalCenter
                x: modelData.step < 0 ? 4 : header.width - width - 4
                width: 28
                height: 28
                Accessible.role: Accessible.Button
                Accessible.name: modelData.label

                Icon {
                    anchors.centerIn: parent
                    name: arrow.modelData.icon
                    size: 14
                    color: arrowMouse.containsMouse ? Theme.frame : Theme.muted
                }

                MouseArea {
                    id: arrowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.offset += arrow.modelData.step
                }
            }
        }

        PText {
            anchors.centerIn: parent
            text: Qt.locale("en_US").toString(root.shown, "MMMM yyyy").toUpperCase()
            color: root.offset === 0 ? Theme.fg : Theme.fg2
            font.pixelSize: 22
            font.underline: monthMouse.containsMouse && root.offset !== 0

            MouseArea {
                id: monthMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: root.offset !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.offset = 0
            }
        }
    }

    Item {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 6
        anchors.bottomMargin: 8

        readonly property int columns: root.weeks ? 8 : 7
        readonly property real cellW: width / columns
        readonly property real cellH: (height - 22) / root.rows

        // Wheel: month back and forth
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.offset += event.angleDelta.y > 0 ? -1 : 1
        }

        // Weekday names
        Row {
            id: names
            x: root.weeks ? body.cellW : 0
            height: 22

            Repeater {
                model: root.monday ? ["MO", "TU", "WE", "TH", "FR", "SA", "SU"] : ["SU", "MO", "TU", "WE", "TH", "FR", "SA"]

                Caps {
                    required property string modelData
                    required property int index
                    width: body.cellW
                    height: 22
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    // The weekend in the accent colour
                    color: modelData === "SA" || modelData === "SU" ? Theme.accent : Theme.muted
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            y: 21
            height: 1
            color: Theme.line
        }

        // Week numbers
        Column {
            visible: root.weeks
            y: 22

            Repeater {
                model: root.rows

                PText {
                    required property int index
                    width: body.cellW
                    height: body.cellH
                    horizontalAlignment: Text.AlignHCenter
                    text: root.isoWeek(root.cells[index * 7 + (root.monday ? 0 : 1)])
                    color: Theme.faint
                    font.pixelSize: 19
                }
            }
        }

        Grid {
            x: root.weeks ? body.cellW : 0
            y: 22
            columns: 7

            Repeater {
                model: root.rows * 7

                Item {
                    id: day

                    required property int index
                    readonly property date d: root.cells[index]
                    readonly property bool inMonth: d.getMonth() === root.shown.getMonth()
                    readonly property bool isToday: root.sameDay(d, root.today)

                    width: body.cellW
                    height: body.cellH

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 4, 34)
                        height: parent.height - 2
                        visible: day.isToday
                        color: Theme.frame
                    }

                    PText {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: day.d.getDate()
                        font.pixelSize: 22
                        color: day.isToday ? Theme.bg : !day.inMonth ? Theme.faint : Theme.fg
                    }
                }
            }
        }
    }
}
