import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

// DESKTOP WIDGETS page of STATION SETUP: drag the widgets on the small
// screen, show or hide them and set them up. Everything applies right away
// and is kept in ~/.local/state/station/desktop.json.
ColumnLayout {
    id: page

    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: 32
        Layout.rightMargin: 32
        Layout.topMargin: 26
        Layout.bottomMargin: 26
        spacing: 40
        focus: true
        Keys.onEscapePressed: Panels.crt = false

        // The small screen
        ColumnLayout {
            Layout.preferredWidth: 768
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Section {
                text: "LAYOUT · DRAG THE WIDGETS"
            }

            MiniScreen {
                Layout.preferredWidth: 768
                Layout.preferredHeight: 768 * screenH / screenW
            }

            PText {
                text: "Snaps to an 8 px grid on the " + (Wm.primaryScreen?.width ?? 1920) + "×" + (Wm.primaryScreen?.height ?? 1080) + " screen"
                color: Theme.muted
                font.pixelSize: 22
            }

            Repeater {
                model: ["music", "tasks", "pda"]

                PText {
                    required property string modelData
                    readonly property var cfg: Desktop.widget(modelData)

                    text: Desktop.names[modelData] + "  X " + cfg.x + "  Y " + cfg.y + (cfg.visible ? "" : "  · HIDDEN")
                    color: cfg.visible ? Theme.fg : Theme.muted
                    font.pixelSize: 22
                }
            }

            // Lets the column (and the page) grow to the window height
            Item {
                Layout.fillHeight: true
            }
        }

        // Settings per widget
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 6

            Section {
                text: "MUSIC"
            }

            Check {
                text: "Show"
                checked: Desktop.music.visible
                onToggled: Desktop.update("music", { visible: !checked })
            }

            Check {
                text: "Visualizer (cava)"
                checked: Desktop.music.visualizer
                onToggled: Desktop.update("music", { visualizer: !checked })
            }

            PText {
                Layout.fillWidth: true
                text: Cava.available ? "Real levels while music plays" : "cava is not installed, the bars only hop"
                color: Theme.muted
                font.pixelSize: 22
                elide: Text.ElideRight
            }

            Section {
                Layout.topMargin: 14
                text: "TASKS"
            }

            Check {
                text: "Show"
                checked: Desktop.tasks.visible
                onToggled: Desktop.update("tasks", { visible: !checked })
            }

            Check {
                text: "Show done tasks"
                checked: Desktop.tasks.showDone
                onToggled: Desktop.update("tasks", { showDone: !checked })
            }

            Btn {
                Layout.topMargin: 4
                implicitHeight: 44
                text: "EDIT TASKS"
                fontSize: 24
                outline: Theme.muted
                onClicked: Tasks.edit()
            }

            Section {
                Layout.topMargin: 14
                text: "PDA PANEL"
            }

            Check {
                text: "Show"
                checked: Desktop.pda.visible
                onToggled: Desktop.update("pda", { visible: !checked })
            }

            Section {
                Layout.topMargin: 14
                text: "WINDOWS"
            }

            Check {
                text: "Keep the right column free"
                checked: Desktop.column
                onToggled: Desktop.setColumn(!checked)
            }

            // Lets the column (and the page) grow to the window height
            Item {
                Layout.fillHeight: true
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 2
        color: Theme.line
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 74
        Layout.leftMargin: 32
        Layout.rightMargin: 32
        spacing: 10

        PText {
            Layout.fillWidth: true
            text: "CHANGES APPLY RIGHT AWAY · ~/.local/state/station/desktop.json"
            color: Theme.frame
            font.pixelSize: 23
            elide: Text.ElideRight
        }

        Btn {
            implicitHeight: 48
            text: "RESET LAYOUT"
            padding: 20
            outline: Theme.muted
            onClicked: Desktop.reset()
        }
    }
}
