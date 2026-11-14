// Audio backend: reads devices from PipeWire (`pw-dump`), hardware limits from ALSA
// (/proc/asound), and applies settings as a WirePlumber config fragment that this app owns.
//
// USB/ALSA outputs: `monitor.alsa.rules` on the device's output nodes set audio.format,
// audio.rate (+ allowed-rates, so the DAC really runs at that rate) and audio.channels.
// Bluetooth: the codec is the device profile (`a2dp-sink-<codec>`), switched live with
// `wpctl set-profile` and kept with `device.profile`; codec quality goes into
// `monitor.bluez.rules` (bluez5.a2dp.ldac.quality, bluez5.a2dp.aac.bitratemode), the BT
// sample rate into `monitor.bluez.properties` (bluez5.default.rate, it is global).
// Quality and rate changes need WirePlumber to recreate the devices: it is restarted.

use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::path::PathBuf;
use std::process::{Command, Stdio};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Kind {
    Alsa,
    Bluez,
}

#[derive(Clone, Debug, PartialEq)]
pub struct Prof {
    pub index: u32,
    pub name: String,
    pub desc: String,
    pub available: bool,
}

/// what the hardware is doing right now (ALSA hw_params of the playback substream)
#[derive(Clone, Debug, PartialEq, Default)]
pub struct Live {
    pub format: String,
    pub rate: u32,
    pub channels: u32,
}

#[derive(Clone, Debug, PartialEq)]
pub struct Dev {
    pub id: u32,
    /// device.name: the key for settings and rules (alsa_card.usb-…, bluez_card.XX_XX…)
    pub name: String,
    pub desc: String,
    pub kind: Kind,
    /// usb, pci, bluetooth…
    pub bus: String,
    pub vendor: String,
    pub product: String,
    /// ALSA card number
    pub card: Option<u32>,
    /// output nodes of this device (node.name)
    pub sinks: Vec<String>,
    pub default_sink: bool,
    /// ALSA: what the hardware accepts (SPA format names, ascending rates, channel counts)
    pub formats: Vec<String>,
    pub rates: Vec<u32>,
    pub channels: Vec<u32>,
    pub live: Option<Live>,
    /// Bluetooth: profiles and the active one; codec and rate of the running sink
    pub profiles: Vec<Prof>,
    pub profile: Option<u32>,
    pub codec: String,
    pub sink_rate: u32,
    pub sink_format: String,
}

impl Dev {
    pub fn cur_profile(&self) -> Option<&Prof> {
        self.profile.and_then(|i| self.profiles.iter().find(|p| p.index == i))
    }
}

/// per-device choices; None — leave it to PipeWire
#[derive(Clone, Debug, Default, PartialEq, Serialize, Deserialize)]
#[serde(default)]
pub struct DevCfg {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub format: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub rate: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub channels: Option<u32>,
    /// Bluetooth profile name (a2dp-sink-ldac…)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub profile: Option<String>,
    /// LDAC: auto, hq, sq, mq
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ldac: Option<String>,
    /// AAC: 0 CBR, 1…5 VBR
    #[serde(skip_serializing_if = "Option::is_none")]
    pub aac: Option<u8>,
}

impl DevCfg {
    pub fn is_empty(&self) -> bool {
        *self == DevCfg::default()
    }
}

#[derive(Clone, Debug, Default, PartialEq, Serialize, Deserialize)]
#[serde(default)]
pub struct Cfg {
    pub devices: BTreeMap<String, DevCfg>,
    /// Bluetooth sample rate for all BT devices (0 — PipeWire default)
    #[serde(rename = "btRate")]
    pub bt_rate: u32,
    /// remembered names of devices, so the list can show ones that are away
    #[serde(rename = "names")]
    pub names: BTreeMap<String, String>,
}

