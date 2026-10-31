import QtQuick
import qs.services

// Header strip of a framed panel: marker, title, hatching, info on the right.
// `strong` is the bright version of the focused window on the canvas.
Rectangle {
    id: root

    property string title: ""
    property string info: ""
    property bool strong: true
    property int fontSize: 24
    readonly property color ink: strong ? Theme.bg : Theme.muted

    implicitHeight: 34
    color: strong ? Theme.frame : Theme.surface2

    Row {
        id: titleRow
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Rectangle {
            width: 6
            height: 18
            anchors.verticalCenter: parent.verticalCenter
            color: root.strong ? Theme.bg : Theme.border
        }

        PText {
            text: root.title
            color: root.ink
            font.pixelSize: root.fontSize
        }
    }

    Hatch {
        visible: root.strong
        anchors.left: titleRow.right
        anchors.right: infoText.left
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - 16
        color: Theme.bg
        opacity: 0.45
    }

    PText {
        id: infoText
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.info
        color: root.ink
        font.pixelSize: root.fontSize
    }
}
