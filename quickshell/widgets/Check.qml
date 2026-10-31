import QtQuick
import qs.services

// Pixel checkbox with a label (canvas board 03, "BEHAVIOR")
Item {
    id: root

    property string text
    property bool checked
    property int fontSize: 25
    signal toggled

    implicitWidth: box.width + 14 + label.implicitWidth
    implicitHeight: 44
    Accessible.role: Accessible.CheckBox
    Accessible.name: text
    Accessible.checked: checked

    Rectangle {
        id: box
        width: 22
        height: 22
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        border.width: 2
        border.color: mouse.containsMouse ? Theme.fg : Theme.frame

        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            color: root.checked ? Theme.frame : "transparent"
        }
    }

    PText {
        id: label
        anchors.left: box.right
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.pixelSize: root.fontSize
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