pub fn cfg_path() -> PathBuf {
    yami_px::paths::config_dir().join("yami-audio.json")
}
pub fn conf_path() -> PathBuf {
    yami_px::paths::config_dir().join("wireplumber/wireplumber.conf.d/90-yami-audio.conf")
}

impl Cfg {
    pub fn load() -> Cfg {
        std::fs::read_to_string(cfg_path()).map(|t| yami_px::paths::lenient_json(&t)).unwrap_or_default()
    }
    pub fn save(&self) -> std::io::Result<()> {
        let mut c = self.clone();
        c.devices.retain(|_, d| !d.is_empty());
        yami_px::paths::write_atomic(&cfg_path(), &(serde_json::to_string_pretty(&c).unwrap_or_default() + "\n"))
    }
}

// ── reading ──────────────────────────────────────────────────────────────

fn run(cmd: &str, args: &[&str]) -> Option<String> {
    let o = Command::new(cmd).args(args).stdin(Stdio::null()).stderr(Stdio::null()).output().ok()?;
    o.status.success().then(|| String::from_utf8_lossy(&o.stdout).to_string())
}

fn s(v: &serde_json::Value, k: &str) -> String {
    match v.get(k) {
        Some(serde_json::Value::String(x)) => x.clone(),
        Some(serde_json::Value::Number(n)) => n.to_string(),
        Some(serde_json::Value::Bool(b)) => b.to_string(),
        _ => String::new(),
    }
}
fn n(v: &serde_json::Value, k: &str) -> Option<u32> {
    match v.get(k) {
        Some(serde_json::Value::Number(x)) => x.as_u64().map(|x| x as u32),
        Some(serde_json::Value::String(x)) => x.trim().parse().ok(),
        _ => None,
    }
}

/// all audio devices PipeWire knows, sorted: USB, Bluetooth, then the rest
pub fn scan() -> Result<Vec<Dev>, String> {
    let text = run("pw-dump", &["--no-colors"]).ok_or("pw-dump failed: is PipeWire running?")?;
    parse_dump(&text, &default_sink())
}

fn default_sink() -> String {
    // the configured default sink lives in the "default" metadata
    run("pw-metadata", &["-n", "default", "0", "default.audio.sink"])
        .and_then(|t| t.lines().find(|l| l.contains("default.audio.sink")).map(|l| l.to_string()))
        .and_then(|l| l.split("\"name\":\"").nth(1).map(|x| x.split('"').next().unwrap_or("").to_string()))
        .unwrap_or_default()
}

