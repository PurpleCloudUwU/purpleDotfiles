import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.desktop
import qs.services
import qs.widgets

// One screen of the lock: the wallpaper's star chart, a strip in the place
// of the bar, the lock window where the windows would be and, on the laptop
// panel, the desktop widgets in the right column. The orbit and the
// crosshair of the chart stay free, they are hidden behind the widgets on
// the desktop.
WlSessionLockSurface {
    id: surface

    required property var ctl
    readonly property bool primary: screen === Wm.primaryScreen

    color: Theme.bg

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // ISO week (Monday start), as on German calendars
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const start = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - start) / 86400000 + 1) / 7);
    }

    StarChart {
        anchors.fill: parent
    }

    // The layout is for the 1920x1080 canvas, like the desktop; smaller
    // screens get it scaled down, bigger ones centred.
    Item {
        id: canvas

        width: 1920
        height: 1080
        anchors.centerIn: parent
        scale: Math.min(1, surface.width / 1920, surface.height / 1080)

        // --- Strip in the place of the bar ----------------------------------

        Row {
            x: 24
            y: Theme.barTop
            height: Theme.barHeight
            spacing: 12

            Rectangle {
                width: stationLabel.implicitWidth + 50
                height: parent.height
                color: Theme.frame

                Rectangle {
                    x: 14
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.bg

                    Rectangle {
                        width: 4
                        height: 4
                        anchors.centerIn: parent
                        color: Theme.bg
                    }
                }

                PText {
                    id: stationLabel
                    x: 36
                    anchors.verticalCenter: parent.verticalCenter
                    text: "STATION"
                    color: Theme.bg
                    font.pixelSize: 20
                }
            }

            Rectangle {
                width: lockedLabel.implicitWidth + 28
                height: parent.height
                color: "transparent"
                border.width: 2
                border.color: Theme.accent

                PText {
                    id: lockedLabel
                    anchors.centerIn: parent
                    text: "LOCKED"
                    color: Theme.accent
                    font.pixelSize: 20
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 24
            y: Theme.barTop
            width: status.implicitWidth + 32
            height: Theme.barHeight
            color: "transparent"
            border.width: 2
            border.color: Theme.line

            Row {
                id: status
                anchors.centerIn: parent
                spacing: 12

                PText {
                    visible: Net.enabled && Net.ssid !== ""
                    text: "WIFI " + Net.ssid.toUpperCase()
                    color: Theme.muted
                    font.pixelSize: 20
                }

                PText {
                    visible: Sys.hasBattery
                    text: (Sys.charging ? "CHG " : "BAT ") + Sys.batPct + " %"
                    color: Sys.batPct <= 15 && !Sys.charging ? Theme.accent : Theme.fg
                    font.pixelSize: 20
                }

                PText {
                    text: clock.date.toLocaleDateString(Qt.locale("en_US"), "ddd dd.MM.").toUpperCase()
                    color: Theme.muted
                    font.pixelSize: 20
                }
            }
        }

        // --- Lock window ---------------------------------------------------
        // In the middle of the window area (x 24 to 1116) on the laptop
        // panel, in the middle of the screen elsewhere.

        Rectangle {
            id: win

            width: 760
            height: 520
            x: surface.primary ? 24 + (1092 - width) / 2 : (parent.width - width) / 2
            y: surface.primary ? 72 + (984 - height) / 2 : (parent.height - height) / 2
            color: Theme.surface
            border.width: 2
            border.color: Theme.frame

            Header {
                id: header
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 2
                title: "STATION: LOCKED"
                info: Theme.host.toUpperCase()
            }

            // Clock, like the STATION TIME card but bigger
            Row {
                id: time

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: header.bottom
                anchors.topMargin: 18
                spacing: 10

                PText {
                    text: Qt.formatTime(clock.date, "HH:mm")
                    color: Theme.frame
                    font.pixelSize: 168
                }

                PText {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 30
                    text: Qt.formatTime(clock.date, "ss")
                    color: Theme.accent
                    font.pixelSize: 52
                }
            }

            PText {
                id: date
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: time.bottom
                anchors.topMargin: -12
                text: Qt.locale("en_US").toString(clock.date, "dddd · d MMMM yyyy").toUpperCase() + "  ·  WEEK " + surface.isoWeek(clock.date)
                color: Theme.muted
                font.pixelSize: 26
            }

            Rectangle {
                id: rule
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: date.bottom
                anchors.margins: 28
                anchors.topMargin: 22
                height: 2
                color: Theme.line
            }

            Caps {
                id: userLabel
                anchors.left: field.left
                anchors.top: rule.bottom
                anchors.topMargin: 22
                text: "USER: " + Theme.user.toUpperCase()
                color: Theme.muted
            }

            Caps {
                anchors.right: field.right
                anchors.top: userLabel.top
                visible: surface.ctl.fingerReady
                text: "FINGER READY"
                color: Theme.fg2
            }

            // Password
            Rectangle {
                id: field

                width: 560
                height: 58
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: userLabel.bottom
                anchors.topMargin: 10
                color: Theme.bg
                border.width: 2
                border.color: surface.ctl.statusIsError ? Theme.accent : input.activeFocus ? Theme.frame : Theme.line

                // Marker on the left, like the header strips
                Rectangle {
                    x: 14
                    width: 6
                    height: 22
                    anchors.verticalCenter: parent.verticalCenter
                    color: surface.ctl.busy ? Theme.accent : Theme.border
                }

                TextInput {
                    id: input

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 34
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 30
                    font.letterSpacing: 4
                    echoMode: TextInput.Password
                    passwordCharacter: "*"
                    passwordMaskDelay: 0
                    clip: true
                    focus: true
                    // Read only while PAM checks; disabling it would lose the focus
                    readOnly: surface.ctl.busy
                    text: surface.ctl.buffer
                    onTextChanged: {
                        if (text !== surface.ctl.buffer)
                            surface.ctl.buffer = text;
                        if (text !== "" && surface.ctl.statusIsError) {
                            surface.ctl.status = "";
                            surface.ctl.statusIsError = false;
                        }
                    }
                    onAccepted: surface.ctl.submit()
                    Keys.onEscapePressed: surface.ctl.buffer = ""
                    Accessible.role: Accessible.EditableText
                    Accessible.name: "Password"
                    Component.onCompleted: forceActiveFocus()
                }

                PText {
                    anchors.left: input.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text === ""
                    text: surface.ctl.busy ? "" : surface.ctl.fingerReady ? "PASSWORD OR FINGER" : "PASSWORD"
                    color: Theme.faint
                    font.pixelSize: 26
                }

                // Clicks anywhere put the focus back into the field
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: input.forceActiveFocus()
                }
            }

            PText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: field.bottom
                anchors.topMargin: 14
                width: field.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: surface.ctl.status !== "" ? surface.ctl.status : capsLock.on ? "CAPS LOCK IS ON" : ""
                color: surface.ctl.statusIsError || capsLock.on ? Theme.accent : Theme.fg2
                font.pixelSize: 24
            }

            // Footer: battery cells and the time left, like the PDA panel
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 2
                height: 40
                color: Theme.surface2

                Caps {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "MONDBASIS · SECTOR 7"
                    color: Theme.muted
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    visible: Sys.hasBattery

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Repeater {
                            model: 10

                            Rectangle {
                                required property int index
                                width: 8
                                height: 16
                                color: index < Math.ceil(Sys.batPct / 10) ? (Sys.batPct <= 15 ? Theme.accent : Theme.frame) : Theme.off
                            }
                        }
                    }

                    PText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Sys.batPct + " %" + (Sys.timeLeft !== "" ? "  ·  " + Sys.timeLeft : "")
                        color: Theme.fg
                        font.pixelSize: 22
                    }
                }
            }
        }

        // --- Widgets in the right column (laptop panel only) --------------
        // Two rows, so the crosshair and the orbit below stay visible.

        WeatherCard {
            visible: surface.primary
            x: 1140
            y: 72
            width: Desktop.sizes.weather.width
            height: Desktop.sizes.weather.height
        }

        SystemCard {
            visible: surface.primary
            x: 1524
            y: 72
            width: Desktop.sizes.system.width
            height: 216
        }

        MusicCard {
            visible: surface.primary
            x: 1140
            y: 312
            width: 448
            height: 284
        }

        // Read only here: no ticking off tasks or opening the editor while locked
        TasksCard {
            visible: surface.primary
            enabled: false
            x: 1612
            y: 312
            width: 284
        }
    }

    // Caps Lock from the keyboard LEDs, checked while the lock is up
    QtObject {
        id: capsLock
        property bool on: false
    }

    Process {
        id: capsCheck
        command: ["sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null | grep -qv '^0$'"]
        onExited: code => capsLock.on = code === 0
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!capsCheck.running)
                capsCheck.running = true;
        }
    }
}
