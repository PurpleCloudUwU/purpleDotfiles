import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs.services
import qs.widgets

// "PDA: QUICK ACCESS" (canvas board 04): WiFi, brightness, volume, toggles
// and the current profile, plus quick theme and CRT preset switches
// (the CRT calibration window has all settings).
PanelWindow {
    id: win

    visible: Panels.quick
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
    implicitWidth: 596
    implicitHeight: content.implicitHeight + 6
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "station-pda"

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property int rows: 6
    property int netPage: 0
    readonly property int netPages: Math.max(1, Math.ceil(Net.sorted.length / rows))
    readonly property var netItems: Net.sorted.slice(netPage * rows, netPage * rows + rows)
    property var pskTarget: null

    onVisibleChanged: {
        grab.active = visible;
        Net.scanning = visible;
        netPage = 0;
        pskTarget = null;
        if (visible)
            content.forceActiveFocus();
    }

    HyprlandFocusGrab {
        id: grab
        windows: [win]
        onCleared: Panels.dismissed()
    }

    function connect(net) {
        if (net.connected)
            net.disconnect();
        else if (Net.needsPassword(net))
            pskTarget = net;
        else
            net.connect();
    }

    function cycleProfile() {
        const order = [PowerProfile.PowerSaver, PowerProfile.Balanced];
        if (PowerProfiles.hasPerformanceProfile)
            order.push(PowerProfile.Performance);
        const i = order.indexOf(PowerProfiles.profile);
        PowerProfiles.profile = order[(i + 1) % order.length];
    }

    readonly property string profileName: {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            return "SAVER";
        case PowerProfile.Performance:
            return "PERFORMANCE";
        default:
            return "BALANCED";
        }
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
        spacing: 12
        focus: true
        Keys.onEscapePressed: Panels.quick = false

        // PDA: QUICK ACCESS [BACK]
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            spacing: 10

            PText {
                Layout.leftMargin: 14
                text: "PDA:"
                font.pixelSize: 36
            }

            PText {
                Layout.fillWidth: true
                text: "QUICK ACCESS"
                font.pixelSize: 30

                Rectangle {
                    y: parent.height - 6
                    width: parent.implicitWidth
                    height: 2
                    color: Theme.accent
                }
            }

            Btn {
                Layout.fillHeight: true
                text: "BACK"
                fontSize: 28
                padding: 18
                active: true
                fill: Theme.accent
                onClicked: Panels.quick = false
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 2
            Layout.topMargin: -12
            color: Theme.line
        }

        // SELECT NETWORK
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            implicitHeight: netGrid.implicitHeight + 6
            color: "transparent"
            border.width: 3
            border.color: Theme.frame

            GridLayout {
                id: netGrid

                anchors.fill: parent
                anchors.margins: 3
                columns: 3
                rowSpacing: 0
                columnSpacing: 0

                Rectangle {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    color: Theme.frame

                    PText {
                        anchors.centerIn: parent
                        text: !Net.wifi ? "NO WIFI DEVICE" : Net.enabled ? "SELECT NETWORK" : "WIFI IS OFF"
                        color: Theme.bg
                        font.pixelSize: 28
                        font.letterSpacing: 1
                    }
                }

                // Vertical "NEXT PAGE" tab over the whole list
                Rectangle {
                    Layout.rowSpan: 2
                    Layout.fillHeight: true
                    Layout.preferredWidth: 44
                    color: tabMouse.containsMouse ? Theme.fg : Theme.frame

                    Icon {
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "right"
                        size: 18
                    }

                    PText {
                        anchors.centerIn: parent
                        rotation: 90
                        text: "NEXT PAGE"
                        color: Theme.bg
                        font.pixelSize: 24
                        font.letterSpacing: 3
                    }

                    Icon {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "right"
                        size: 18
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.netPage = (win.netPage + 1) % win.netPages
                        Accessible.role: Accessible.Button
                        Accessible.name: "Next page of networks"
                    }
                }

                // Network rows
                Column {
                    Layout.fillWidth: true

                    Repeater {
                        model: win.rows

                        Rectangle {
                            id: netRow

                            required property int index
                            readonly property var net: win.netItems[index] ?? null

                            width: parent.width
                            height: 40
                            color: net?.connected ? Theme.accent : index % 2 === 0 ? Theme.surface2 : Theme.surface3

                            PText {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: netState.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: netRow.net ? netRow.net.name.toUpperCase() : "..."
                                color: netRow.net?.connected ? Theme.bg : netRow.net ? Theme.fg : Theme.muted
                                font.pixelSize: 27
                                elide: Text.ElideRight
                            }

                            PText {
                                id: netState
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: !netRow.net ? "" : netRow.net.stateChanging ? "..." : netRow.net.connected ? "CONNECTED" : netRow.net.known ? "SAVED" : ""
                                color: netRow.net?.connected ? Theme.bg : Theme.muted
                                font.pixelSize: 22
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: netRow.net !== null
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.connect(netRow.net)
                            }

                            Connections {
                                target: netRow.net
                                ignoreUnknownSignals: true

                                function onConnectionFailed(reason) {
                                    if (reason === ConnectionFailReason.NoSecrets)
                                        win.pskTarget = netRow.net;
                                }
                            }
                        }
                    }

                    // Hidden networks and everything else: nmtui
                    Rectangle {
                        width: parent.width
                        height: 40
                        color: Theme.surface2

                        PText {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "HIDDEN NETWORK"
                            font.pixelSize: 27
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["foot", "--app-id=station.net", "nmtui"]);
                                Panels.quick = false;
                            }
                        }
                    }
                }

                // Signal column
                Column {
                    Layout.preferredWidth: 52
                    Layout.alignment: Qt.AlignTop

                    Repeater {
                        model: win.rows

                        Rectangle {
                            id: cell

                            required property int index
                            readonly property var net: win.netItems[index] ?? null

                            width: 52
                            height: 40
                            color: Theme.frame
                            border.width: 1
                            border.color: Theme.surface

                            Row {
                                visible: cell.net !== null
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 10
                                spacing: 3

                                Repeater {
                                    model: 4

                                    Rectangle {
                                        required property int index
                                        width: 4
                                        height: 6 + index * 4
                                        anchors.bottom: parent.bottom
                                        color: cell.net && index < Net.barsFor(cell.net) ? Theme.bg : Theme.withAlpha(Theme.bg, 0.3)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 52
                        height: 40
                        color: Theme.frame
                        border.width: 1
                        border.color: Theme.surface

                        Icon {
                            anchors.centerIn: parent
                            name: "plus"
                            size: 22
                        }
                    }
                }
            }
        }

        // Password for a new network
        RowLayout {
            visible: win.pskTarget !== null
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                color: "transparent"
                border.width: 2
                border.color: Theme.frame

                PText {
                    id: pskLabel
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "KEY ›"
                    color: Theme.muted
                    font.pixelSize: 24
                }

                TextInput {
                    id: psk
                    anchors.left: pskLabel.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 24
                    Accessible.role: Accessible.EditableText
                    Accessible.name: "WiFi password for " + (win.pskTarget?.name ?? "")
                    onAccepted: {
                        win.pskTarget?.connectWithPsk(text);
                        text = "";
                        win.pskTarget = null;
                    }
                }
            }

            Btn {
                implicitHeight: 44
                text: "JOIN"
                fontSize: 24
                active: true
                onClicked: psk.accepted()
            }
        }

        // BRIGHTNESS / VOLUME
        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            columns: 3
            columnSpacing: 12
            rowSpacing: 10

            PText {
                Layout.preferredWidth: 158
                text: "BRIGHTNESS"
                font.pixelSize: 25
            }

            Segments {
                Layout.fillWidth: true
                value: Sys.brightness / 5
                on: Theme.accent
                interactive: true
                onPicked: cells => Sys.setBrightness(cells * 5)
            }

            PText {
                Layout.preferredWidth: 64
                horizontalAlignment: Text.AlignRight
                text: Sys.brightness + " %"
                font.pixelSize: 25
            }

            PText {
                text: "VOLUME"
                font.pixelSize: 25
            }

            Segments {
                Layout.fillWidth: true
                value: Sys.muted ? 0 : Sys.volume / 5
                on: Theme.accent2
                interactive: true
                onPicked: cells => Sys.setVolume(cells * 5)
            }

            PText {
                Layout.preferredWidth: 64
                horizontalAlignment: Text.AlignRight
                text: Sys.muted ? "MUTE" : Sys.volume + " %"
                font.pixelSize: 25
            }
        }

        // Toggles and the current profile
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            spacing: 14

            GridLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Btn {
                    Layout.fillWidth: true
                    implicitHeight: 60
                    text: "BLUETOOTH"
                    fontSize: 23
                    active: win.adapter?.enabled ?? false
                    fill: Theme.accent
                    onClicked: if (win.adapter) win.adapter.enabled = !win.adapter.enabled
                }

                Btn {
                    Layout.fillWidth: true
                    implicitHeight: 60
                    text: "DO NOT\nDISTURB"
                    fontSize: 23
                    active: Notifs.dnd
                    fill: Theme.accent
                    onClicked: Notifs.dnd = !Notifs.dnd
                }

                Btn {
                    Layout.fillWidth: true
                    implicitHeight: 60
                    text: "NIGHT LIGHT"
                    fontSize: 23
                    active: Sys.nightLight
                    fill: Theme.accent
                    onClicked: Sys.nightLight = !Sys.nightLight
                }

                Btn {
                    readonly property bool airplane: !Networking.wifiEnabled && !(win.adapter?.enabled ?? false)

                    Layout.fillWidth: true
                    implicitHeight: 60
                    text: "AIRPLANE\nMODE"
                    fontSize: 23
                    active: airplane
                    fill: Theme.accent
                    onClicked: {
                        Networking.wifiEnabled = airplane;
                        if (win.adapter)
                            win.adapter.enabled = airplane;
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                implicitHeight: profile.implicitHeight + 4
                color: "transparent"
                border.width: 2
                border.color: Theme.frame

                Column {
                    id: profile

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 2

                    Rectangle {
                        width: parent.width
                        height: 22
                        color: Theme.frame

                        Caps {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "CURRENT PROFILE"
                            color: Theme.bg
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 28
                        color: Theme.accent

                        PText {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "POWER: " + win.profileName
                            color: Theme.bg
                            font.pixelSize: 23
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.cycleProfile()
                            Accessible.role: Accessible.Button
                            Accessible.name: "Power profile " + win.profileName + ", change"
                        }
                    }

                    PText {
                        leftPadding: 8
                        height: 28
                        text: "USAGE: " + Sys.usage
                        font.pixelSize: 23
                    }

                    Rectangle {
                        width: parent.width
                        height: 28
                        color: Theme.accent

                        PText {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "CRT: " + (Station.presetNames[Station.shown] ?? Station.shown.toUpperCase())
                            color: Theme.bg
                            font.pixelSize: 23
                        }
                    }

                    PText {
                        leftPadding: 8
                        height: 28
                        text: Sys.hasBattery ? "BAT: " + Sys.batPct + " % · " + Sys.timeLeft.replace("≈ ", "") : "BAT: NONE"
                        font.pixelSize: 23
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.preferredHeight: 2
            color: Theme.line
        }

        // THEME (also in the CRT calibration window)
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            spacing: 8

            Caps {
                Layout.preferredWidth: 64
                text: "THEME"
                color: Theme.muted
            }

            Repeater {
                model: ["amber", "red", "green", "violet"]

                Choice {
                    required property string modelData
                    Layout.fillWidth: true
                    text: modelData.toUpperCase()
                    swatch: Theme.swatches[modelData]
                    active: Theme.name === modelData
                    onClicked: Station.setTheme(modelData)
                }
            }
        }

        // CRT preset
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.bottomMargin: 14
            spacing: 8

            Caps {
                Layout.preferredWidth: 64
                text: "CRT"
                color: Theme.muted
            }

            Repeater {
                model: ["off", "work", "subtle", "full"]

                Choice {
                    required property string modelData
                    Layout.fillWidth: true
                    text: Station.presetNames[modelData]
                    active: Station.preset === modelData
                    onClicked: Station.setPreset(modelData)
                }
            }
        }
    }
}