pub fn parse_dump(text: &str, def_sink: &str) -> Result<Vec<Dev>, String> {
    let all: Vec<serde_json::Value> = serde_json::from_str(text).map_err(|e| format!("pw-dump: {e}"))?;
    let mut devs: Vec<Dev> = vec![];
    for o in &all {
        let Some(info) = o.get("info") else { continue };
        let p = &info["props"];
        if s(p, "media.class") != "Audio/Device" {
            continue;
        }
        let kind = match s(p, "device.api").as_str() {
            "alsa" => Kind::Alsa,
            "bluez5" => Kind::Bluez,
            _ => continue,
        };
        let params = &info["params"];
        let profiles: Vec<Prof> = params["EnumProfile"]
            .as_array()
            .map(|a| {
                a.iter()
                    .filter_map(|x| {
                        Some(Prof { index: x.get("index")?.as_u64()? as u32, name: s(x, "name"), desc: s(x, "description"), available: s(x, "available") != "no" })
                    })
                    .collect()
            })
            .unwrap_or_default();
        let profile = params["Profile"].as_array().and_then(|a| a.first()).and_then(|x| x.get("index")?.as_u64()).map(|x| x as u32);
        let id = o.get("id").and_then(|x| x.as_u64()).unwrap_or(0) as u32;
        let card = n(p, "api.alsa.card");
        let mut d = Dev {
            id,
            name: s(p, "device.name"),
            desc: { let d = s(p, "device.description"); if d.is_empty() { s(p, "device.nick") } else { d } },
            kind,
            bus: { let b = s(p, "device.bus"); if b.is_empty() && kind == Kind::Bluez { "bluetooth".into() } else { b } },
            vendor: s(p, "device.vendor.name"),
            product: s(p, "device.product.name"),
            card,
            sinks: vec![],
            default_sink: false,
            formats: vec![],
            rates: vec![],
            channels: vec![],
            live: None,
            profiles,
            profile,
            codec: String::new(),
            sink_rate: 0,
            sink_format: String::new(),
        };
        if let (Kind::Alsa, Some(c)) = (kind, card) {
            let (f, r, ch) = alsa_caps(c);
            d.formats = f;
            d.rates = r;
            d.channels = ch;
            d.live = alsa_live(c);
        }
        devs.push(d);
    }
    // output nodes belong to their device through device.id
    for o in &all {
        let Some(info) = o.get("info") else { continue };
        let p = &info["props"];
        if s(p, "media.class") != "Audio/Sink" {
            continue;
        }
        let Some(did) = n(p, "device.id") else { continue };
        if let Some(d) = devs.iter_mut().find(|d| d.id == did) {
            let nn = s(p, "node.name");
            if nn == def_sink {
                d.default_sink = true;
            }
            if d.kind == Kind::Bluez {
                d.codec = s(p, "api.bluez5.codec");
                d.sink_rate = n(p, "audio.rate").unwrap_or(0);
                d.sink_format = s(p, "audio.format");
                // without audio.rate in props: the negotiated format is in the Format param
                if let Some(f) = info["params"]["Format"].as_array().and_then(|a| a.first()) {
                    if d.sink_rate == 0 {
                        d.sink_rate = n(f, "rate").unwrap_or(0);
                    }
                    if d.sink_format.is_empty() {
                        d.sink_format = s(f, "format");
                    }
                }
            }
            d.sinks.push(nn);
        }
    }
    devs.sort_by_key(|d| (match (d.kind, d.bus.as_str()) {
        (Kind::Alsa, "usb") => 0,
        (Kind::Bluez, _) => 1,
        _ => 2,
    }, d.desc.to_lowercase()));
    Ok(devs)
}

/// ALSA format name → SPA (PipeWire) format name
pub fn spa_format(alsa: &str) -> Option<&'static str> {
    Some(match alsa {
        "S16_LE" => "S16LE",
        "S24_3LE" => "S24LE",
        "S24_LE" => "S24_32LE",
        "S32_LE" => "S32LE",
        "FLOAT_LE" => "F32LE",
        _ => return None,
    })
}

/// bit depth of a SPA format, for the buttons
pub fn bits(spa: &str) -> &'static str {
    match spa {
        "S16LE" => "16 bit",
        "S24LE" => "24 bit",
        "S24_32LE" => "24 in 32",
        "S32LE" => "32 bit",
        "F32LE" => "32 float",
        _ => "?",
    }
}

const FMT_ORDER: &[&str] = &["S16LE", "S24LE", "S24_32LE", "S32LE", "F32LE"];

