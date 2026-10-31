import QtQuick
import qs.services

// One option of a row of choices (theme, preset, phosphor colour), with an
// optional colour swatch
Rectangle {
    id: root

    property string text
    property bool active
    property color swatch: "transparent"
    property int fontSize: 22
    signal clicked

    implicitHeight: 44
    color: active ? Theme.surface2 : "transparent"
    border.width: 2
    border.color: active || mouse.containsMouse ? Theme.frame : Theme.line
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.checked: active

    Row {
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            visible: root.swatch.a > 0
            width: 14
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            color: root.swatch
        }

        PText {
            text: root.text
            font.pixelSize: root.fontSize
            color: root.active ? Theme.fg : Theme.muted
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
