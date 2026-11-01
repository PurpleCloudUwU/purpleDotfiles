import QtQuick
import Quickshell
import qs.services
import qs.widgets

// CLOCK: the station time in big display digits, the date and the week
// below. Seconds, 12/24 hours and the week number are set in STATION SETUP.
Rectangle {
    id: root

    readonly property var cfg: Desktop.clock
    readonly property date now: clock.date

    color: Theme.surface
    border.width: 2
    border.color: Theme.border

    SystemClock {
        id: clock
        // Ticks once a minute unless the seconds are shown
        precision: root.cfg.seconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    // ISO week (Monday start), as on German calendars
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const start = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - start) / 86400000 + 1) / 7);
    }

    Header {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 2
        implicitHeight: 28
        fontSize: 22
        strong: false
        title: "STATION TIME"
        info: root.cfg.week ? "WEEK " + root.isoWeek(root.now) : ""
    }

    Row {
        id: time

        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.top: header.bottom
        anchors.topMargin: 2
        spacing: 6

        PText {
            // "hh" is only 12-hour together with AP; the AM/PM goes on the side
            text: root.cfg.h24 ? Qt.formatTime(root.now, "HH:mm") : Qt.formatTime(root.now, "h:mm AP").split(" ")[0]
            font.pixelSize: 82
            color: Theme.frame
        }

        Column {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            spacing: 0

            PText {
                visible: !root.cfg.h24
                text: Qt.formatTime(root.now, "AP")
                font.pixelSize: 26
                color: Theme.fg2
            }

            PText {
                visible: root.cfg.seconds
                text: Qt.formatTime(root.now, "ss")
                font.pixelSize: 34
                color: Theme.accent
            }
        }
    }

    PText {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        text: Qt.locale("en_US").toString(root.now, "dddd · d MMMM yyyy").toUpperCase()
        color: Theme.muted
        font.pixelSize: 22
        elide: Text.ElideRight
    }
}
