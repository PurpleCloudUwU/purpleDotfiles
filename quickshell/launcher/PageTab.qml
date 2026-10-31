import QtQuick
import qs.services
import qs.widgets

// Vertical "PREVIOUS PAGE" / "NEXT PAGE" tab next to the program list
Rectangle {
    id: root

    property bool previous: true
    signal clicked

    color: mouse.containsMouse ? Theme.fg : Theme.frame
    Accessible.role: Accessible.Button
    Accessible.name: previous ? "Previous page" : "Next page"

    Icon {
        id: arrow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: root.previous ? parent.top : undefined
        anchors.bottom: root.previous ? undefined : parent.bottom
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        name: root.previous ? "left" : "right"
        size: 22
        color: Theme.bg
    }

    // Reads bottom to top on the left tab, top to bottom on the right one
    PText {
        anchors.centerIn: parent
        text: root.previous ? "PREVIOUS PAGE" : "NEXT PAGE"
        color: Theme.bg
        font.letterSpacing: 3
        rotation: root.previous ? -90 : 90
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
