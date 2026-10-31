import QtQuick
import qs.services

// Pixel button: filled when active, outlined otherwise
Rectangle {
    id: root

    property string text: ""
    property bool active: false
    property color fill: Theme.frame
    property color ink: active ? Theme.bg : Theme.fg
    property color outline: Theme.border
    property int fontSize: 26
    property int padding: 14
    property int minWidth: 48
    readonly property bool hovered: mouse.containsMouse
    signal clicked

    implicitWidth: Math.max(minWidth, label.implicitWidth + padding * 2)
    implicitHeight: 48
    color: active ? fill : "transparent"
    border.width: active ? 0 : 2
    border.color: hovered ? Theme.frame : outline

    Accessible.role: Accessible.Button
    Accessible.name: text

    PText {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.ink
        font.pixelSize: root.fontSize
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 0.9
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
