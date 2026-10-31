import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Widgets
import qs.services

// The preview tube of the calibration window. It imitates the effects of
// station/crt/crt.frag.in in QML, so settings can be tried before they go
// to the real screen.
Rectangle {
    id: root

    // 0-100, like in the station script
    property var values: ({})
    property color phosphor: Theme.fg

    readonly property real scan: (values.scan ?? 0) / 100
    readonly property real curve: (values.curve ?? 0) / 100
    readonly property real glow: (values.glow ?? 0) / 100
    readonly property real fringe: (values.fringe ?? 0) / 100
    readonly property real vig: (values.vig ?? 0) / 100
    readonly property real noise: (values.noise ?? 0) / 100
    readonly property real flick: (values.flick ?? 0) / 100
    property real dip: 0

    // The bezel; curvature rounds the corners of the glass
    color: Theme.surface2
    radius: 14 + curve * 70

    ClippingRectangle {
        id: tube

        anchors.fill: parent
        anchors.margins: 12
        radius: Math.max(2, root.radius - 10)
        color: Qt.darker(Theme.bg, 1.5)

        Item {
            id: picture

            anchors.fill: parent
            opacity: 1 - root.dip * root.flick * 0.3

            // Colour fringe: a red and a blue copy, pulled apart
            TestImage {
                width: picture.width
                height: picture.height
                visible: root.fringe > 0
                x: root.fringe * 5
                ink: "#ff3c3c"
                opacity: 0.55
            }

            TestImage {
                width: picture.width
                height: picture.height
                visible: root.fringe > 0
                x: -root.fringe * 5
                ink: "#3c8cff"
                opacity: 0.55
            }

            TestImage {
                id: main
                anchors.fill: parent
                ink: root.phosphor
            }

            // Glow: the picture with a soft halo in its own colour
            ShaderEffectSource {
                id: mainTexture
                anchors.fill: main
                sourceItem: main
                hideSource: root.glow > 0
                live: true
                visible: false
            }

            MultiEffect {
                anchors.fill: main
                visible: root.glow > 0
                source: mainTexture
                shadowEnabled: true
                shadowColor: root.phosphor
                shadowBlur: 0.3 + root.glow * 0.7
                shadowOpacity: root.glow
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                blurMax: 24
            }
        }

        // Scanlines
        Canvas {
            id: lines
            anchors.fill: parent
            opacity: root.scan
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = "rgba(0, 0, 0, 0.75)";
                for (let y = 0; y < height; y += 5)
                    ctx.fillRect(0, y, width, 2);
            }
        }

        // Grain, redrawn while the tube flickers
        Canvas {
            id: grain
            anchors.fill: parent
            opacity: root.noise
            visible: root.noise > 0
            onWidthChanged: requestPaint()
            onVisibleChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                for (let i = 0; i < 2600; i++) {
                    const v = Math.floor(Math.random() * 255);
                    ctx.fillStyle = "rgb(" + v + "," + v + "," + v + ")";
                    ctx.fillRect(Math.random() * width, Math.random() * height, 2, 2);
                }
            }

            Timer {
                interval: 120
                repeat: true
                running: grain.visible && root.flick > 0 && root.visible
                onTriggered: grain.requestPaint()
            }
        }

        // Vignette, stronger with curvature
        Shape {
            anchors.fill: parent
            opacity: Math.min(1, root.vig + root.curve / 2)
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: tube.width / 2
                    centerY: tube.height / 2
                    centerRadius: tube.width * 0.62
                    focalX: tube.width / 2
                    focalY: tube.height / 2

                    GradientStop { position: 0.5; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.92) }
                }

                startX: 0
                startY: 0
                PathLine { x: tube.width; y: 0 }
                PathLine { x: tube.width; y: tube.height }
                PathLine { x: 0; y: tube.height }
                PathLine { x: 0; y: 0 }
            }
        }
    }

    // Flicker: short dips in brightness
    SequentialAnimation on dip {
        running: root.flick > 0 && root.visible
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 60 }
        NumberAnimation { to: 0.3; duration: 90 }
        NumberAnimation { to: 0; duration: 80 }
        PauseAnimation { duration: 140 }
        onRunningChanged: if (!running) root.dip = 0
    }
}
