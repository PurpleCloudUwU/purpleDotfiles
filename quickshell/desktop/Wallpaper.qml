import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

// The wallpaper: the star chart (StarChart.qml) on the background layer of
// every screen.
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

    // Everything in one item, so `qs ipc call wallpaper save` can write it
    // as a picture (the window colour itself is not part of a grab)
    StarChart {
        id: scene
        anchors.fill: parent
    }

    // From scripts, for the laptop panel:
    //   qs ipc call wallpaper save ~/Pictures/station-violet.png
    IpcHandler {
        target: "wallpaper"
        enabled: win.screen === Wm.primaryScreen

        function save(path: string): string {
            const file = path.replace(/^~/, Theme.home);
            const ok = scene.grabToImage(result => result.saveToFile(file));
            return ok ? "saved " + file : "failed";
        }
    }
}
