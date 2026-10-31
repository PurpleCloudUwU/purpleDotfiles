import QtQuick
import qs.services
import qs.widgets

// TASKS 2/5: ~/.local/share/station/tasks.txt. A click on a task ticks it
// off, a click on the header opens the file in nvim.
Rectangle {
    id: root

    implicitHeight: list.implicitHeight + header.height + 24
    color: Theme.surface
    border.width: 2
    border.color: Theme.border

    Rectangle {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 2
        height: 22
        color: Theme.frame

        Caps {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "TASKS"
            color: Theme.bg
        }

        Caps {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: Tasks.doneCount + "/" + Tasks.items.length
            color: Theme.bg
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Tasks.edit()
            Accessible.role: Accessible.Button
            Accessible.name: "Edit tasks"
        }
    }

    Column {
        id: list

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.margins: 12
        anchors.topMargin: 10
        spacing: 4

        // Done tasks can be hidden in STATION SETUP
        readonly property var shown: Desktop.tasks.showDone ? Tasks.items : Tasks.items.filter(t => !t.done)
        // The first open task is marked like on the canvas
        readonly property int firstOpen: Tasks.items.find(t => !t.done)?.line ?? -1

        PText {
            visible: list.shown.length === 0
            text: Tasks.items.length === 0 ? "NO TASKS · CLICK THE HEADER" : "ALL DONE"
            color: Theme.muted
            font.pixelSize: 20
        }

        Repeater {
            model: list.shown

            Item {
                id: task

                required property var modelData
                readonly property bool next: !modelData.done && modelData.line === list.firstOpen

                width: list.width
                height: 30

                Rectangle {
                    id: box
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: task.modelData.done ? Theme.faint : "transparent"
                    border.width: task.modelData.done ? 0 : 2
                    border.color: task.next ? Theme.accent : Theme.frame
                }

                PText {
                    anchors.left: box.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: task.modelData.text
                    color: task.modelData.done ? Theme.faint : Theme.fg
                    font.pixelSize: 23
                    font.strikeout: task.modelData.done
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Tasks.toggle(task.modelData)
                    Accessible.role: Accessible.CheckBox
                    Accessible.name: task.modelData.text
                    Accessible.checked: task.modelData.done
                }
            }
        }
    }
}
