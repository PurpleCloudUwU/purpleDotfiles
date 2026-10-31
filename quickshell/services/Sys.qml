pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// Battery, audio, CPU, temperature and brightness
Singleton {
    id: root

    // --- Battery (UPower's combined display device)
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: bat.ready && bat.energyCapacity > 0
    readonly property int batPct: {
        if (bat.energyCapacity > 0)
            return Math.round(bat.energy / bat.energyCapacity * 100);
        return Math.round(bat.percentage <= 1 ? bat.percentage * 100 : bat.percentage);
    }
    readonly property bool onBattery: UPower.onBattery
    readonly property bool charging: bat.state === UPowerDeviceState.Charging || bat.state === UPowerDeviceState.PendingCharge
    readonly property real watts: Math.abs(bat.changeRate)
    readonly property int minutesLeft: Math.round((onBattery ? bat.timeToEmpty : bat.timeToFull) / 60)
    readonly property string timeLeft: {
        if (!hasBattery)
            return "NO BATTERY";
        if (!onBattery && !charging)
            return "ON MAINS";
        if (minutesLeft <= 0)
            return "CALCULATING";
        return (charging ? "FULL IN " : "≈ ") + Math.floor(minutesLeft / 60) + " H " + (minutesLeft % 60) + " MIN";
    }
    readonly property string usage: !onBattery ? "MAINS" : watts < 7 ? "LOW" : watts < 12 ? "MEDIUM" : "HIGH"

    // --- Audio
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: sink?.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: sink?.audio?.muted ?? false

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    function setVolume(pct) {
        if (!sink?.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(100, pct)) / 100;
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    // --- CPU, temperature, brightness (scripts/sysinfo.sh prints a line
    // every 3 seconds: cpu_total cpu_idle temp_millideg brightness max)
    property int cpu: 0
    property int temp: 0
    property int brightness: 0
    property var last: null

    function parse(line) {
        const f = line.trim().split(/\s+/).map(Number);
        if (f.length < 5 || f.some(isNaN))
            return;
        if (last) {
            const total = f[0] - last[0];
            const idle = f[1] - last[1];
            if (total > 0)
                cpu = Math.round((1 - idle / total) * 100);
        }
        last = [f[0], f[1]];
        temp = Math.round(f[2] / 1000);
        if (f[4] > 0)
            brightness = Math.round(f[3] / f[4] * 100);
    }

    function setBrightness(pct) {
        const v = Math.max(1, Math.min(100, Math.round(pct)));
        brightness = v;
        Quickshell.execDetached(["station", "bright", String(v)]);
    }

    // --- Night light (hyprsunset runs while it is on)
    property bool nightLight: false

    Process {
        command: ["hyprsunset", "-t", "4500"]
        running: root.nightLight
    }

    Process {
        id: sysinfo
        command: ["sh", Quickshell.shellPath("scripts/sysinfo.sh")]
        running: true
        stdout: SplitParser {
            onRead: data => root.parse(data)
        }
        onRunningChanged: if (!running) restart.start()
    }

    Timer {
        id: restart
        interval: 5000
        onTriggered: sysinfo.running = true
    }
}
