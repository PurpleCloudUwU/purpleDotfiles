pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// WiFi through NetworkManager (Quickshell.Networking)
Singleton {
    id: root

    readonly property var wifi: {
        const all = Networking.devices.values;
        for (let i = 0; i < all.length; i++) {
            if (all[i].type === DeviceType.Wifi)
                return all[i];
        }
        return null;
    }

    readonly property var networks: wifi ? Array.from(wifi.networks.values) : []
    readonly property var active: networks.find(n => n.connected) ?? null
    readonly property string ssid: active?.name ?? ""
    readonly property int signal: active ? Math.round(active.signalStrength * 100) : 0
    readonly property int bars: !active ? 0 : signal >= 75 ? 4 : signal >= 50 ? 3 : signal >= 25 ? 2 : 1
    readonly property bool enabled: Networking.wifiEnabled

    // Connected first, then by signal
    readonly property var sorted: networks.slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))

    // The PDA panel scans while it is open
    property bool scanning: false

    Binding {
        when: root.wifi !== null
        target: root.wifi
        property: "scannerEnabled"
        value: root.scanning
    }

    function needsPassword(net) {
        return !net.known && /psk|sae/i.test(WifiSecurityType.toString(net.security));
    }

    function barsFor(net) {
        const s = net.signalStrength * 100;
        return s >= 75 ? 4 : s >= 50 ? 3 : s >= 25 ? 2 : 1;
    }

    // "Access point found" toast (canvas board 02), not for the login itself
    property bool ready: false

    Timer {
        interval: 5000
        running: true
        onTriggered: root.ready = true
    }

    onSsidChanged: {
        if (ready && ssid !== "")
            Notifs.push({
                key: "wifi",
                title: "ACCESS POINT FOUND",
                body: "WIFI " + ssid.toUpperCase() + " · CONNECTED · SIGNAL " + signal + " %",
                icon: "wifi"
            });
    }
}
