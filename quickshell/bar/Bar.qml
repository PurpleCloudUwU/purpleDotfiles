import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.widgets

// Top bar (canvas boards 01-04): STATION, workspaces, the focused window,
// and the status box with WIFI, VOL, BAT, clock and the OFF button.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 16
        left: 24
        right: 24
    }
    implicitHeight: 48
    color: "transparent"
    WlrLayershell.namespace: "station-bar"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12

        // STATION: opens the program select
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: station.implicitWidth + 32
            color: Theme.frame

            Row {
                id: station
                anchors.centerIn: parent
                spacing: 10

                Rectangle {
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    border.width: 3
                    border.color: Theme.bg

                    Rectangle {
                        width: 4
                        height: 4
                        anchors.centerIn: parent
                        color: Theme.bg
                    }
                }

                PText {
                    text: "STATION"
                    color: Theme.bg
                    font.letterSpacing: 1
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Panels.toggle("launcher")
            }
        }

        // Workspaces
        Row {
            Layout.fillHeight: true
            spacing: 6

            Repeater {
                model: Wm.workspaceIds

                Btn {
                    required property int modelData
                    readonly property var ws: Wm.workspace(modelData)
                    readonly property bool focused: Hyprland.focusedWorkspace?.id === modelData
                    readonly property bool used: (ws?.toplevels.values.length ?? 0) > 0
                    readonly property string label: Wm.names[String(modelData)] ?? ""

                    height: 48
                    padding: focused ? 14 : 0
                    active: focused
                    text: focused && label ? modelData + " " + label : String(modelData)
                    ink: focused ? Theme.bg : used ? Theme.fg : Theme.muted
                    outline: ws?.urgent ? Theme.accent : used ? Theme.muted : Theme.line
                    Accessible.name: "Workspace " + modelData + (focused ? ", active" : "")
                    onClicked: Wm.focusWorkspace(modelData)
                }
            }
        }

        // Focused window
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Row {
                anchors.centerIn: parent
                spacing: 12

                PText {
                    text: "WINDOW:"
                    color: Theme.muted
                }

                PText {
                    id: title
                    text: Wm.title
                    width: Math.min(implicitWidth, 640)
                    elide: Text.ElideMiddle

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: -6
                        anchors.rightMargin: -6
                        height: 2
                        color: Theme.accent
                    }
                }
            }
        }

        // Status box
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: status.implicitWidth + 18
            color: "transparent"
            border.width: 2
            border.color: Theme.line

            Row {
                id: status
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 24

                // WIFI: opens the PDA quick access
                Item {
                    implicitWidth: wifi.implicitWidth
                    implicitHeight: 44
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: wifi
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        PText {
                            text: Net.enabled ? "WIFI" : "WIFI OFF"
                            color: Theme.muted
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Repeater {
                                model: 4

                                Rectangle {
                                    required property int index
                                    width: 5
                                    height: [6, 10, 15, 20][index]
                                    anchors.bottom: parent.bottom
                                    color: index < Net.bars ? Theme.fg : Theme.line
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Panels.toggle("quick")
                        Accessible.role: Accessible.Button
                        Accessible.name: "Network, open quick access"
                    }
                }

                // VOL: the wheel changes it, a click mutes
                Item {
                    implicitWidth: vol.implicitWidth
                    implicitHeight: 44
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: vol
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        PText {
                            text: "VOL"
                            color: Theme.muted
                        }

                        PText {
                            text: Sys.muted ? "--" : Sys.volume
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Sys.toggleMute()
                        onWheel: wheel => Sys.setVolume(Sys.volume + (wheel.angleDelta.y > 0 ? 5 : -5))
                        Accessible.role: Accessible.Button
                        Accessible.name: "Volume " + Sys.volume + ", mute"
                    }
                }

                // BAT with the cell icon
                Row {
                    visible: Sys.hasBattery
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    PText {
                        text: Sys.charging ? "CHG" : "BAT"
                        color: Theme.muted
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            width: cells.implicitWidth + 8
                            height: 22
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.fg

                            Row {
                                id: cells
                                anchors.centerIn: parent
                                spacing: 2

                                Repeater {
                                    model: 5

                                    Rectangle {
                                        required property int index
                                        width: 7
                                        height: 14
                                        color: index < Math.ceil(Sys.batPct / 20) ? (Sys.batPct <= 15 ? Theme.accent : Theme.fg) : Theme.off
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 3
                            height: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.fg
                        }
                    }

                    PText {
                        text: Sys.batPct + " %"
                        color: Sys.batPct <= 15 && !Sys.charging ? Theme.accent : Theme.fg
                    }
                }

                PText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "hh:mm")
                    font.pixelSize: 30
                }

                PText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: clock.date.toLocaleDateString(Qt.locale("en_US"), "ddd dd.MM.").toUpperCase()
                    color: Theme.muted
                }

                Btn {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 44
                    text: "OFF"
                    active: true
                    fill: Theme.accent
                    Accessible.name: "Power menu"
                    onClicked: Panels.toggle("power")
                }
            }
        }
    }
}
