import QtQuick
import qs.services

// Diagonal hatching, as in the window headers and the half battery cell
Canvas {
    id: root

    property color color: Theme.bg
    property int step: 9
    property int lineWidth: 3

    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = String(root.color);
        ctx.lineWidth = root.lineWidth;
        ctx.beginPath();
        for (let x = -height; x < width + height; x += step) {
            ctx.moveTo(x, height);
            ctx.lineTo(x + height, 0);
        }
        ctx.stroke();
    }
}
