import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The desktop widgets (canvas board 01), below the windows. Where they sit
// and which are shown is set on the DESKTOP WIDGETS page of STATION SETUP
// (services/Desktop.qml). By default they fill the right column that
// Hyprland keeps free on workspace 1.
PanelWindow {
    id: win

    screen: Wm.primaryScreen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "station-desktop"

    // Only the shown cards take clicks, the rest goes to the desktop
    mask: Region {
        Region {
            x: music.x
            y: music.y
            width: music.visible ? music.width : 0
            height: music.visible ? music.height : 0
        }

        Region {
            x: tasks.x
            y: tasks.y
            width: tasks.visible ? tasks.width : 0
            height: tasks.visible ? tasks.height : 0
        }

        Region {
            x: pda.x
            y: pda.y
            width: pda.visible ? pda.width : 0
            height: pda.visible ? pda.height : 0
        }
    }

    // Keeps a card on screen, also on smaller screens than the layout's
    function place(pos, size, limit) {
        return Math.max(0, Math.min(pos, limit - size));
    }

    MusicCard {
        id: music
        visible: Desktop.music.visible
        width: 448
        height: 284
        x: win.place(Desktop.music.x, width, win.width)
        y: win.place(Desktop.music.y, height, win.height)
    }

    TasksCard {
        id: tasks
        visible: Desktop.tasks.visible
        width: 284
        x: win.place(Desktop.tasks.x, width, win.width)
        y: win.place(Desktop.tasks.y, height, win.height)
    }

    PdaCard {
        id: pda
        visible: Desktop.pda.visible
        width: 756
        height: 208
        x: win.place(Desktop.pda.x, width, win.width)
        y: win.place(Desktop.pda.y, height, win.height)
    }
}
