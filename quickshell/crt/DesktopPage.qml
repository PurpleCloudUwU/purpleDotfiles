import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// DESKTOP WIDGETS page of STATION SETUP: drag the widgets on the small
// screen, show or hide them and set them up. Everything applies right away
// and is kept in ~/.local/state/station/desktop.json.
ColumnLayout {
    id: page

    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: 32
        Layout.rightMargin: 32
        Layout.topMargin: 26
        Layout.bottomMargin: 26
        spacing: 40
        focus: true
        Keys.onEscapePressed: Panels.crt = false

        // The small screen
        ColumnLayout {
            Layout.preferredWidth: 768
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Section {
                text: "LAYOUT · DRAG THE WIDGETS"
            }

            MiniScreen {
                Layout.preferredWidth: 768
                Layout.preferredHeight: 768 * screenH / screenW
            }

            PText {
                text: "Snaps to an 8 px grid on the " + (Wm.primaryScreen?.width ?? 1920) + "×" + (Wm.primaryScreen?.height ?? 1080) + " screen"
                color: Theme.muted
                font.pixelSize: 22
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 24
                rowSpacing: 0

                Repeater {
                    model: Desktop.order

                    PText {
                        required property string modelData
                        readonly property var cfg: Desktop.widget(modelData)

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: Desktop.names[modelData] + "  " + cfg.x + "," + cfg.y + (cfg.visible ? "" : "  · HIDDEN")
                        color: cfg.visible ? Theme.fg : Theme.muted
                        font.pixelSize: 22
                        elide: Text.ElideRight
                    }
                }
            }

            // Lets the column (and the page) grow to the window height
            Item {
                Layout.fillHeight: true
            }
        }

        // Settings per widget, scrolls with the wheel
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: flick

                anchors.fill: parent
                anchors.rightMargin: 18
                contentHeight: settings.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                // No kinetic scrolling: the WheelHandler below moves the
                // list in steps, without an animation
                interactive: false

                ColumnLayout {
                    id: settings

                    width: flick.width
                    spacing: 6

                    Section {
                        text: "CLOCK"
                    }

                    Check {
                        text: "Show"
                        checked: Desktop.clock.visible
                        onToggled: Desktop.update("clock", { visible: !checked })
                    }

                    Check {
                        text: "24 hours"
                        checked: Desktop.clock.h24
                        onToggled: Desktop.update("clock", { h24: !checked })
                    }

                    Check {
                        text: "Seconds"
                        checked: Desktop.clock.seconds
                        onToggled: Desktop.update("clock", { seconds: !checked })
                    }

                    Check {
                        text: "Week number"
                        checked: Desktop.clock.week
                        onToggled: Desktop.update("clock", { week: !checked })
                    }

                    Section {
                        Layout.topMargin: 14
                        text: "CALENDAR"
                    }

                    Check {
                        text: "Show"
                        checked: Desktop.calendar.visible
                        onToggled: Desktop.update("calendar", { visible: !checked })
                    }

                    Check {
                        text: "Week starts on Monday"
                        checked: Desktop.calendar.monday
                        onToggled: Desktop.update("calendar", { monday: !checked })
                    }

                    Check {
                        text: "Week numbers"
                        checked: Desktop.calendar.weekNumbers
                        onToggled: Desktop.update("calendar", { weekNumbers: !checked })
                    }

                    Section {
                        Layout.topMargin: 14
                        text: "WEATHER"
                    }

                    Check {
                        text: "Show"
                        checked: Desktop.weather.visible
                        onToggled: Desktop.update("weather", { visible: !checked })
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Field {
                            id: city
                            Layout.fillWidth: true
                            placeholder: "City, e.g. Hamburg"
                            text: Desktop.weather.city ?? ""
                            onAccepted: t => Weather.setCity(t)
                        }

                        Btn {
                            implicitHeight: 44
                            text: Weather.searching ? "…" : "SET"
                            fontSize: 24
                            outline: Theme.muted
                            onClicked: Weather.setCity(city.text)
                        }
                    }

                    PText {
                        Layout.fillWidth: true
                        text: Weather.searchError !== "" ? Weather.searchError
                            : Desktop.weather.place + (Desktop.weather.country ? " · " + Desktop.weather.country : "") + " · " + Number(Desktop.weather.lat).toFixed(2) + " " + Number(Desktop.weather.lon).toFixed(2)
                        color: Weather.searchError !== "" ? Theme.accent : Theme.muted
                        font.pixelSize: 22
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        spacing: 8

                        Choice {
                            Layout.preferredWidth: 90
                            text: "°C"
                            active: !Desktop.weather.fahrenheit
                            onClicked: Desktop.update("weather", { fahrenheit: false })
                        }

                        Choice {
                            Layout.preferredWidth: 90
                            text: "°F"
                            active: Desktop.weather.fahrenheit
                            onClicked: Desktop.update("weather", { fahrenheit: true })
                        }
                    }

                    Section {
                        Layout.topMargin: 14
                        text: "SYSTEM"
                    }

                    Check {
                        text: "Show"
                        checked: Desktop.system.visible
                        onToggled: Desktop.update("system", { visible: !checked })
                    }

                    Check {
                        text: "CPU graph"
                        checked: Desktop.system.graph
                        onToggled: Desktop.update("system", { graph: !checked })
                    }

                    Section {
                        Layout.topMargin: 14
                        text: "MUSIC"
                    }

                    Check {
                        text: "Show"
                        checked: Desktop.music.visible
                        onToggled: Desktop.update("music", { visible: !checked })
                    }

                    Check {
                        text: "Visualizer (cava)"
                        checked: Desktop.music.visualizer
                        onToggled: Desktop.update("music", { visualizer: !checked })
                    }

                    PText {
                        Layout.fillWidth: true
                        text: Cava.available ? "Real levels while music plays" : "cava is not installed, the bars only hop"
                        color: Theme.muted
                        font.pixelSize: 22
                        elide: Text.ElideRight
                    }

                    Section {
                        Layout.topMargin: 14
                        text: "TASKS"
                    }

                    Check {
                        text: "Show"
                        checked: Desktop.tasks.visible
                        onToggled: Desktop.update("tasks", { visible: !checked })
                    }

                    Check {
                        text: "Show done tasks"
                        checked: Desktop.tasks.showDone
                        onToggled: Desktop.update("tasks", { showDone: !checked })
                    }

                    Btn {
                        Layout.topMargin: 4
                        implicitHeight: 44
                        text: "EDIT TASKS"
                        fontSize: 24
                        outline: Theme.muted
                        onClicked: Tasks.edit()
                    }

                    Section {
                        Layout.topMargin: 14
                        text: "PDA PANEL"
                    }

                    Check {
                        text: "Show"
                        checked: Desktop.pda.visible
                        onToggled: Desktop.update("pda", { visible: !checked })
                    }

                    Section {
                        Layout.topMargin: 14
                        text: "WINDOWS"
                    }

                    Check {
                        text: "Keep the right column free"
                        checked: Desktop.column
                        onToggled: Desktop.setColumn(!checked)
                    }
                }
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    const step = event.pixelDelta.y !== 0 ? -event.pixelDelta.y : -event.angleDelta.y / 120 * 88;
                    flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, flick.contentY + step));
                }
            }

            // Pixel scrollbar
            Rectangle {
                visible: flick.contentHeight > flick.height
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 8
                color: Theme.surface2

                Rectangle {
                    width: parent.width
                    height: Math.max(30, parent.height * flick.height / flick.contentHeight)
                    y: (parent.height - height) * (flick.contentY / Math.max(1, flick.contentHeight - flick.height))
                    color: Theme.frame
                }
            }
        }
    }

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
            text: "CHANGES APPLY RIGHT AWAY · ~/.local/state/station/desktop.json"
            color: Theme.frame
            font.pixelSize: 23
            elide: Text.ElideRight
        }

        Btn {
            implicitHeight: 48
            text: "RESET LAYOUT"
            padding: 20
            outline: Theme.muted
            onClicked: Desktop.reset()
        }
    }
}
