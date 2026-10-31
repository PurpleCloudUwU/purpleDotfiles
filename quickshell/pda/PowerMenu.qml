import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.widgets

// "POWER:" menu under the bar's OFF button (Super+Shift+E)
PanelWindow {
    id: win

    visible: Panels.power
    screen: Wm.focusedScreen
    anchors {
        top: true
        right: true
    }
    margins {
        top: 72
        right: 24
    }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 320
    implicitHeight: content.implicitHeight + 6
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "station-power"

    onVisibleChanged: {
        grab.active = visible;
        if (visible)
            content.forceActiveFocus();
    }

    HyprlandFocusGrab {
        id: grab
        windows: [win]
        onCleared: Panels.dismissed()
    }

    function run(action) {
        Panels.power = false;
        Quickshell.execDetached(["station", "power", action]);
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        border.width: 3
        border.color: Theme.frame
    }

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 3
        spacing: 8
        focus: true
        Keys.onEscapePressed: Panels.power = false

        Header {
            Layout.fillWidth: true
            title: "POWER"
            info: Sys.hasBattery ? "BAT " + Sys.batPct + " %" : ""
        }

        Repeater {
            model: [
                { label: "LOCK", action: "lock" },
                { label: "LOG OUT", action: "logout" },
                { label: "SUSPEND", action: "suspend" },
                { label: "REBOOT", action: "reboot" }
            ]

            Btn {
                required property var modelData
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                implicitHeight: 52
                text: modelData.label
                outline: Theme.line
                onClicked: win.run(modelData.action)
            }
        }

        Btn {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.bottomMargin: 12
            implicitHeight: 52
            text: "OFF"
            active: true
            fill: Theme.accent
            onClicked: win.run("off")
        }
    }
}
