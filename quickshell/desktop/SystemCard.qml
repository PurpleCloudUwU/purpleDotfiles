import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// SYSTEM: CPU load over the last two minutes, memory, disk, temperature
// and uptime (services/Sys.qml). The graph can be switched off in STATION
// SETUP. A click on the header opens btop.
Rectangle {
    id: root

    color: Theme.surface
    border.width: 2
    border.color: Theme.border

    Header {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 2
        implicitHeight: 28
        fontSize: 22
        strong: false
        title: "SYSTEM"
        info: "UP " + Sys.uptimeText

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Sys.monitor()
            Accessible.role: Accessible.Button
            Accessible.name: "Open the system monitor"
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.margins: 14
        anchors.topMargin: 10
        spacing: 6

        // CPU graph: one column per reading, newest on the right
        Rectangle {
            visible: Desktop.system.graph
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            border.width: 2
            border.color: Theme.line

            Row {
                id: graph

                anchors.fill: parent
                anchors.margins: 5
                spacing: 2
                layoutDirection: Qt.RightToLeft

                readonly property int slots: 40
                readonly property var values: Sys.cpuHistory.slice().reverse()

                Repeater {
                    model: graph.slots

                    Item {
                        required property int index
                        readonly property real v: (graph.values[index] ?? 0) / 100

                        width: (graph.width - graph.spacing * (graph.slots - 1)) / graph.slots
                        height: graph.height

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(2, Math.round(parent.v * parent.height))
                            color: parent.v > 0.8 ? Theme.accent : parent.index === 0 ? Theme.frame : Theme.accent2
                        }
                    }
                }
            }

            Caps {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 6
                text: "CPU " + Sys.cpu + " %"
                color: Theme.fg
            }
        }

        Repeater {
            model: [
                { label: "CPU", value: Sys.cpu, text: Sys.cpu + " % · " + Sys.temp + " °C", graphOnly: true },
                { label: "MEM", value: Sys.memPct, text: Sys.gib(Sys.memUsed) + " / " + Sys.gib(Sys.memTotal), graphOnly: false },
                { label: "DISK", value: Sys.disk, text: Sys.disk + " % USED", graphOnly: false }
            ]

            RowLayout {
                id: meter

                required property var modelData

                // Without the graph the CPU gets a bar like the others
                visible: !modelData.graphOnly || !Desktop.system.graph
                Layout.fillWidth: true
                spacing: 10

                Caps {
                    Layout.preferredWidth: 40
                    text: meter.modelData.label
                    color: Theme.muted
                }

                Segments {
                    Layout.fillWidth: true
                    count: 16
                    gap: 2
                    implicitHeight: 12
                    value: meter.modelData.value / 100 * 16
                    on: meter.modelData.value > 85 ? Theme.accent : Theme.frame
                }

                PText {
                    Layout.preferredWidth: 130
                    horizontalAlignment: Text.AlignRight
                    text: meter.modelData.text
                    font.pixelSize: 20
                    color: Theme.fg
                }
            }
        }

        // Fills the card when the graph is off
        Item {
            visible: !Desktop.system.graph
            Layout.fillHeight: true
        }
    }
}
