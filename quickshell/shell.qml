// Mondbasis · Quickshell
//
// Bar, program select, PDA panels, desktop widgets, notifications and OSD
// in one shell. Colours follow `station theme`, the CRT follows `station
// crt` (services/Station.qml). Quickshell reloads on save.
//
//   bar/       top bar
//   desktop/   wallpaper and the widgets in the right column
//   launcher/  STATION: PROGRAM SELECT (Super+D)
//   pda/       PDA quick access (Super+N) and the power menu (Super+Shift+E)
//   notify/    notifications
//   osd/       volume and brightness
//   services/  state: theme, CRT, battery, WiFi, tasks, player, ...
//   widgets/   pixel building blocks

import QtQuick
import Quickshell
import qs.bar
import qs.desktop
import qs.launcher
import qs.notify
import qs.osd
import qs.pda
import qs.services

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Wallpaper {}
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Console {}
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Bar {}
        }
    }

    Launcher {}
    QuickAccess {}
    PowerMenu {}
    Toasts {}
    Osd {}

    // Singletons start when first used. These work in the background (CRT
    // overrides, the notification daemon, the WiFi toast), so start them now.
    Component.onCompleted: [Station.preset, Notifs.dnd, Net.ssid, Panels.ready]
}
