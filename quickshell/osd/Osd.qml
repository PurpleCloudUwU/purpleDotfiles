import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.widgets

// Volume and brightness OSD at the bottom (no input, clicks pass through)
PanelWindow {
    id: win

    visible: Panels.osdVisible
    screen: Wm.focusedScreen
    anchors.bottom: true
    margins.bottom: 96
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 560
    implicitHeight: 84
    color: "transparent"
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "station-osd"

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        border.width: 2
        border.color: Theme.frame

        Caps {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 16
            anchors.topMargin: 12
            text: Panels.osdKind === "brightness" ? "BRIGHTNESS" : Sys.muted ? "VOLUME · MUTED" : "VOLUME"
        }

        PText {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 16
            anchors.topMargin: 2
            text: Panels.osdValue + " %"
        }

        Segments {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            height: 24
            value: Panels.osdValue / 5
            on: Panels.osdKind === "brightness" ? Theme.accent : Theme.frame
        }
    }
}
