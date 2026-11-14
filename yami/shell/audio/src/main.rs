// yami-audio: audio device settings in the pixel style of the yami shell.
// Bluetooth: codec (A2DP profile), bitrate (LDAC quality, AAC mode), BT sample rate.
// USB and other ALSA outputs: bit depth, sample rate, channels, as the hardware allows.
// Settings live in ~/.config/yami-audio.json and become a WirePlumber fragment.
//
//   yami-audio                 the window
//   yami-audio list            devices, limits and live state in the terminal
//   yami-audio apply           write the fragment from yami-audio.json and restart WirePlumber
//   yami-audio shot [-o DIR]   PNG renders of the window, without Wayland

mod app;
mod panel;
mod pw;

pub use yami_px::{font, gfx, icons, look, paths, theme, ui};

use std::path::PathBuf;

/// UI strings are English only; yami_px::ui wants a translate function
pub fn tr(s: &str) -> &str {
    s
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match args.first().map(|s| s.as_str()) {
        Some("--version") => println!("yami-audio {}", env!("CARGO_PKG_VERSION")),
        Some("-h") | Some("--help") => println!(
            "yami-audio [list | apply | shot [-o DIR]]\n\nkeys: ↑/↓ device · enter or ctrl+s apply · ctrl+z revert · r rescan · q quit\nsettings: {}\nwritten to: {}",
            pw::cfg_path().display(),
            pw::conf_path().display()
        ),
        Some("list") => std::process::exit(list()),
        Some("apply") => match pw::apply(&pw::Cfg::load()) {
            Ok(m) => println!("{m}"),
            Err(e) => {
                eprintln!("yami-audio: {e}");
                std::process::exit(1);
            }
        },
        Some("shot") => std::process::exit(shot(&args[1..])),
        Some(x) => {
            eprintln!("yami-audio: unknown command {x} (see --help)");
            std::process::exit(2);
        }
        None => std::process::exit(app::run(panel::A::new(look::Look::load()))),
    }
}

fn list() -> i32 {
    let devs = match pw::scan() {
        Ok(d) => d,
        Err(e) => {
            eprintln!("yami-audio: {e}");
            return 1;
        }
    };
    let cfg = pw::Cfg::load();
    for d in &devs {
        println!("{}{}  [{}]", d.desc, if d.default_sink { "  (default)" } else { "" }, d.name);
        match d.kind {
            pw::Kind::Alsa => {
                println!("  formats   {}", d.formats.iter().map(|f| format!("{f} ({})", pw::bits(f))).collect::<Vec<_>>().join(", "));
                println!("  rates     {}", d.rates.iter().map(|r| r.to_string()).collect::<Vec<_>>().join(", "));
                println!("  channels  {}", d.channels.iter().map(|r| r.to_string()).collect::<Vec<_>>().join(", "));
                match &d.live {
                    Some(l) => println!("  now       {} · {} ch · {} Hz", l.format, l.channels, l.rate),
                    None => println!("  now       idle"),
                }
            }
            pw::Kind::Bluez => {
                for p in &d.profiles {
                    println!("  {} {:>2} {:<28} {}", if d.profile == Some(p.index) { "*" } else { " " }, p.index, p.name, p.desc);
                }
                println!("  now       {} · {} Hz", pw::codec_label(&d.codec), d.sink_rate);
            }
        }
        if let Some(c) = cfg.devices.get(&d.name) {
            println!("  set       {}", serde_json::to_string(c).unwrap_or_default());
        }
    }
    0
}

/// offscreen renders: the real devices of this machine plus a sample Bluetooth headset
fn shot(args: &[String]) -> i32 {
    let mut out = PathBuf::from("shots");
    let mut it = args.iter();
    while let Some(a) = it.next() {
        if a == "-o" {
            out = it.next().map(PathBuf::from).unwrap_or(out);
        }
    }
    let mut look = look::Look::load();
    look.animations = false;
    let _ = std::fs::create_dir_all(&out);
    let mut fonts = font::Fonts::with(look.font("view"));
    let mut ic = icons::Icons::new("");
    let mut devs = pw::scan().unwrap_or_default();
    let bt = pw::Dev {
        id: 900,
        name: "bluez_card.00_11_22_33_44_55".into(),
        desc: "Sample Headphones".into(),
        kind: pw::Kind::Bluez,
        bus: "bluetooth".into(),
        vendor: String::new(),
        product: String::new(),
        card: None,
        sinks: vec!["bluez_output.00_11_22_33_44_55.1".into()],
        default_sink: false,
        formats: vec![],
        rates: vec![],
        channels: vec![],
        live: None,
        profiles: ["sbc", "sbc_xq", "aac", "aptx", "aptx_hd", "ldac"]
            .iter()
            .enumerate()
            .map(|(i, c)| pw::Prof { index: i as u32 + 1, name: format!("a2dp-sink-{c}"), desc: format!("High Fidelity Playback (A2DP Sink, codec {})", pw::codec_label(c)), available: true })
            .chain([pw::Prof { index: 7, name: "headset-head-unit-msbc".into(), desc: "Headset Head Unit (HSP/HFP, codec mSBC)".into(), available: true }])
            .collect(),
        profile: Some(6),
        codec: "ldac".into(),
        sink_rate: 96000,
        sink_format: "S32LE".into(),
    };
    devs.push(bt.clone());
    let mut targets: Vec<(String, String, pw::DevCfg)> = devs.iter().filter(|d| d.kind == pw::Kind::Alsa).map(|d| (format!("alsa-{}", d.card.unwrap_or(0)), d.name.clone(), pw::DevCfg::default())).collect();
    if let Some(usb) = devs.iter().find(|d| d.kind == pw::Kind::Alsa && d.bus == "usb") {
        targets.push(("usb-set".into(), usb.name.clone(), pw::DevCfg { format: usb.formats.last().cloned(), rate: usb.rates.last().copied(), channels: usb.channels.last().copied(), ..Default::default() }));
    }
    targets.push(("bt".into(), bt.name.clone(), pw::DevCfg { ldac: Some("hq".into()), ..Default::default() }));
    for (file, sel, dc) in targets {
        let mut a = panel::A::new(look.clone());
        a.fx.clear();
        a.on_scan(Ok(devs.clone()));
        a.sel = sel.clone();
        a.cfg = pw::Cfg::default();
        a.edit = pw::Cfg::default();
        if !dc.is_empty() {
            a.edit.devices.insert(sel, dc);
        }
        a.born = std::time::Instant::now() - std::time::Duration::from_secs(5);
        let (w, h) = (a.w, a.h);
        let mut buf = vec![0u32; (w * h) as usize];
        {
            let mut ui = panel::Ui { cv: gfx::Canvas::new(&mut buf, w, h), f: &mut fonts, ic: &mut ic, t: look.theme, zones: vec![], ptr: None, down: false, anim: false, blink: true, tr };
            panel::draw(&mut ui, &a, w, h);
        }
        // premultiplied ARGB over the theme background, like a compositor without blur
        let bg = look.theme.bg.0;
        let mut rgba = Vec::with_capacity(buf.len() * 4);
        for px in &buf {
            let al = (px >> 24) & 0xff;
            let mix = |sh: u32| (((px >> sh) & 0xff) + ((bg >> sh) & 0xff) * (255 - al) / 255).min(255) as u8;
            rgba.extend_from_slice(&[mix(16), mix(8), mix(0), 255]);
        }
        let path = out.join(format!("{file}.png"));
        let _ = image::save_buffer(&path, &rgba, w as u32, h as u32, image::ColorType::Rgba8);
        println!("{}", path.display());
    }
    0
}
