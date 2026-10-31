import QtQuick
import qs.services

// A row of cells, the first `value` of them lit. With `interactive`, a click
// or the mouse wheel reports the new number of lit cells.
Item {
    id: root

    property int count: 20
    property real value: 0
    property color on: Theme.frame
    property color offColor: Theme.off
    property int gap: 3
    property bool interactive: false
    signal picked(int cells)

    readonly property real cellWidth: (width - gap * (count - 1)) / count
    implicitHeight: 22

    Repeater {
        model: root.count

        Rectangle {
            required property int index
            x: index * (root.cellWidth + root.gap)
            width: root.cellWidth
            height: root.height
            color: index < Math.round(root.value) ? root.on : root.offColor
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        // Click or drag: every cell up to the pointer; left of the first cell: 0
        onPressed: mouse => root.pick(mouse.x)
        onPositionChanged: mouse => root.pick(mouse.x)
        onWheel: wheel => root.picked(Math.max(0, Math.min(root.count, Math.round(root.value) + (wheel.angleDelta.y > 0 ? 1 : -1))))
    }

    function pick(x) {
        const cells = x < 0 ? 0 : Math.min(count, Math.ceil(x / (cellWidth + gap)));
        if (cells !== Math.round(value))
            picked(cells);
    }
}
