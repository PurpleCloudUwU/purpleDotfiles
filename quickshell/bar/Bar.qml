import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.widgets

// Top bar (canvas boards 01-04): STATION, workspaces, the focused window,
// and the status box with WIFI, VOL, BAT, clock and the OFF button.
// All sizes are the canvas sizes times Theme.barScale.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    // Canvas pixels to bar pixels
    function px(v) {
        return Math.max(1, Math.round(v * Theme.barScale));
    }

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: Theme.barTop
        left: 24
        right: 24
    }
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "station-bar"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        anchors.fill: parent
        spacing: bar.px(12)

        // STATION: opens the program select
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: station.implicitWidth + bar.px(32)
            color: Theme.frame

            Row {
                id: station
                anchors.centerIn: parent
                spacing: bar.px(10)

                Rectangle {
                    width: bar.px(18)
                    height: bar.px(18)
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    border.width: bar.px(3)
                    border.color: Theme.bg

                    Rectangle {
                        width: bar.px(4)
                        height: bar.px(4)
                        anchors.centerIn: parent
                        color: Theme.bg
                    }
                }

                BarText {
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

        // Workspaces that exist right now, just their numbers
        Row {
            id: workspaces

            Layout.fillHeight: true
            spacing: bar.px(6)

            Repeater {
                model: Wm.workspaceIds

                Btn {
                    required property int modelData
                    readonly property var ws: Wm.workspace(modelData)
                    readonly property bool focused: Hyprland.focusedWorkspace?.id === modelData
                    readonly property bool used: (ws?.toplevels.values.length ?? 0) > 0

                    height: Theme.barHeight
                    minWidth: Theme.barHeight
                    fontSize: Math.round(26 * Theme.barScale)
                    padding: bar.px(10)
                    active: focused
                    text: String(modelData)
                    ink: focused ? Theme.bg : used ? Theme.fg : Theme.muted
                    outline: ws?.urgent ? Theme.accent : used ? Theme.muted : Theme.line
                    Accessible.name: "Workspace " + modelData + (focused ? ", active" : "")
                    onClicked: Wm.focusWorkspace(modelData)
                }
            }
        }

        // The window title sits on top, in the middle of the bar
        Item {
            Layout.fillWidth: true
        }

        // Status box
        Rectangle {
            id: statusBox

            Layout.fillHeight: true
            implicitWidth: status.implicitWidth + bar.px(18)
            color: "transparent"
            border.width: 2
            border.color: Theme.line

            Row {
                id: status
                anchors.left: parent.left
                anchors.leftMargin: bar.px(18)
                anchors.verticalCenter: parent.verticalCenter
                spacing: bar.px(24)

                // WIFI: opens the PDA quick access
                Item {
                    implicitWidth: wifi.implicitWidth
                    implicitHeight: Theme.barHeight - 4
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: wifi
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: bar.px(8)

                        BarText {
                            text: Net.enabled ? "WIFI" : "WIFI OFF"
                            color: Theme.muted
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: bar.px(3)

                            Repeater {
                                model: 4

                                Rectangle {
                                    required property int index
                                    width: bar.px(5)
                                    height: bar.px([6, 10, 15, 20][index])
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
                    implicitHeight: Theme.barHeight - 4
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: vol
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: bar.px(8)

                        BarText {
                            text: "VOL"
                            color: Theme.muted
                        }

                        BarText {
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
                    spacing: bar.px(8)

                    BarText {
                        text: Sys.charging ? "CHG" : "BAT"
                        color: Theme.muted
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            width: cells.implicitWidth + bar.px(8)
                            height: bar.px(22)
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.fg

                            Row {
                                id: cells
                                anchors.centerIn: parent
                                spacing: bar.px(2)

                                Repeater {
                                    model: 5

                                    Rectangle {
                                        required property int index
                                        width: bar.px(7)
                                        height: bar.px(14)
                                        color: index < Math.ceil(Sys.batPct / 20) ? (Sys.batPct <= 15 ? Theme.accent : Theme.fg) : Theme.off
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: bar.px(3)
                            height: bar.px(8)
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.fg
                        }
                    }

                    BarText {
                        text: Sys.batPct + " %"
                        color: Sys.batPct <= 15 && !Sys.charging ? Theme.accent : Theme.fg
                    }
                }

                BarText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "hh:mm")
                    font.pixelSize: bar.px(30)
                }

                BarText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: clock.date.toLocaleDateString(Qt.locale("en_US"), "ddd dd.MM.").toUpperCase()
                    color: Theme.muted
                }

                Btn {
                    anchors.verticalCenter: parent.verticalCenter
                    height: Theme.barHeight - 4
                    minWidth: Theme.barHeight
                    padding: bar.px(16)
                    fontSize: Math.round(26 * Theme.barScale)
                    text: "OFF"
                    active: true
                    fill: Theme.accent
                    Accessible.name: "Power menu"
                    onClicked: Panels.toggle("power")
                }
            }
        }
    }

    // Focused window, always in the middle of the bar, however wide the
    // workspaces and the status box are. Long titles get shortened.
    Row {
        id: windowTitle

        // Free width around the middle, the same on both sides
        readonly property real room: bar.width - 2 * Math.max(workspaces.x + workspaces.width, bar.width - statusBox.x) - 2 * bar.px(24)

        anchors.centerIn: parent
        spacing: bar.px(12)
        visible: room > windowLabel.width + bar.px(60)

        BarText {
            id: windowLabel
            text: "WINDOW:"
            color: Theme.muted
        }

        BarText {
            text: Wm.title
            width: Math.min(implicitWidth, windowTitle.room - windowLabel.width - windowTitle.spacing)
            elide: Text.ElideMiddle

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: -bar.px(6)
                anchors.rightMargin: -bar.px(6)
                height: 2
                color: Theme.accent
            }
        }
    }
}
