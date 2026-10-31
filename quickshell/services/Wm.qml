pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Window manager state for the bar: workspaces, the focused window, the
// focused screen.
Singleton {
    id: root

    // Names shown on the active workspace button (1 TERM, 2 WEB, ...)
    readonly property var names: ({ "1": "TERM", "2": "WEB", "3": "SYS", "4": "CODE", "5": "MEDIA" })

    // Short names for the "WINDOW:" field
    readonly property var apps: ({
        "foot": "TERMINAL",
        "station.files": "FILES",
        "station.editor": "EDITOR",
        "station.monitor": "SYSTEM",
        "station.net": "NETWORK",
        "kew": "MUSIC",
        "spotify": "MUSIC",
        "Spotify": "MUSIC",
        "firefox": "BROWSER",
        "librewolf": "BROWSER",
        "brave-origin": "BROWSER",
        "chromium": "BROWSER"
    })

    readonly property var focusedScreen: {
        const name = Hyprland.focusedMonitor?.name;
        const list = Quickshell.screens;
        for (let i = 0; i < list.length; i++) {
            if (list[i].name === name)
                return list[i];
        }
        return list.length > 0 ? list[0] : null;
    }

    readonly property var active: ToplevelManager.activeToplevel
    readonly property bool emptyWorkspace: (Hyprland.focusedWorkspace?.toplevels.values.length ?? 0) === 0

    readonly property string title: {
        if (emptyWorkspace || !active)
            return "DESKTOP";
        const id = active.appId ?? "";
        // The shell's own windows (CRT CALIBRATION) are named by their title
        if (id === "org.quickshell")
            return (active.title ?? "SHELL").toUpperCase();
        const app = apps[id] ?? (id.split(".").pop() || "WINDOW").toUpperCase();
        // foot titles look like "~/dots" (see bash/station.bash)
        const t = (active.title ?? "").trim();
        return t && t.toUpperCase() !== app ? app + " — " + t : app;
    }

    // Workspaces 1-5 always, higher ones while they exist
    readonly property var workspaceIds: {
        const ids = [1, 2, 3, 4, 5];
        const all = Hyprland.workspaces.values;
        for (let i = 0; i < all.length; i++) {
            const id = all[i].id;
            if (id > 5 && ids.indexOf(id) < 0)
                ids.push(id);
        }
        return ids.sort((a, b) => a - b);
    }

    function workspace(id) {
        const all = Hyprland.workspaces.values;
        for (let i = 0; i < all.length; i++) {
            if (all[i].id === id)
                return all[i];
        }
        return null;
    }

    function focusWorkspace(id) {
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = ${id} })` : `workspace ${id}`);
    }
}
