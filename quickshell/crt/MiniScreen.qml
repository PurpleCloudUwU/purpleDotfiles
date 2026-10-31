import QtQuick
import qs.services
import qs.widgets

// The screen in small: bar, the windows of workspace 1, the free column and
// the three desktop widgets. Drag a widget and its real twin moves along;
// positions snap to an 8 px grid on the real screen.
Rectangle {
    id: root

    readonly property real screenW: Wm.primaryScreen?.width ?? 1920
    readonly property real screenH: Wm.primaryScreen?.height ?? 1080
    readonly property real s: width / screenW
    // Where windows start: below the bar plus Hyprland's gaps_out
    readonly property real windowTop: Theme.barBottom + 24

    color: Theme.bg
    border.width: 2
    border.color: Theme.line
    clip: true

    // Grid like the wallpaper
    Canvas {
        id: grid
        anchors.fill: parent
        onWidthChanged: requestPaint()

        Connections {
            target: Theme

            function onPChanged() {
                grid.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = String(Theme.grid);
            ctx.lineWidth = 1;
            ctx.beginPath();
            for (let x = 0.5; x < width; x += 48 * root.s) {
                ctx.moveTo(x, 0);
                ctx.lineTo(x, height);
            }
            for (let y = 0.5; y < height; y += 48 * root.s) {
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
            }
            ctx.stroke();
        }
    }

    // Bar
    Rectangle {
        x: 24 * root.s
        y: Theme.barTop * root.s
        width: (root.screenW - 48) * root.s
        height: Theme.barHeight * root.s
        color: "transparent"
        border.width: 1
        border.color: Theme.border

        Rectangle {
            width: 140 * Theme.barScale * root.s
            height: parent.height
            color: Theme.frame
        }

        Caps {
            anchors.centerIn: parent
            text: "BAR"
            color: Theme.muted
            font.pixelSize: 10
        }
    }

    // Where tiled windows go
    Rectangle {
        x: 24 * root.s
        y: root.windowTop * root.s
        width: (Desktop.column ? 1092 : root.screenW - 48) * root.s
        height: (root.screenH - root.windowTop - 24) * root.s
        color: "transparent"
        border.width: 1
        border.color: Theme.faint

        Caps {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 8
            text: "WINDOWS"
            color: Theme.muted
            font.pixelSize: 10
        }
    }

    // The column Hyprland keeps free next to the windows
    Item {
        visible: Desktop.column
        x: (root.screenW - 780) * root.s
        y: root.windowTop * root.s
        width: 756 * root.s
        height: (root.screenH - root.windowTop - 24) * root.s

        Hatch {
            anchors.fill: parent
            color: Theme.line
            step: 12
            lineWidth: 1
        }

        Caps {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 8
            text: "FREE COLUMN"
            color: Theme.muted
            font.pixelSize: 10
        }
    }

    Repeater {
        model: ["pda", "music", "tasks"]

        Rectangle {
            id: box

            required property string modelData
            readonly property var cfg: Desktop.widget(modelData)
            readonly property size real: Desktop.sizes[modelData]
            readonly property bool dragging: mouse.drag.active

            x: cfg.x * root.s
            y: cfg.y * root.s
            z: dragging ? 10 : 1
            width: real.width * root.s
            height: real.height * root.s
            color: cfg.visible ? Theme.surface2 : "transparent"
            border.width: 2
            border.color: dragging || mouse.containsMouse ? Theme.fg : cfg.visible ? Theme.frame : Theme.faint
            Accessible.role: Accessible.Grip
            Accessible.name: Desktop.names[modelData] + ", drag to move"

            Caps {
                anchors.centerIn: parent
                text: Desktop.names[box.modelData] + (box.cfg.visible ? "" : " · HIDDEN")
                color: box.cfg.visible ? Theme.frame : Theme.muted
            }

            // The real position, snapped to 8 px
            function commit() {
                const snap = v => Math.round(v / root.s / 8) * 8;
                Desktop.update(modelData, { x: snap(x), y: snap(y) });
            }

            MouseArea {
                id: mouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: box
                drag.threshold: 2
                drag.minimumX: 0
                drag.maximumX: root.width - box.width
                drag.minimumY: 0
                drag.maximumY: root.height - box.height
                onPositionChanged: if (drag.active) box.commit()
                onReleased: {
                    box.commit();
                    // Dragging replaced the bindings; follow the layout again
                    box.x = Qt.binding(() => box.cfg.x * root.s);
                    box.y = Qt.binding(() => box.cfg.y * root.s);
                }
            }
        }
    }
}