/// playback formats, rates and channel counts the card accepts.
/// USB audio: /proc/asound/cardN/stream0; HDA: the codec's default PCM line.
pub fn alsa_caps(card: u32) -> (Vec<String>, Vec<u32>, Vec<u32>) {
    let base = PathBuf::from(format!("/proc/asound/card{card}"));
    let mut fmts: Vec<String> = vec![];
    let mut rates: Vec<u32> = vec![];
    let mut chans: Vec<u32> = vec![];
    if let Ok(t) = std::fs::read_to_string(base.join("stream0")) {
        let mut playback = false;
        for l in t.lines() {
            let l = l.trim();
            if l.starts_with("Playback:") {
                playback = true;
            } else if l.starts_with("Capture:") {
                playback = false;
            }
            if !playback {
                continue;
            }
            if let Some(f) = l.strip_prefix("Format:") {
                if let Some(x) = spa_format(f.trim()) {
                    fmts.push(x.into());
                }
            } else if let Some(c) = l.strip_prefix("Channels:") {
                if let Ok(c) = c.trim().parse() {
                    chans.push(c);
                }
            } else if let Some(r) = l.strip_prefix("Rates:") {
                // "8000, 16000, …" or a range "8000 - 192000 (continuous)"
                if r.contains('-') {
                    let lo_hi: Vec<u32> = r.split(|c: char| !c.is_ascii_digit()).filter_map(|x| x.parse().ok()).collect();
                    if let (Some(lo), Some(hi)) = (lo_hi.first(), lo_hi.get(1)) {
                        rates.extend(COMMON_RATES.iter().filter(|x| **x >= *lo && **x <= *hi));
                    }
                } else {
                    rates.extend(r.split(',').filter_map(|x| x.trim().parse::<u32>().ok()));
                }
            }
        }
    } else if let Some(t) = std::fs::read_dir(&base).ok().and_then(|rd| rd.flatten().find(|e| e.file_name().to_string_lossy().starts_with("codec#"))).and_then(|e| std::fs::read_to_string(e.path()).ok()) {
        // HDA: the first rates/bits lines are the codec's default PCM
        if let Some(l) = t.lines().find(|l| l.trim_start().starts_with("rates [")) {
            rates.extend(l.split(':').nth(1).unwrap_or("").split_whitespace().filter_map(|x| x.parse::<u32>().ok()));
        }
        if let Some(l) = t.lines().find(|l| l.trim_start().starts_with("bits [")) {
            let b: Vec<u32> = l.split(':').nth(1).unwrap_or("").split_whitespace().filter_map(|x| x.parse().ok()).collect();
            fmts.push("S16LE".into());
            if b.iter().any(|x| *x > 16) {
                fmts.push("S32LE".into());
            }
        }
        chans.push(2);
    }
    if fmts.is_empty() {
        fmts = vec!["S16LE".into(), "S24LE".into(), "S32LE".into()];
    }
    if rates.is_empty() {
        rates = vec![44100, 48000, 88200, 96000, 176400, 192000];
    }
    if chans.is_empty() {
        chans = vec![2];
    }
    fmts.sort_by_key(|f| FMT_ORDER.iter().position(|x| x == f).unwrap_or(99));
    fmts.dedup();
    rates.sort_unstable();
    rates.dedup();
    chans.sort_unstable();
    chans.dedup();
    (fmts, rates, chans)
}

const COMMON_RATES: &[u32] = &[8000, 11025, 16000, 22050, 32000, 44100, 48000, 88200, 96000, 176400, 192000, 352800, 384000, 705600, 768000];

/// the running playback substream, if any
pub fn alsa_live(card: u32) -> Option<Live> {
    let rd = std::fs::read_dir(format!("/proc/asound/card{card}")).ok()?;
    for e in rd.flatten() {
        let name = e.file_name().to_string_lossy().to_string();
        if !(name.starts_with("pcm") && name.ends_with('p')) {
            continue;
        }
        let Ok(t) = std::fs::read_to_string(e.path().join("sub0/hw_params")) else { continue };
        if t.trim() == "closed" {
            continue;
        }
        let mut l = Live::default();
        for line in t.lines() {
            if let Some((k, v)) = line.split_once(':') {
                match k.trim() {
                    "format" => l.format = v.trim().to_string(),
                    "channels" => l.channels = v.trim().parse().unwrap_or(0),
                    "rate" => l.rate = v.split_whitespace().next().and_then(|x| x.parse().ok()).unwrap_or(0),
                    _ => {}
                }
            }
        }
        return Some(l);
    }
    None
}

// ── Bluetooth codecs ─────────────────────────────────────────────────────

