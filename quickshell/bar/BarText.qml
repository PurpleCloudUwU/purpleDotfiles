import QtQuick
import qs.services
import qs.widgets

// Text in the bar's size (26 px on the canvas, times Theme.barScale)
PText {
    font.pixelSize: Math.round(26 * Theme.barScale)
}
