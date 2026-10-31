import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.widgets

// Notifications top right, like "ACCESS POINT FOUND" on canvas board 02.
// A click runs the default action (or dismisses), Super+Shift+N clears all.
PanelWindow {
    id: win

    visible: Notifs.toasts.length > 0
    screen: Wm.focusedScreen
    anchors {
        top: true
        right: true
    }
    margins {
        top: 88
        right: 24
    }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 560
    implicitHeight: Math.max(1, list.implicitHeight)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "station-toast"

    Column {
        id: list

        width: parent.width
        spacing: 12

        Repeater {
            model: Notifs.toasts

            Rectangle {
                id: toast

                required property var modelData

                width: 560
                height: Math.max(96, texts.implicitHeight + 20)
                color: Theme.surface
                border.width: 2
                border.color: modelData.urgent ? Theme.accent : toastMouse.containsMouse ? Theme.fg : Theme.accent
                Accessible.role: Accessible.AlertMessage
                Accessible.name: modelData.title + ". " + modelData.body

                Rectangle {
                    id: badge
                    width: 76
                    height: parent.height
                    color: Theme.accent

                    Icon {
                        anchors.centerIn: parent
                        name: toast.modelData.icon
                        size: 38
                    }
                }

                Column {
                    id: texts

                    anchors.left: badge.right
                    anchors.right: parent.right
                    anchors.leftMargin: 18
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    PText {
                        width: parent.width
                        text: toast.modelData.title
                        font.pixelSize: 30
                        elide: Text.ElideRight
                    }

                    PText {
                        visible: text !== ""
                        width: parent.width
                        text: toast.modelData.body
                        textFormat: Text.PlainText
                        color: Theme.fg2
                        font.pixelSize: 23
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }

                // The list is rebuilt on every change, so count from the
                // toast's creation, not from this delegate's
                Timer {
                    running: toast.modelData.timeout > 0
                    interval: Math.max(1, toast.modelData.timeout - (Date.now() - toast.modelData.created))
                    onTriggered: Notifs.expire(toast.modelData.uid)
                }

                MouseArea {
                    id: toastMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.activate(toast.modelData.uid)
                }
            }
        }
    }
}
