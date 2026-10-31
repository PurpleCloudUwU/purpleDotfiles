import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// MUSIC (canvas board 04): whatever MPRIS player runs (Spotify, kew, ...).
// The level bars only move while something plays.
Rectangle {
    id: root

    color: Theme.surface
    border.width: 2
    border.color: Theme.border

    Header {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 2
        strong: false
        title: "MUSIC"
        info: Player.source || "mpris"
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.margins: 16
        spacing: 20

        // Level bars
        Rectangle {
            Layout.preferredWidth: 120
            Layout.fillHeight: true
            color: "transparent"
            border.width: 2
            border.color: Theme.line

            Row {
                id: levels

                // Real levels from cava while it runs; a resting skyline
                // otherwise, which hops at random if cava is missing
                property var resting: [0.35, 0.6, 0.85, 0.7, 0.5, 0.95, 0.75, 0.45, 0.6, 0.3]
                readonly property var heights: Cava.levels.length === 10 ? Cava.levels.map(v => 0.06 + v * 0.94) : resting

                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                Repeater {
                    model: levels.heights.length

                    Column {
                        id: level

                        required property int index
                        readonly property int segments: Math.max(1, Math.round(levels.heights[index] * levels.height / 9))

                        width: (levels.width - levels.spacing * 9) / 10
                        height: levels.height
                        spacing: 3
                        topPadding: height - segments * 9 + 3

                        Repeater {
                            model: level.segments

                            Rectangle {
                                width: level.width
                                height: 6
                                color: level.index % 3 === 1 ? Theme.accent : Theme.accent2
                                opacity: Player.playing ? 1 : 0.4
                            }
                        }
                    }
                }

                Timer {
                    interval: 250
                    repeat: true
                    running: Player.playing && !Cava.available && Desktop.music.visualizer
                    onTriggered: levels.resting = levels.resting.map(() => 0.15 + Math.random() * 0.85)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            Caps {
                text: Player.current ? (Player.playing ? "PLAYING" : "PAUSED") : "IDLE"
                color: Theme.muted
            }

            PText {
                Layout.fillWidth: true
                text: Player.title.toUpperCase()
                font.pixelSize: 34
                elide: Text.ElideRight
            }

            PText {
                Layout.fillWidth: true
                text: [Player.artist, Player.album].filter(s => s).join(" · ") || "NO PLAYER RUNNING"
                color: Theme.muted
                font.pixelSize: 22
                elide: Text.ElideRight
            }

            Segments {
                Layout.fillWidth: true
                Layout.topMargin: 6
                count: 24
                gap: 3
                implicitHeight: 12
                value: Player.length > 0 ? Player.position / Player.length * 24 : 0
                on: Theme.accent
            }

            RowLayout {
                Layout.fillWidth: true

                PText {
                    text: Player.clock(Player.position)
                    color: Theme.muted
                    font.pixelSize: 22
                }

                Item {
                    Layout.fillWidth: true
                }

                PText {
                    text: Player.clock(Player.length)
                    color: Theme.muted
                    font.pixelSize: 22
                }
            }

            Item {
                Layout.fillHeight: true
            }

            Row {
                spacing: 8

                Repeater {
                    model: [
                        { icon: "prev", label: "Previous track", main: false },
                        { icon: Player.playing ? "pause" : "play", label: Player.playing ? "Pause" : "Play", main: true },
                        { icon: "next", label: "Next track", main: false }
                    ]

                    Rectangle {
                        id: button

                        required property var modelData

                        width: modelData.main ? 64 : 52
                        height: 44
                        color: modelData.main ? Theme.accent : "transparent"
                        border.width: modelData.main ? 0 : 2
                        border.color: buttonMouse.containsMouse ? Theme.frame : Theme.border
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.label

                        Icon {
                            anchors.centerIn: parent
                            name: button.modelData.icon
                            size: 20
                            color: button.modelData.main ? Theme.bg : Theme.fg
                        }

                        MouseArea {
                            id: buttonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: Player.current !== null
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (button.modelData.icon === "prev")
                                    Player.current.previous();
                                else if (button.modelData.icon === "next")
                                    Player.current.next();
                                else
                                    Player.current.togglePlaying();
                            }
                        }
                    }
                }
            }
        }
    }
}
