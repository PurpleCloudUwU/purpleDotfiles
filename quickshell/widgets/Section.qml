import QtQuick
import QtQuick.Layouts
import qs.services

// Small caps heading with a line under it (STATION SETUP)
Item {
    property alias text: label.text

    Layout.fillWidth: true
    implicitHeight: 22

    Caps {
        id: label
        anchors.left: parent.left
        anchors.top: parent.top
        font.letterSpacing: 2
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        color: Theme.line
    }
}
