import QtQuick
import qs.services

// One-line text field in the display font. Return or Enter sends
// `accepted` with the text.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property int fontSize: 24
    signal accepted(string text)

    implicitWidth: 240
    implicitHeight: 44
    color: Theme.bg
    border.width: 2
    border.color: input.activeFocus ? Theme.frame : mouse.containsMouse ? Theme.border : Theme.line

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        onClicked: input.forceActiveFocus()
    }

    TextInput {
        id: input

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: root.fontSize
        clip: true
        selectByMouse: true
        selectionColor: Theme.frame
        selectedTextColor: Theme.bg
        Accessible.role: Accessible.EditableText
        Accessible.name: root.placeholder
        onAccepted: root.accepted(text)
        Keys.onEscapePressed: event => {
            focus = false;
            event.accepted = true;
        }
    }

    PText {
        anchors.left: input.left
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text === "" && !input.activeFocus
        text: root.placeholder
        color: Theme.faint
        font.pixelSize: root.fontSize
    }
}
