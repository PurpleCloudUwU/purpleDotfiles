import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.widgets

// The PDA panel bottom right (canvas board 01): battery bar, the dots
// floppy, and SYSTEM INFO with the red marked lines.
Rectangle {
    id: root

    color: Theme.surface
    border.width: 2
    border.color: Theme.frame

    readonly property int cells: 8
    readonly property real filled: Sys.batPct / 100 * cells

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        spacing: 20

        // Battery
        ColumnLayout {
            Layout.preferredWidth: 330
            Layout.fillHeight: true
            spacing: 8

            Caps {
                Layout.fillWidth: true
                text: Sys.hasBattery ? "BATTERY CAPACITY: " + Sys.batPct + " %" : "NO BATTERY"

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.bottom
                    anchors.topMargin: 3
                    height: 2
                    color: Theme.border
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 74
                Layout.topMargin: 4
                color: "transparent"
                border.width: 2
                border.color: Theme.frame

                Row {
                    id: battery

                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    Repeater {
                        model: root.cells

                        Rectangle {
                            id: cell

                            required property int index
                            readonly property bool full: index < Math.floor(root.filled)
                            readonly property bool partial: !full && index < root.filled

                            width: (battery.width - battery.spacing * (root.cells - 1)) / root.cells
                            height: battery.height
                            color: full ? (Sys.batPct <= 15 ? Theme.accent : Theme.frame) : partial ? "transparent" : Theme.surface2

                            Hatch {
                                visible: cell.partial
                                anchors.fill: parent
                                color: Theme.frame
                                lineWidth: 4
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                PText {
                    text: Sys.timeLeft
                    font.pixelSize: 24
                }

                Item {
                    Layout.fillWidth: true
                }

                PText {
                    visible: Sys.onBattery && Sys.watts > 0
                    text: Sys.watts.toFixed(1) + " W"
                    color: Theme.muted
                    font.pixelSize: 24
                }
            }
        }

        // The floppy: opens the dots repository in yazi
        ColumnLayout {
            Layout.preferredWidth: 104
            Layout.fillHeight: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 104
                Layout.preferredHeight: 104
                Layout.topMargin: 18
                color: floppyMouse.containsMouse ? Theme.fg : Theme.frame

                // Metal shutter
                Rectangle {
                    x: 26
                    width: 52
                    height: 36
                    color: Theme.surface

                    Rectangle {
                        x: 32
                        y: 6
                        width: 12
                        height: 22
                        color: floppyMouse.containsMouse ? Theme.fg : Theme.frame
                    }
                }

                // Label
                Rectangle {
                    x: 14
                    y: parent.height - height
                    width: 76
                    height: 44
                    color: Theme.surface

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7

                        Rectangle {
                            width: parent.width
                            height: 3
                            color: Theme.border
                        }

                        Rectangle {
                            width: parent.width
                            height: 3
                            color: Theme.border
                        }
                    }
                }

                MouseArea {
                    id: floppyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: "Open the dots folder"
                    onClicked: Quickshell.execDetached(["sh", "-c", "cd \"$(dirname \"$(readlink -f ~/.config/quickshell)\")\" && exec foot --app-id=station.files yazi"])
                }
            }

            Caps {
                Layout.alignment: Qt.AlignHCenter
                text: "DOTS V1.0"
                color: Theme.muted
                font.pixelSize: 11
            }
        }

        // SYSTEM INFO
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                Layout.bottomMargin: 6
                color: Theme.frame

                Caps {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "SYSTEM INFO"
                    color: Theme.bg
                }
            }

            Repeater {
                model: [
                    { text: "CPU: " + Sys.cpu + " % · " + Sys.temp + " °C", marked: false },
                    { text: "DISPLAY: CRT " + (Station.presetNames[Station.shown] ?? Station.shown.toUpperCase()), marked: true },
                    { text: "USAGE: " + Sys.usage, marked: false },
                    { text: "LIGHT: " + Sys.brightness + " %", marked: true }
                ]

                Rectangle {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: modelData.marked ? Theme.accent : "transparent"

                    PText {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.modelData.text
                        color: parent.modelData.marked ? Theme.bg : Theme.fg
                        font.pixelSize: 24
                        elide: Text.ElideRight
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
