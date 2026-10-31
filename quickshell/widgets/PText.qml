import QtQuick
import qs.services

// Text in the display font (Pocket or VT323)
Text {
    color: Theme.fg
    font.family: Theme.font
    font.pixelSize: 26
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