/// codec id from a profile name: a2dp-sink-ldac → ldac; plain a2dp-sink → "" (the device chose)
pub fn profile_codec(name: &str) -> Option<&str> {
    name.strip_prefix("a2dp-sink-").or_else(|| (name == "a2dp-sink").then_some(""))
}

/// the codec the device would use with this profile
pub fn codec_of(d: &Dev, cfg_profile: Option<&str>) -> String {
    match cfg_profile.or(d.cur_profile().map(|p| p.name.as_str())).and_then(profile_codec) {
        Some("") | None => d.codec.clone(),
        Some(c) => c.to_string(),
    }
}

pub fn codec_label(c: &str) -> String {
    match c {
        "sbc" => "SBC".into(),
        "sbc_xq" => "SBC-XQ".into(),
        "aac" => "AAC".into(),
        "aac_eld" => "AAC-ELD".into(),
        "aptx" => "aptX".into(),
        "aptx_hd" => "aptX HD".into(),
        "aptx_ll" => "aptX LL".into(),
        "aptx_ll_duplex" => "aptX LL duplex".into(),
        "ldac" => "LDAC".into(),
        "faststream" => "FastStream".into(),
        "faststream_duplex" => "FastStream duplex".into(),
        "lc3plus_h3" => "LC3plus".into(),
        "opus_05" => "Opus".into(),
        "opus_05_51" => "Opus 5.1".into(),
        "opus_05_71" => "Opus 7.1".into(),
        "opus_05_duplex" => "Opus duplex".into(),
        "opus_05_pro" => "Opus pro".into(),
        "opus_g" => "Opus (G)".into(),
        "lc3" => "LC3".into(),
        "" => "auto".into(),
        x => x.to_uppercase(),
    }
}

/// fixed bitrate of a codec, or the text describing its range
pub fn codec_bitrate(c: &str) -> &'static str {
    match c {
        "sbc" => "≈ 328 kbps",
        "sbc_xq" => "≈ 552 kbps",
        "aac" => "≤ 320 kbps",
        "aptx" => "352 kbps",
        "aptx_hd" => "576 kbps",
        "aptx_ll" | "aptx_ll_duplex" => "352 kbps",
        "ldac" => "330 – 990 kbps",
        "faststream" | "faststream_duplex" => "≈ 212 kbps",
        "lc3plus_h3" => "≤ 500 kbps",
        "opus_05" | "opus_05_pro" | "opus_05_duplex" | "opus_g" => "≤ 510 kbps",
        _ => "",
    }
}

pub const LDAC: &[(&str, &str)] = &[("auto", "auto · ABR"), ("hq", "990 kbps"), ("sq", "660 kbps"), ("mq", "330 kbps")];
pub const AAC: &[(u8, &str)] = &[(0, "CBR"), (1, "VBR 1"), (2, "VBR 2"), (3, "VBR 3"), (4, "VBR 4"), (5, "VBR 5")];
pub const BT_RATES: &[u32] = &[44100, 48000, 96000];

// ── writing ──────────────────────────────────────────────────────────────

/// regex that matches every output node of an ALSA card, whatever its profile
fn alsa_outputs(dev_name: &str) -> String {
    format!("~alsa_output.{}.*", regex_escape(dev_name.strip_prefix("alsa_card.").unwrap_or(dev_name)))
}

fn regex_escape(s: &str) -> String {
    let mut o = String::new();
    for c in s.chars() {
        if ".+*?()[]{}|^$\\".contains(c) {
            o.push('\\');
        }
        o.push(c);
    }
    o
}

fn q(s: &str) -> String {
    format!("\"{}\"", s.replace('\\', "\\\\").replace('"', "\\\""))
}

