pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Weather for the WEATHER widget from Open-Meteo (no account, no key).
// The place is set on the DESKTOP WIDGETS page of STATION SETUP: the name is
// looked up once with Open-Meteo's geocoding, the coordinates are kept in
// desktop.json. The last forecast is cached in
// ~/.local/state/station/weather.json, so the widget has something to show
// before the network is up.
Singleton {
    id: root

    readonly property var cfg: Desktop.weather
    readonly property bool wanted: cfg.visible
    readonly property string unit: cfg.fahrenheit ? "°F" : "°C"

    property var data: null
    property string error: ""
    property bool loading: false
    property bool searching: false
    property string searchError: ""

    readonly property var current: data?.current ?? null
    readonly property int code: current?.weather_code ?? -1
    readonly property bool day: (current?.is_day ?? 1) === 1
    readonly property int temp: Math.round(current?.temperature_2m ?? 0)
    readonly property int feels: Math.round(current?.apparent_temperature ?? 0)
    readonly property int humidity: Math.round(current?.relative_humidity_2m ?? 0)
    readonly property int wind: Math.round(current?.wind_speed_10m ?? 0)
    readonly property string windUnit: cfg.fahrenheit ? "MPH" : "KM/H"
    // When the forecast was made, "20:45"
    readonly property string updated: current?.time ? current.time.slice(11, 16) : "--:--"

    // The next days: { day: "SAT", code, max, min }
    readonly property var days: {
        const d = data?.daily;
        if (!d?.time)
            return [];
        const names = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        const out = [];
        for (let i = 1; i < d.time.length && out.length < 3; i++) {
            const date = new Date(d.time[i] + "T12:00:00");
            out.push({ day: names[date.getDay()], code: d.weather_code[i], max: Math.round(d.temperature_2m_max[i]), min: Math.round(d.temperature_2m_min[i]) });
        }
        return out;
    }

    // WMO weather codes into a word and an icon
    function describe(c) {
        if (c < 0)
            return "NO DATA";
        if (c === 0)
            return "CLEAR";
        if (c <= 2)
            return "PARTLY CLOUDY";
        if (c === 3)
            return "OVERCAST";
        if (c <= 48)
            return "FOG";
        if (c <= 57)
            return "DRIZZLE";
        if (c <= 67)
            return "RAIN";
        if (c <= 77)
            return "SNOW";
        if (c <= 82)
            return "SHOWERS";
        if (c <= 86)
            return "SNOW SHOWERS";
        return "THUNDERSTORM";
    }

    function icon(c, isDay) {
        if (c < 0)
            return "cloud";
        if (c === 0)
            return isDay === false ? "moon" : "sun";
        if (c <= 2)
            return "partly";
        if (c === 3)
            return "cloud";
        if (c <= 48)
            return "fog";
        if ((c >= 71 && c <= 77) || c === 85 || c === 86)
            return "snow";
        if (c >= 95)
            return "storm";
        return "rain";
    }

    function refresh() {
        if (fetch.running || cfg.lat === undefined)
            return;
        loading = true;
        const units = cfg.fahrenheit ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "";
        fetch.command = ["curl", "-sf", "-m", "15", "https://api.open-meteo.com/v1/forecast?latitude=" + cfg.lat + "&longitude=" + cfg.lon
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=4" + units];
        fetch.running = true;
    }

    // Looks the place up and keeps its coordinates; the forecast follows
    function setCity(name) {
        name = name.trim();
        if (name === "" || geo.running)
            return;
        searching = true;
        searchError = "";
        geo.command = ["curl", "-sf", "-m", "15", "-G", "https://geocoding-api.open-meteo.com/v1/search", "--data-urlencode", "name=" + name, "-d", "count=1", "-d", "language=en"];
        geo.running = true;
    }

    Process {
        id: fetch

        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    const d = JSON.parse(text);
                    if (!d.current)
                        throw "empty";
                    root.data = d;
                    root.error = "";
                    cache.setText(text);
                } catch (e) {
                    root.error = "NO SIGNAL";
                }
            }
        }
        onExited: code => {
            if (code !== 0) {
                root.loading = false;
                root.error = "NO SIGNAL";
            }
        }
    }

    Process {
        id: geo

        stdout: StdioCollector {
            onStreamFinished: {
                root.searching = false;
                try {
                    const r = JSON.parse(text).results?.[0];
                    if (!r)
                        throw "none";
                    Desktop.update("weather", { city: r.name, place: r.name.toUpperCase(), lat: r.latitude, lon: r.longitude, country: r.country_code ?? "" });
                } catch (e) {
                    root.searchError = "PLACE NOT FOUND";
                }
            }
        }
        onExited: code => {
            if (code !== 0) {
                root.searching = false;
                root.searchError = "NO SIGNAL";
            }
        }
    }

    // A new place or unit: fetch again right away
    onCfgChanged: {
        const key = cfg.lat + "," + cfg.lon + "," + cfg.fahrenheit;
        if (key !== lastKey) {
            lastKey = key;
            if (wanted)
                Qt.callLater(refresh);
        }
    }
    property string lastKey: ""

    // Every 20 minutes while the widget is shown; again soon after a failure
    Timer {
        interval: root.error !== "" ? 60 * 1000 : 20 * 60 * 1000
        repeat: true
        running: root.wanted
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // From scripts:
    //   qs ipc call weather city Hamburg
    //   qs ipc call weather refresh
    IpcHandler {
        target: "weather"

        function city(name: string): void {
            root.setCity(name);
        }

        function refresh(): void {
            root.refresh();
        }
    }

    FileView {
        id: cache
        path: Theme.stateDir + "/weather.json"
        printErrors: false
        onLoaded: {
            if (root.data)
                return;
            try {
                root.data = JSON.parse(text());
            } catch (e) {}
        }
    }
}
