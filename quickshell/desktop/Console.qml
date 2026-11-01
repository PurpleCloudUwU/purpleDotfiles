import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The desktop widgets (canvas board 01), below the windows. Where they sit
// and which are shown is set on the DESKTOP WIDGETS page of STATION SETUP
// (services/Desktop.qml). By default they fill the right column that
// Hyprland keeps free next to the windows.
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
        Region { item: clock.visible ? clock : null }
        Region { item: calendar.visible ? calendar : null }
        Region { item: weather.visible ? weather : null }
        Region { item: system.visible ? system : null }
        Region { item: music.visible ? music : null }
        Region { item: tasks.visible ? tasks : null }
        Region { item: pda.visible ? pda : null }
    }

    // Keeps a card on screen, also on smaller screens than the layout's
    function place(pos, size, limit) {
        return Math.max(0, Math.min(pos, limit - size));
    }

    ClockCard {
        id: clock
        visible: Desktop.clock.visible
        width: Desktop.sizes.clock.width
        height: Desktop.sizes.clock.height
        x: win.place(Desktop.clock.x, width, win.width)
        y: win.place(Desktop.clock.y, height, win.height)
    }

    CalendarCard {
        id: calendar
        visible: Desktop.calendar.visible
        width: Desktop.sizes.calendar.width
        height: Desktop.sizes.calendar.height
        x: win.place(Desktop.calendar.x, width, win.width)
        y: win.place(Desktop.calendar.y, height, win.height)
    }

    WeatherCard {
        id: weather
        visible: Desktop.weather.visible
        width: Desktop.sizes.weather.width
        height: Desktop.sizes.weather.height
        x: win.place(Desktop.weather.x, width, win.width)
        y: win.place(Desktop.weather.y, height, win.height)
    }

    SystemCard {
        id: system
        visible: Desktop.system.visible
        width: Desktop.sizes.system.width
        height: Desktop.sizes.system.height
        x: win.place(Desktop.system.x, width, win.width)
        y: win.place(Desktop.system.y, height, win.height)
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
