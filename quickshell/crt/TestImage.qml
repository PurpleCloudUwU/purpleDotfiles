import QtQuick
import qs.services
import qs.widgets

// Test picture inside the preview tube (canvas board 03), drawn in one ink
Item {
    id: root

    property color ink: Theme.fg

    Column {
        x: 28
        y: 24
        width: root.width - 56

        Repeater {
            model: [Theme.user + "@" + Theme.host + " ~ $ fastfetch", "OS     Arch Linux", "WM     Hyprland", "UI     Quickshell"]

            PText {
                required property string modelData
                height: 31
                text: modelData
                color: root.ink
            }
        }

        Row {
            id: bars

            topPadding: 18
            bottomPadding: 14
            spacing: 6

            Repeater {
                model: [1, 0.8, 0.62, 0.46, 0.32, 0.2, 0.1]

                Rectangle {
                    required property real modelData
                    width: (root.width - 56 - bars.spacing * 6) / 7
                    height: 64
                    color: root.ink
                    opacity: modelData
                }
            }
        }

        Row {
            spacing: 10

            PText {
                height: 31
                text: "TEST IMAGE 01 · 1920×1080"
                color: root.ink
            }

            Rectangle {
                width: 12
                height: 22
                anchors.verticalCenter: parent.verticalCenter
                color: root.ink

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    PropertyAction { value: 1 }
                    PauseAnimation { duration: 550 }
                    PropertyAction { value: 0 }
                    PauseAnimation { duration: 550 }
                }
            }
        }
    }
}
