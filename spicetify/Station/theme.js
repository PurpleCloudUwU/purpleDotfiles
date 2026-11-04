// Station: Spotify's icons redrawn like the shell's (quickshell/widgets/Icon.qml).
//
// Every icon is path data on a 24x24 grid: stroked with flat caps and mitred
// corners, or filled (the transport arrows, play/pause and a few badges).
// Spotify draws its icons as <svg viewBox="0 0 16 16|24 24"><path d="…">;
// this finds them by the start of the first path's data and swaps the shape
// through the CSS `d` property, so React can keep changing the attribute
// (play <-> pause) and the right icon still shows. Icons that are not in the
// table stay Spotify's own.
(function station() {
    // Same names and shapes as Icon.qml where they exist there
    const S = {
        // From the shell
        bell: "M6 17v-6a6 6 0 0 1 12 0v6l2 2H4Z M10 21h4",
        info: "M3 3h18v18H3Z M12 10v7 M12 6v2",
        sliders: "M4 6h16 M4 12h16 M4 18h16 M8 3v6 M15 9v6 M10 15v6",
        volume: "M3 9h4l5-5v16l-5-5H3Z M16 9a4 4 0 0 1 0 6 M19 6a8 8 0 0 1 0 12",
        plus: "M12 5v14 M5 12h14",
        close: "M4 4l16 16 M20 4L4 20",
        shuffle: "M3 7h4l10 10h4 M3 17h4l3-3 M14 10l3-3h4 M18 4l3 3-3 3 M18 14l3 3-3 3",
        music: "M9 18V6l10-2v12 M5 18a2 2 0 1 0 4 0a2 2 0 1 0 -4 0 M15 16a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
        pencil: "M4 20l4-1 11-11-3-3L5 16Z",
        bars: "M5 20V12 M10 20V5 M15 20v-9 M20 20v-5",
        layout: "M3 4h18v16H3Z M14 4v16 M14 10h7 M14 15h7",
        // New ones in the same style
        back: "M15 4l-8 8 8 8",
        forward: "M9 4l8 8-8 8",
        home: "M3 11L12 3l9 8 M5 9v12h14V9 M10 21v-6h4v6",
        search: "M3 10a7 7 0 1 0 14 0a7 7 0 1 0 -14 0 M15 15l6 6",
        browse: "M3 4h18v5H3Z M5 9v11h14V9 M9 13h6",
        friends: "M3 20v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2 M5 7a4 4 0 1 0 8 0a4 4 0 1 0 -8 0 M16 3a4 4 0 0 1 0 8 M18 14a4 4 0 0 1 3 4v2",
        library: "M4 3v18 M9 3v18 M13 4l6 17",
        panelOpen: "M3 4h18v16H3Z M9 4v16 M13 9l3 3-3 3",
        panelClose: "M3 4h18v16H3Z M15 4v16 M10 9l-3 3 3 3",
        pin: "M8 3h8 M10 3v6l-4 5h12l-4-5V3 M12 14v7",
        add: "M3 3h18v18H3Z M12 7v10 M7 12h10",
        repeat: "M3 11V6h15 M15 3l3 3-3 3 M21 13v5H6 M9 21l-3-3 3-3",
        repeatOne: "M3 11V6h15 M15 3l3 3-3 3 M21 13v5H6 M9 21l-3-3 3-3 M12 9v6",
        mic: "M9 3h6v10H9Z M5 11a7 7 0 0 0 14 0 M12 18v3 M8 21h8",
        queue: "M3 5h18 M3 10h18 M3 15h10 M3 20h10 M16 14l5 3.5-5 3.5Z",
        device: "M5 4h14v11H5Z M2 19h20",
        miniplayer: "M3 4h18v16H3Z M12 12h6v5h-6Z",
        fullscreen: "M3 9V3h6 M15 3h6v6 M21 15v6h-6 M9 21H3v-6",
        expand: "M14 3h7v7 M21 3l-7 7 M10 21H3v-7 M3 21l7-7",
        share: "M12 3v12 M7 8l5-5 5 5 M4 12v9h16v-9",
        mute: "M3 9h4l5-5v16l-5-5H3Z M15 9l6 6 M21 9l-6 6",
        download: "M12 3v12 M7 10l5 5 5-5 M4 20h16",
        list: "M3 5h2 M8 5h13 M3 12h2 M8 12h13 M3 19h2 M8 19h13",
        invite: "M3 20v-2a5 5 0 0 1 5-5h2a5 5 0 0 1 5 5v2 M5 7a4 4 0 1 0 8 0a4 4 0 1 0 -8 0 M19 4v6 M16 7h6",
        user: "M4 21v-3a5 5 0 0 1 5-5h6a5 5 0 0 1 5 5v3 M8 7a4 4 0 1 0 8 0a4 4 0 1 0 -8 0",
        cycle: "M4 12a8 8 0 0 1 14-5.3 M20 12a8 8 0 0 1-14 5.3 M18 3v4h-4 M6 21v-4h4",
        external: "M14 3h7v7 M21 3l-9 9 M18 14v7H3V6h7",
        gear: "M10 2h4v3l2 1 2-2 3 3-2 2 1 2h3v4h-3l-1 2 2 2-3 3-2-2-2 1v3h-4v-3l-2-1-2 2-3-3 2-2-1-2H2v-4h3l1-2-2-2 3-3 2 2 2-1Z M9 12a3 3 0 1 0 6 0a3 3 0 1 0 -6 0",
        wave: "M4 9v6 M8 5v14 M12 8v8 M16 3v18 M20 9v6",
        panelCollapse: "M3 4h18v16H3Z M9 4v16 M16 9l-3 3 3 3",
        bellDot: "M6 17v-6a6 6 0 0 1 8.5-5.5 M18 11v6l2 2H4l2-2 M10 21h4 M17 2h4v4h-4Z",
        disc: "M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0 M10 12a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
        canvas: "M3 4h18v16H3Z M10 9l5 3-5 3Z",
        shrink: "M21 3l-7 7 M14 4v6h6 M3 21l7-7 M10 20v-6H4",
        queueAdd: "M3 10h18 M3 15h18 M3 20h18 M17 2v6 M14 5h6",
        timer: "M4 13a8 8 0 1 0 16 0a8 8 0 1 0 -16 0 M12 9v4h3 M9 2h6",
        radio: "M8 8a6 6 0 0 0 0 8 M16 8a6 6 0 0 1 0 8 M5 5a10 10 0 0 0 0 14 M19 5a10 10 0 0 1 0 14 M10 12a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
        credits: "M3 5h10 M3 10h10 M3 15h6 M19 3v13 M15 16a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
    };
    // Filled shapes (evenodd, so inner shapes cut holes)
    const F = {
        play: "M6 4l14 8-14 8Z",
        pause: "M5 4h5v16H5Z M14 4h5v16h-5Z",
        prev: "M5 4h3v16H5Z M20 4L9 12l11 8Z",
        next: "M16 4h3v16h-3Z M4 4l11 8-11 8Z",
        down: "M3 8h18l-9 10Z",
        up: "M3 16h18L12 6Z",
        more: "M3 10h4v4H3Z M10 10h4v4h-4Z M17 10h4v4h-4Z",
        homeOn: "M12 2L2 11h3v10h5v-6h4v6h5V11h3Z",
        browseOn: "M3 3h18v6H3Z M5 10h14v11H5Z M9 13v2h6v-2Z",
        saved: "M2 2h20v20H2Z M10 18l-6-6 2-2 4 4 8-8 2 2Z",
        badge: "M2 2h20v20H2Z M12 5l1.6 5.4L19 12l-5.4 1.6L12 19l-1.6-5.4L5 12l5.4-1.6Z",
        bookmark: "M5 2h14v20l-7-5-7 5Z",
    };

    // Start of Spotify's path data -> icon. The viewBox decides the scale.
    const MAP = [
        ["M15.957 2.793a1 1 0 0 1 0 1.414L8.164 12", "back"],
        ["M8.043 2.793a1 1 0 0 0 0 1.414L15.836 12", "forward"],
        ["M11.03.47a.75.75 0 0 1 0 1.06L4.56 8l6.4", "back"],
        ["M4.97.47a.75.75 0 0 0 0 1.06L11.44 8l-6.", "forward"],
        ["M13.5 1.515a3 3 0 0 0-3 0L3 5.845a2 2 0 ", "homeOn"],
        ["M12.5 3.247a1 1 0 0 0-1 0L4 7.577V20h4.5", "home"],
        ["M10.533 1.27893C5.35215 1.27893 1.12598 ", "search"],
        ["M7 1.75a5.25 5.25 0 1 0 0 10.5 5.25 5.25", "search"],
        ["M3.293 3.293a1 1 0 0 1 1.414 0L12 10.586", "close"],
        ["M2.47 2.47a.75.75 0 0 1 1.06 0L8 6.94l4.", "close"],
        ["M15 15.5c0 1.105-1.343 2-3 2s-3-.895-3-2", "browse"],
        ["M4 2a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v4H4z", "browseOn"],
        ["M8 1.5a4 4 0 0 0-4 4v3.27a.75.75 0 0 1-.", "bell"],
        ["M3.849 10.034c-.021-.465.026-.93.139-1.3", "friends"],
        ["M14.5 2.134a1 1 0 0 1 1 0l6 3.464a1 1 0 ", "library"],
        ["M14.457 15.207a1 1 0 0 1-1.414-1.414L14.", "panelOpen"],
        ["M5.03 10.53a.75.75 0 1 1-1.06-1.06L5.44 ", "panelOpen"],
        ["M15.25 8a.75.75 0 0 1-.75.75H8.75v5.75a.", "plus"],
        ["M8.822.797a2.72 2.72 0 0 1 3.847 0l2.534", "pin"],
        ["M15 4v12.167a3.5 3.5 0 1 1-3.5-3.5H13V4z", "music"],
        ["M8 1.5a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 ", "add"],
        ["M11.999 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18m", "add"],
        ["M0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8m11.748", "saved"],
        ["M13.151.922a.75.75 0 1 0-1.06 1.06L13.10", "shuffle"],
        ["M18.788 3.702a1 1 0 0 1 1.414-1.414L23.9", "shuffle"],
        ["M3.3 1a.7.7 0 0 1 .7.7v5.15l9.95-5.744a.", "prev"],
        ["M12.7 1a.7.7 0 0 0-.7.7v5.15L2.05 1.107A", "next"],
        ["M2.7 1a.7.7 0 0 0-.7.7v12.6a.7.7 0 0 0 .", "pause"],
        ["M5.7 3a.7.7 0 0 0-.7.7v16.6a.7.7 0 0 0 .", "pause"],
        ["M3 1.713a.7.7 0 0 1 1.05-.607l10.89 6.28", "play"],
        ["m7.05 3.606 13.49 7.788a.7.7 0 0 1 0 1.2", "play"],
        ["M0 4.75A3.75 3.75 0 0 1 3.75 1h8.5A3.75 ", "repeat"],
        ["M0 4.75A3.75 3.75 0 0 1 3.75 1h.75v1.5h-", "repeatOne"],
        ["M13.426 2.574a2.831 2.831 0 0 0-4.797 1.", "mic"],
        ["M15 15H1v-1.5h14zm0-4.5H1V9h14zm-14-7A2.", "queue"],
        ["M2 3.75C2 2.784 2.784 2 3.75 2h8.5c.966 ", "device"],
        ["M9.741.85a.75.75 0 0 1 .375.65v13a.75.75", "volume"],
        ["M13.86 5.47a.75.75 0 0 0-1.061 0l-1.47 1", "mute"],
        ["M14.5 8a6.47 6.47 0 0 0-1.3-3.9l1.2-.9C1", "volume"],
        ["M16 2.45c0-.8-.65-1.45-1.45-1.45H1.45C.6", "miniplayer"],
        ["M0.25 3C0.25 2.0335 1.0335 1.25 2 1.25H5", "fullscreen"],
        ["M6.53 9.47a.75.75 0 0 1 0 1.06l-2.72 2.7", "expand"],
        ["M3 8a1 1 0 0 1 1-1h3.5v2H5v11h14V9h-2.5V", "share"],
        ["M4.5 13.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 ", "more"],
        ["M3 8a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0", "more"],
        ["M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18M1 12", "download"],
        ["M15 14.5H5V13h10zm0-5.75H5v-1.5h10zM15 3", "list"],
        ["m14 6-6 6-6-6z", "down"],
        ["M10.814.5a1.66 1.66 0 0 1 2.372 0l2.512 ", "saved"],
        ["M7.155.406a1.18 1.18 0 0 1 1.69 0L10.46 ", "saved"],
        ["M17.318 1.975a3.329 3.329 0 1 1 4.707 4.", "pencil"],
        ["M11.838.714a2.438 2.438 0 0 1 3.448 3.44", "pencil"],
        ["M4.99 3h2.993v2H4.99v3H2.994V5H0V3h2.994", "invite"],
        ["M1.25 9a.5.5 0 0 1 .5-.5H3.5V.75a.75.75 ", "sliders"],
        ["M1 0a1 1 0 0 0-1 1v14a1 1 0 0 0 1 1h14a1", "badge"],
        ["M7 1a3 3 0 0 0-3 3v17.167c0 1.448 1.657 ", "bookmark"],
        ["m23.2 11.362-1.628-.605a.92.92 0 0 1-.52", "gear"],
        ["M13.363 10.4742L12.842 11.0992C12.6086 1", "user"],
        ["M12 0a1 1 0 0 1 1 1v22a1 1 0 1 1-2 0V1a1", "wave"],
        ["M9.096.794a.75.75 0 0 1 .914-.538 8.01 8", "cycle"],
        ["M1 2.75A.75.75 0 0 1 1.75 2H7v1.5H2.5v11", "external"],
        ["M8 14.5a6.5 6.5 0 1 1 0-13 6.5 6.5 0 0 1", "info"],
        ["M14 10 8 4l-6 6z", "up"],
        ["M10.97 5.47a.75.75 0 1 1 1.06 1.06L10.56", "panelCollapse"],
        ["M13.5 5.71v2.857l2.193 3.809a.75.75 0 0 ", "bellDot"],
        ["M9.5 8a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3", "disc"],
        ["M11.196 8 6 5v6z", "canvas"],
        ["M14.53 1.47a.75.75 0 0 1 0 1.06l-2.72 2.", "shrink"],
        ["M16 15H2v-1.5h14zm0-4.5H2V9h14zm-8.034-6", "queueAdd"],
        ["M5.2 0c-.387 0-.7.336-.7.75s.313.75.7.75", "timer"],
        ["M5.624 3.886A4.75 4.75 0 0 0 3.25 8c0 1.", "radio"],
        ["M11.757 2.987A4.36 4.36 0 0 0 7.618 0a4.", "user"],
        ["M16 8.328V1h-1.5v4.828h-1a2.5 2.5 0 1 0 ", "credits"],
        ["M1 5.75A.75.75 0 0 1 1.75 5H4v1.5H2.5v8h", "share"],
    ];

    const esc = (s) => s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
    let css = "";
    for (const [key, name] of MAP) {
        const filled = name in F;
        const d = filled ? F[name] : S[name];
        if (!d) continue;
        for (const vb of [16, 24]) {
            const path = `svg[viewBox="0 0 ${vb} ${vb}"] > path:first-of-type[d^="${esc(key)}"]`;
            // 24-grid shapes in a 16-unit box are scaled by 2/3; the stroke is
            // set so both come out about 2 px wide at their usual size
            const scale = vb === 16 ? "transform: scale(0.6667);" : "";
            const paint = filled
                ? "fill: currentColor !important; fill-rule: evenodd; stroke: none !important;"
                : `fill: none !important; stroke: currentColor !important; stroke-width: ${vb === 16 ? 3 : 2}; ` +
                  "stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 4;";
            css += `${path}{d:path("${d}");${scale}transform-origin:0 0;${paint}}\n`;
            // Spotify's extra paths of the same icon (rings, dots) go away
            css += `svg[viewBox="0 0 ${vb} ${vb}"]:has(> ${path.split(" > ")[1]}) > path:not(:first-of-type){display:none}\n`;
        }
    }

    const style = document.createElement("style");
    style.id = "station-icons";
    style.textContent = css;
    (document.head || document.documentElement).appendChild(style);

    // Live theme switch. `spicetify config color_scheme <name> && spicetify
    // apply` rewrites colors.css in Spotify's folder, and Spotify reads its
    // files from disk on every request; so the page looks at colors.css every two seconds and,
    // when it changed, loads it again. No restart of Spotify needed.
    let last = null;
    async function checkColors() {
        try {
            const res = await fetch("colors.css?" + Date.now(), { cache: "no-store" });
            if (!res.ok) return;
            const text = await res.text();
            if (last !== null && text !== last) {
                const link = document.querySelector('link.userCSS[href^="colors.css"]');
                if (link) {
                    // The new sheet first, then the old one goes, so nothing flashes
                    const next = link.cloneNode();
                    next.href = "colors.css?" + Date.now();
                    next.onload = () => link.remove();
                    link.after(next);
                }
            }
            last = text;
        } catch (e) {
            // Spotify offline or the file is being written; try again later
        }
    }
    checkColors();
    setInterval(checkColors, 2000);
})();
