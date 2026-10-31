import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.widgets

// The station's star chart (canvas board 01): grid, orbit rings, crosshair.
// Green uses a dot grid like the calibration board. Drawn once, redrawn only
// when the theme or the screen size changes.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.bg
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "station-wallpaper"

    // Canvas coordinates are for 1920x1080 and scale with the screen
    readonly property real sx: width / 1920
    readonly property real sy: height / 1080
    readonly property bool dots: Theme.name === "green"

    Canvas {
        id: chart

        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: Theme

            function onPChanged() {
                chart.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            const w = width, h = height, sx = win.sx, sy = win.sy;
            ctx.reset();

            // Grid
            if (win.dots) {
                ctx.fillStyle = String(Theme.grid);
                for (let x = 16; x < w; x += 32)
                    for (let y = 16; y < h; y += 32)
                        ctx.fillRect(x - 1.5, y - 1.5, 3, 3);
            } else {
                ctx.strokeStyle = String(Theme.grid);
                ctx.lineWidth = 1;
                ctx.beginPath();
                for (let x = 0.5; x < w; x += 48) {
                    ctx.moveTo(x, 0);
                    ctx.lineTo(x, h);
                }
                for (let y = 0.5; y < h; y += 48) {
                    ctx.moveTo(0, y);
                    ctx.lineTo(w, y);
                }
                ctx.stroke();
            }

            // Orbit rings in the bottom right
            const cx = 1640 * sx, cy = 1240 * sy;
            ctx.lineWidth = 2;
            ctx.strokeStyle = String(Theme.border);
            ctx.beginPath();
            ctx.arc(cx, cy, 620 * sy, 0, Math.PI * 2);
            ctx.stroke();
            ctx.strokeStyle = String(Theme.line);
            for (let a = 0; a < Math.PI * 2; a += 14 / (560 * sy)) {
                ctx.beginPath();
                ctx.arc(cx, cy, 560 * sy, a, a + 4 / (560 * sy));
                ctx.stroke();
            }

            // Crosshair with the marker ring
            const tx = 1200 * sx, ty = 640 * sy;
            ctx.strokeStyle = String(Theme.fg);
            ctx.globalAlpha = 0.75;
            ctx.beginPath();
            ctx.moveTo(tx - 28, ty);
            ctx.lineTo(tx + 28, ty);
            ctx.moveTo(tx, ty - 28);
            ctx.lineTo(tx, ty + 28);
            ctx.stroke();
            ctx.globalAlpha = 1;
            ctx.strokeStyle = String(Theme.accent);
            ctx.beginPath();
            ctx.arc(tx, ty, 14, 0, Math.PI * 2);
            ctx.stroke();
        }
    }

    Caps {
        x: 1236 * win.sx
        y: 626 * win.sy - height
        text: "SECTOR 7 · OBSERVATORY"
        color: Theme.fg2
        font.pixelSize: 13
    }

    PText {
        x: 1236 * win.sx
        y: 640 * win.sy
        text: "0°41′N  23°26′E"
        font.pixelSize: 30
    }

    Caps {
        x: 1168 * win.sx
        y: 796 * win.sy
        text: "MARE TRANQUILLITATIS / MAP 03-B"
        color: Theme.faint
        font.letterSpacing: 2
    }

    Caps {
        visible: win.dots
        x: 40
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36
        text: "HYDROPONICS · LEVEL 3 · HUMIDITY 64 %"
        color: Theme.faint
        font.pixelSize: 13
        font.letterSpacing: 2
    }
}
