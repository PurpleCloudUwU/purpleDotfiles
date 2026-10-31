import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Desktop widgets in the right column (canvas board 01). They sit below the
// windows: on workspace 1 Hyprland keeps this column free (hypr/station/
// look.lua), the floating file manager takes its top, the widgets the rest.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        right: true
    }
    margins {
        top: 88
        bottom: 24
        right: 24
    }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 756
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "station-desktop"

    // Only the cards take clicks
    mask: Region {
        item: music

        Region { item: tasks }
        Region { item: pda }
    }

    MusicCard {
        id: music
        x: 0
        y: pda.y - 24 - height
        width: 448
        height: 284
    }

    TasksCard {
        id: tasks
        x: 472
        y: music.y
        width: 284
    }

    PdaCard {
        id: pda
        x: 0
        y: win.height - height
        width: 756
        height: 208
    }
}