/// the WirePlumber fragment for these settings; None when nothing is set
pub fn render(cfg: &Cfg) -> Option<String> {
    let mut alsa = vec![];
    let mut bluez = vec![];
    for (name, d) in &cfg.devices {
        if name.starts_with("alsa_card.") {
            let mut props = vec![];
            if let Some(f) = &d.format {
                props.push(format!("audio.format = {}", q(f)));
            }
            if let Some(r) = d.rate {
                props.push(format!("audio.rate = {r}"));
                props.push(format!("audio.allowed-rates = [ {r} ]"));
            }
            if let Some(c) = d.channels {
                props.push(format!("audio.channels = {c}"));
            }
            if !props.is_empty() {
                alsa.push(format!("  {{\n    matches = [ {{ node.name = {} }} ]\n    actions = {{ update-props = {{ {} }} }}\n  }}", q(&alsa_outputs(name)), props.join(", ")));
            }
        } else if name.starts_with("bluez_card.") {
            let mut props = vec![];
            if let Some(p) = &d.profile {
                props.push(format!("device.profile = {}", q(p)));
            }
            if let Some(l) = &d.ldac {
                props.push(format!("bluez5.a2dp.ldac.quality = {}", q(l)));
            }
            if let Some(a) = d.aac {
                props.push(format!("bluez5.a2dp.aac.bitratemode = {a}"));
            }
            if !props.is_empty() {
                bluez.push(format!("  {{\n    matches = [ {{ device.name = {} }} ]\n    actions = {{ update-props = {{ {} }} }}\n  }}", q(name), props.join(", ")));
            }
        }
    }
    // SBC-XQ is off by default in PipeWire; switch it on so its profile can be picked
    let any_bt = cfg.devices.keys().any(|k| k.starts_with("bluez_card.")) || cfg.bt_rate != 0;
    if alsa.is_empty() && bluez.is_empty() && !any_bt {
        return None;
    }
    let mut out = String::from("# Written by yami-audio (~/.config/yami-audio.json). Edits here are overwritten.\n");
    if !alsa.is_empty() {
        out += &format!("\nmonitor.alsa.rules = [\n{}\n]\n", alsa.join("\n"));
    }
    if any_bt {
        out += "\nmonitor.bluez.properties = {\n  bluez5.enable-sbc-xq = true\n";
        if cfg.bt_rate != 0 {
            out += &format!("  bluez5.default.rate = {}\n", cfg.bt_rate);
        }
        out += "}\n";
    }
    if !bluez.is_empty() {
        out += &format!("\nmonitor.bluez.rules = [\n{}\n]\n", bluez.join("\n"));
    }
    Some(out)
}

/// write the fragment (or remove it); true when the file changed
pub fn write_conf(cfg: &Cfg) -> std::io::Result<bool> {
    let p = conf_path();
    let old = std::fs::read_to_string(&p).ok();
    match render(cfg) {
        Some(t) => {
            if old.as_deref() == Some(t.as_str()) {
                return Ok(false);
            }
            yami_px::paths::write_atomic(&p, &t)?;
            Ok(true)
        }
        None => {
            if old.is_none() {
                return Ok(false);
            }
            std::fs::remove_file(&p)?;
            Ok(true)
        }
    }
}

pub fn restart_wireplumber() -> Result<(), String> {
    let o = Command::new("systemctl").args(["--user", "restart", "wireplumber.service"]).stdin(Stdio::null()).output().map_err(|e| e.to_string())?;
    if o.status.success() {
        Ok(())
    } else {
        Err(String::from_utf8_lossy(&o.stderr).trim().to_string())
    }
}

pub fn set_profile(dev: u32, index: u32) -> Result<(), String> {
    let o = Command::new("wpctl").args(["set-profile", &dev.to_string(), &index.to_string()]).stdin(Stdio::null()).output().map_err(|e| e.to_string())?;
    if o.status.success() {
        Ok(())
    } else {
        Err(String::from_utf8_lossy(&o.stderr).trim().to_string())
    }
}

