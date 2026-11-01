import QtQuick
import QtQuick.Shapes
import qs.services

// Stroke icons from the canvas, drawn from SVG path data on a 24x24 grid.
// `filled` icons (the arrows) are filled instead of stroked.
Item {
    id: root

    property string name: "app"
    property color color: Theme.bg
    property real stroke: 2.4
    property int size: 30

    readonly property var paths: ({
        terminal: "M3 4H21V20H3Z M7 9l3 3-3 3 M12 15h5",
        globe: "M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0 M8 12a4 9 0 1 0 8 0a4 9 0 1 0 -8 0 M3 12h18",
        folder: "M3 6h6l2 2h10v11H3Z",
        pencil: "M4 20l4-1 11-11-3-3L5 16Z",
        music: "M9 18V6l10-2v12 M5 18a2 2 0 1 0 4 0a2 2 0 1 0 -4 0 M15 16a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
        bars: "M5 20V12 M10 20V5 M15 20v-9 M20 20v-5",
        tube: "M3 4h18v13H3Z M8 21h8 M12 17v4 M6 8h12 M6 11h12",
        wifi: "M12 12v9 M8 21h8 M8.5 6.5a5 5 0 0 0 0 7 M15.5 6.5a5 5 0 0 1 0 7 M5.5 3.5a9 9 0 0 0 0 13 M18.5 3.5a9 9 0 0 1 0 13",
        bell: "M6 17v-6a6 6 0 0 1 12 0v6l2 2H4Z M10 21h4",
        alert: "M12 3l10 18H2Z M12 10v5 M12 17v2",
        finger: "M5 11a7 7 0 0 1 14 0v3 M8 20a10 10 0 0 0 1-5v-4a3 3 0 0 1 6 0v2 M12 11v4a9 9 0 0 1-2 6 M15 16a12 12 0 0 1-1 5",
        info: "M3 3h18v18H3Z M12 10v7 M12 6v2",
        app: "M4 4h7v7H4Z M13 4h7v7h-7Z M4 13h7v7H4Z M13 13h7v7h-7Z",
        // Program select: one per kind of program
        code: "M8 7l-5 5 5 5 M16 7l5 5-5 5 M14 4l-4 16",
        sliders: "M4 6h16 M4 12h16 M4 18h16 M8 3v6 M15 9v6 M10 15v6",
        printer: "M7 9V3h10v6 M7 17H3V9h18v8h-4 M7 13h10v8H7Z",
        send: "M3 11L21 3l-8 18-2-8Z M11 13L21 3",
        volume: "M3 9h4l5-5v16l-5-5H3Z M16 9a4 4 0 0 1 0 6 M19 6a8 8 0 0 1 0 12",
        camera: "M3 7h4l2-3h6l2 3h4v13H3Z M8 13a4 4 0 1 0 8 0a4 4 0 1 0 -8 0",
        layout: "M3 4h18v16H3Z M14 4v16 M14 10h7 M14 15h7",
        plus: "M12 5v14 M5 12h14",
        close: "M4 4l16 16 M20 4L4 20",
        shuffle: "M3 7h4l10 10h4 M3 17h4l3-3 M14 10l3-3h4 M18 4l3 3-3 3 M18 14l3 3-3 3",
        left: "M16 3L6 12l10 9Z",
        right: "M8 3l10 9-10 9Z",
        down: "M3 8h18l-9 10Z",
        prev: "M5 4h3v16H5Z M20 4L9 12l11 8Z",
        next: "M16 4h3v16h-3Z M4 4l11 8-11 8Z",
        play: "M6 4l14 8-14 8Z",
        pause: "M5 4h5v16H5Z M14 4h5v16h-5Z",
        // Weather (WEATHER widget)
        sun: "M8 12a4 4 0 1 0 8 0a4 4 0 1 0 -8 0 M12 2v3 M12 19v3 M2 12h3 M19 12h3 M4.9 4.9L7 7 M17 17l2.1 2.1 M4.9 19.1L7 17 M17 7l2.1-2.1",
        moon: "M20 14A8 8 0 1 1 10 4a6 6 0 0 0 10 10Z",
        partly: "M6 3v2 M2 8h2 M3 5l1.4 1.4 M9.6 6.4L11 5 M4.2 10.5A3 3 0 0 1 9.8 7 M8 20h9a3.5 3.5 0 0 0 0-7a5 5 0 0 0-9.6 1.2A2.9 2.9 0 0 0 8 20Z",
        cloud: "M7 18h10a4 4 0 0 0 0-8a6 6 0 0 0-11.5 1.5A3.3 3.3 0 0 0 7 18Z",
        rain: "M7 14h10a4 4 0 0 0 0-8a6 6 0 0 0-11.5 1.5A3.3 3.3 0 0 0 7 14Z M8 17l-1 4 M12 17l-1 4 M16 17l-1 4",
        snow: "M7 13h10a4 4 0 0 0 0-8a6 6 0 0 0-11.5 1.5A3.3 3.3 0 0 0 7 13Z M7 16v5 M4.5 18.5h5 M17 16v5 M14.5 18.5h5",
        fog: "M3 6h18 M5 10h14 M3 14h18 M5 18h14",
        storm: "M7 14h10a4 4 0 0 0 0-8a6 6 0 0 0-11.5 1.5A3.3 3.3 0 0 0 7 14Z M13 14l-3 4h4l-3 4"
    })
    readonly property bool filled: ["left", "right", "down", "prev", "next", "play", "pause"].indexOf(name) >= 0

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.filled ? "transparent" : root.color
            strokeWidth: root.filled ? 0 : root.stroke
            fillColor: root.filled ? root.color : "transparent"
            capStyle: ShapePath.FlatCap
            joinStyle: ShapePath.MiterJoin

            PathSvg {
                path: root.paths[root.name] ?? root.paths.app
            }
        }
    }
}