/// save, write the fragment, restart WirePlumber when it changed, then switch Bluetooth
/// profiles that differ from the wanted one. Returns a short report.
pub fn apply(cfg: &Cfg) -> Result<String, String> {
    cfg.save().map_err(|e| format!("yami-audio.json: {e}"))?;
    let changed = write_conf(cfg).map_err(|e| format!("{}: {e}", conf_path().display()))?;
    let mut devs = scan()?;
    if changed {
        restart_wireplumber()?;
        // wait until the devices are back (Bluetooth takes longest)
        let want: Vec<String> = devs.iter().map(|d| d.name.clone()).collect();
        let t0 = std::time::Instant::now();
        loop {
            std::thread::sleep(std::time::Duration::from_millis(300));
            if let Ok(now) = scan() {
                let back = want.iter().all(|w| now.iter().any(|d| &d.name == w && (d.kind == Kind::Alsa || !d.profiles.is_empty())));
                if back || t0.elapsed().as_secs() > 6 {
                    devs = now;
                    break;
                }
            }
        }
    }
    let mut switched = 0;
    for d in devs.iter().filter(|d| d.kind == Kind::Bluez) {
        let Some(want) = cfg.devices.get(&d.name).and_then(|c| c.profile.as_ref()) else { continue };
        let Some(p) = d.profiles.iter().find(|p| &p.name == want) else { continue };
        if d.profile != Some(p.index) {
            set_profile(d.id, p.index)?;
            switched += 1;
        }
    }
    Ok(match (changed, switched) {
        (true, _) => "applied · WirePlumber restarted".into(),
        (false, n) if n > 0 => "codec switched".into(),
        _ => "nothing to change".into(),
    })
}

/// human sample rate: 44100 → 44.1 kHz, 384000 → 384 kHz
pub fn khz(r: u32) -> String {
    if r % 1000 == 0 {
        format!("{} kHz", r / 1000)
    } else {
        let s = format!("{:.1}", r as f32 / 1000.0);
        format!("{} kHz", s.trim_end_matches(".0"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn renders_alsa_rule() {
        let mut c = Cfg::default();
        c.devices.insert("alsa_card.usb-Synaptics_AP6-00".into(), DevCfg { format: Some("S32LE".into()), rate: Some(384000), channels: Some(2), ..Default::default() });
        let t = render(&c).unwrap();
        assert!(t.contains(r#"node.name = "~alsa_output.usb-Synaptics_AP6-00.*""#), "{t}");
        assert!(t.contains("audio.rate = 384000"));
        assert!(t.contains("audio.allowed-rates = [ 384000 ]"));
        assert!(!t.contains("bluez"));
    }

    #[test]
    fn escapes_regex() {
        assert_eq!(alsa_outputs("alsa_card.pci-0000_00_1f.3"), "~alsa_output.pci-0000_00_1f\\.3.*");
        let mut c = Cfg::default();
        c.devices.insert("alsa_card.pci-0000_00_1f.3".into(), DevCfg { rate: Some(48000), ..Default::default() });
        // one backslash after SPA-JSON unquoting
        assert!(render(&c).unwrap().contains(r#""~alsa_output.pci-0000_00_1f\\.3.*""#));
    }

    #[test]
    fn renders_bt_rule() {
        let mut c = Cfg::default();
        c.devices.insert("bluez_card.00_02_3C_C0_04_09".into(), DevCfg { profile: Some("a2dp-sink-ldac".into()), ldac: Some("hq".into()), ..Default::default() });
        c.bt_rate = 48000;
        let t = render(&c).unwrap();
        assert!(t.contains(r#"device.profile = "a2dp-sink-ldac""#));
        assert!(t.contains(r#"bluez5.a2dp.ldac.quality = "hq""#));
        assert!(t.contains("bluez5.default.rate = 48000"));
    }

    #[test]
    fn empty_is_none() {
        assert!(render(&Cfg::default()).is_none());
    }

    #[test]
    fn khz_text() {
        assert_eq!(khz(44100), "44.1 kHz");
        assert_eq!(khz(384000), "384 kHz");
    }
}
