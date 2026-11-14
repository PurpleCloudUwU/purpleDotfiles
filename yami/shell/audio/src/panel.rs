// State and drawing of the audio window. The window (app.rs) feeds input in and takes the
// effects out; scanning and applying run in a worker thread.
//
// Layout: top bar · device list on the left · settings of the selected device on the right
// (option chips per section) · bottom bar with the live state and apply / revert.

use crate::font::PX;
use crate::gfx::{BoxStyle, R};
use crate::pw::{self, Cfg, Dev, DevCfg, Kind};
use crate::ui::{Cur, Tone};
use std::time::Instant;

#[derive(Clone, Debug, PartialEq)]
pub enum Act {
    Block,
    Bg,
    Btn(&'static str),
    Dev(usize),
    Fmt(Option<String>),
    Rate(Option<u32>),
    Ch(Option<u32>),
    Prof(Option<String>),
    Ldac(Option<String>),
    Aac(Option<u8>),
    BtRate(u32),
}

impl yami_px::ui::Action for Act {
    fn block() -> Self {
        Act::Block
    }
}
pub type Ui<'a, 'b> = yami_px::ui::Ui<'a, 'b, Act>;

#[derive(Clone, Debug, PartialEq)]
pub enum Fx {
    Close,
    Scan,
    Apply(Cfg),
}

pub struct A {
    pub look: crate::look::Look,
    pub devs: Vec<Dev>,
    /// selected device by device.name, survives rescans
    pub sel: String,
    /// what is applied
    pub cfg: Cfg,
    /// what is being edited
    pub edit: Cfg,
    pub busy: bool,
    pub scanned: bool,
    pub err: Option<String>,
    pub toast: Option<(String, Instant)>,
    pub w: i32,
    pub h: i32,
    pub ptr: Option<(f64, f64)>,
    pub born: Instant,
    pub fx: Vec<Fx>,
}

impl A {
    pub fn new(look: crate::look::Look) -> A {
        let cfg = Cfg::load();
        A { look, devs: vec![], sel: String::new(), edit: cfg.clone(), cfg, busy: false, scanned: false, err: None, toast: None, w: 940, h: 640, ptr: None, born: Instant::now(), fx: vec![Fx::Scan] }
    }

    pub fn toast(&mut self, s: impl Into<String>) {
        self.toast = Some((s.into(), Instant::now()));
    }

    pub fn dev(&self) -> Option<&Dev> {
        self.devs.iter().find(|d| d.name == self.sel)
    }
    fn idx(&self) -> usize {
        self.devs.iter().position(|d| d.name == self.sel).unwrap_or(0)
    }

    pub fn dirty(&self) -> bool {
        self.edit != self.cfg
    }

    fn dc(&self) -> DevCfg {
        self.edit.devices.get(&self.sel).cloned().unwrap_or_default()
    }
    fn set_dc(&mut self, f: impl FnOnce(&mut DevCfg)) {
        let mut d = self.dc();
        f(&mut d);
        if d.is_empty() {
            self.edit.devices.remove(&self.sel);
        } else {
            self.edit.devices.insert(self.sel.clone(), d);
        }
    }

    pub fn on_scan(&mut self, r: Result<Vec<Dev>, String>) {
        self.scanned = true;
        match r {
            Ok(d) => {
                self.devs = d;
                self.err = None;
                if self.dev().is_none() {
                    // first start: the default output, otherwise the first device
                    self.sel = self.devs.iter().find(|d| d.default_sink).or(self.devs.first()).map(|d| d.name.clone()).unwrap_or_default();
                }
                // remember names: the config file then says which device a rule is for
                for d in &self.devs {
                    if !self.edit.names.contains_key(&d.name) {
                        self.edit.names.insert(d.name.clone(), d.desc.clone());
                        self.cfg.names.insert(d.name.clone(), d.desc.clone());
                    }
                }
            }
            Err(e) => self.err = Some(e),
        }
    }

    pub fn on_applied(&mut self, cfg: Cfg, r: Result<String, String>) {
        self.busy = false;
        match r {
            Ok(m) => {
                self.cfg = cfg;
                self.toast(m);
            }
            Err(e) => self.toast(format!("failed: {e}")),
        }
        self.fx.push(Fx::Scan);
    }

    pub fn go(&mut self, d: i32) {
        if self.devs.is_empty() {
            return;
        }
        let n = self.devs.len() as i32;
        let i = (self.idx() as i32 + d).rem_euclid(n) as usize;
        self.sel = self.devs[i].name.clone();
    }

    pub fn act(&mut self, a: Act) {
        if self.busy && !matches!(a, Act::Btn("close") | Act::Dev(_)) {
            return;
        }
        match a {
            Act::Block | Act::Bg => {}
            Act::Dev(i) => {
                if let Some(d) = self.devs.get(i) {
                    self.sel = d.name.clone();
                }
            }
            Act::Fmt(f) => self.set_dc(|d| d.format = f),
            Act::Rate(r) => self.set_dc(|d| d.rate = r),
            Act::Ch(c) => self.set_dc(|d| d.channels = c),
            Act::Prof(p) => self.set_dc(|d| d.profile = p),
            Act::Ldac(l) => self.set_dc(|d| d.ldac = l),
            Act::Aac(a) => self.set_dc(|d| d.aac = a),
            Act::BtRate(r) => self.edit.bt_rate = r,
            Act::Btn(b) => self.btn(b),
        }
    }

    pub fn btn(&mut self, b: &str) {
        match b {
            "close" => self.fx.push(Fx::Close),
            "scan" => {
                self.fx.push(Fx::Scan);
                self.toast("rescanned");
            }
            "apply" if self.dirty() && !self.busy => {
                self.busy = true;
                self.fx.push(Fx::Apply(self.edit.clone()));
            }
            "revert" => self.edit = self.cfg.clone(),
            "reset" => {
                // this device back to PipeWire's defaults (applied with «apply»)
                self.edit.devices.remove(&self.sel);
            }
            _ => {}
        }
    }

    pub fn animating(&self) -> bool {
        self.busy || self.toast.as_ref().map(|t| t.1.elapsed().as_millis() < 2600).unwrap_or(false) || self.born.elapsed().as_millis() < 400
    }
}

fn ease(born: Instant, ms: f32, a: &A) -> f32 {
    let d = a.look.dur(ms);
    if d <= 0.0 {
        return 1.0;
    }
    let t = (born.elapsed().as_secs_f32() * 1000.0 / d).min(1.0);
    1.0 - (1.0 - t).powi(3)
}

// ── drawing ──────────────────────────────────────────────────────────────

pub fn draw(ui: &mut Ui, a: &A, w: i32, h: i32) {
    let t = ui.t;
    ui.cv.clear(t.bg.alpha(t.glass.max(0.9)));
    ui.zone(R::new(0, 0, w, h), Act::Bg, Cur::Default);
    top(ui, a, w);
    let lw = (w / 3).clamp(220, 300);
    list(ui, a, R::new(12, 46, lw, h - 46 - 64));
    let pr = R::new(12 + lw + 12, 46, w - lw - 36, h - 46 - 64);
    match a.dev() {
        Some(d) => device(ui, a, d, pr),
        None => {
            ui.cv.pxbox(pr, &BoxStyle::new(t.panel.alpha(0.9), t.border));
            let msg = if !a.scanned {
                "scanning…".to_string()
            } else if let Some(e) = &a.err {
                e.clone()
            } else {
                "no audio devices".into()
            };
            ui.cv.icon("speaker", pr.x + pr.w / 2 - 14, pr.cy() - 40, 4, t.border.lerp(t.red, 0.4));
            ui.cv.text_center(ui.f, PX, R::new(pr.x, pr.cy() + 4, pr.w, 20), &msg, t.text_faint);
        }
    }
    bottom(ui, a, w, h);
    if let Some((s, born)) = &a.toast {
        if born.elapsed().as_millis() < 2600 {
            let tw = ui.w(PX, s).min(w - 60) + 36;
            let r = R::new((w - tw) / 2, h - 110, tw, 32);
            ui.cv.pxbox(r, &BoxStyle::new(t.panel.alpha(0.97), t.red).shadow(3));
            ui.cv.fill(R::new(r.x + 12, r.cy() - 3, 6, 6), t.red);
            ui.text_in(PX, R::new(r.x + 26, r.y, r.w - 32, r.h), s, t.text);
            ui.anim = true;
        }
    }
    let k = ease(a.born, 240.0, a);
    if k < 1.0 {
        ui.cv.dissolve(k, 2);
        ui.anim = true;
    }
}

fn top(ui: &mut Ui, a: &A, w: i32) {
    let t = ui.t;
    let r = R::new(0, 0, w, 34);
    ui.cv.fill(r, t.panel.alpha(0.9));
    ui.cv.fill(R::new(0, r.bottom() - 1, w, 1), t.border);
    ui.zone(r, Act::Block, Cur::Default);
    ui.cv.icon("speaker", 10, 10, 2, t.red);
    let nw = ui.text_in(PX, R::new(32, 0, w / 2, 34), "audio devices", t.text);
    let n = a.devs.len();
    ui.cv.text_in(ui.f, PX, R::new(32 + nw + 10, 0, 200, 34), &format!("{n} found"), t.text_faint);
    let bs = 26;
    ui.button(R::new(w - bs - 6, 4, bs, bs), "", "close", Tone::Ghost, false, true, Act::Btn("close"));
    ui.button(R::new(w - 2 * bs - 10, 4, bs, bs), "", "redo", Tone::Ghost, false, !a.busy, Act::Btn("scan"));
}

fn sub_line(d: &Dev, cfg: Option<&DevCfg>) -> (String, bool) {
    match d.kind {
        Kind::Alsa => match &d.live {
            Some(l) => (format!("{} · {} · {} ch", l.format.replace("_LE", ""), pw::khz(l.rate), l.channels), true),
            None => {
                let set = cfg.map(|c| (c.format.as_deref().map(pw::bits).unwrap_or(""), c.rate.map(pw::khz).unwrap_or_default())).unwrap_or(("", String::new()));
                let mut s = format!("{} · idle", if d.bus.is_empty() { "alsa" } else { &d.bus });
                if !set.0.is_empty() || !set.1.is_empty() {
                    s = format!("{s} · set {}", [set.0.to_string(), set.1].iter().filter(|x| !x.is_empty()).cloned().collect::<Vec<_>>().join(" "));
                }
                (s, false)
            }
        },
        Kind::Bluez => {
            let c = pw::codec_of(d, None);
            if c.is_empty() && d.sinks.is_empty() {
                ("bluetooth · no audio profile".into(), false)
            } else {
                let r = if d.sink_rate > 0 { format!(" · {}", pw::khz(d.sink_rate)) } else { String::new() };
                (format!("bluetooth · {}{r}", pw::codec_label(&c)), !d.sinks.is_empty())
            }
        }
    }
}

fn list(ui: &mut Ui, a: &A, r: R) {
    let t = ui.t;
    ui.cv.pxbox(r, &BoxStyle::new(t.panel.alpha(0.9), t.border).shadow(3));
    ui.zone(r, Act::Block, Cur::Default);
    ui.header(R::new(r.x, r.y, r.w, 30), "", "devices", "");
    let mut y = r.y + 38;
    for (i, d) in a.devs.iter().enumerate() {
        let ir = R::new(r.x + 8, y, r.w - 16, 50);
        if ir.bottom() > r.bottom() - 6 {
            break;
        }
        let sel = d.name == a.sel;
        let hov = ui.hover(ir);
        let fill = if sel { t.selection.alpha(0.55) } else if hov { t.surface_hi } else { t.surface };
        let line = if sel { t.red } else if hov { t.border.lerp(t.red, 0.5) } else { t.border };
        ui.cv.pxbox(ir, &BoxStyle::new(fill, line));
        let icon = if d.kind == Kind::Bluez { "bt" } else { "speaker" };
        ui.cv.icon(icon, ir.x + 10, ir.y + 11, 2, if sel { t.ember } else { t.red });
        let cfg = a.edit.devices.get(&d.name);
        ui.cv.text_in(ui.f, PX, R::new(ir.x + 34, ir.y + 4, ir.w - 56, 22), &d.desc, if sel { crate::theme::WHITE } else { t.text });
        let (sub, on) = sub_line(d, cfg);
        ui.cv.text_in(ui.f, PX, R::new(ir.x + 34, ir.y + 24, ir.w - 44, 20), &sub, if on { t.text_dim } else { t.text_faint });
        // default output: a lit square; own settings: a hollow one
        if d.default_sink {
            ui.cv.fill(R::new(ir.right() - 16, ir.y + 10, 6, 6), t.ok);
        }
        if cfg.map(|c| !c.is_empty()).unwrap_or(false) {
            ui.cv.outline(R::new(ir.right() - 16, ir.y + 22, 6, 6), t.ember, 1);
        }
        ui.zone(ir, Act::Dev(i), Cur::Pointer);
        y += 56;
    }
    // legend
    let ly = r.bottom() - 24;
    ui.cv.fill(R::new(r.x + 12, ly + 7, 6, 6), t.ok);
    let w1 = ui.text_in(PX, R::new(r.x + 24, ly, 120, 20), "default", t.text_faint);
    ui.cv.outline(R::new(r.x + 36 + w1, ly + 7, 6, 6), t.ember, 1);
    ui.text_in(PX, R::new(r.x + 48 + w1, ly, 140, 20), "own settings", t.text_faint);
}

/// one option button in a row of chips; wraps to the next row when full
struct Chips {
    x0: i32,
    x: i32,
    y: i32,
    right: i32,
}

impl Chips {
    fn new(x: i32, y: i32, right: i32) -> Chips {
        Chips { x0: x, x, y, right }
    }
    fn chip(&mut self, ui: &mut Ui, label: &str, sel: bool, on: bool, act: Act) {
        let bw = ui.w(PX, label) + 26;
        if self.x + bw > self.right && self.x > self.x0 {
            self.x = self.x0;
            self.y += 34;
        }
        ui.button(R::new(self.x, self.y, bw, 26), label, "", Tone::Plain, sel, on, act);
        self.x += bw + 6;
    }
    /// y under the last row
    fn end(&self) -> i32 {
        self.y + 26
    }
}

fn section(ui: &mut Ui, x: i32, y: i32, w: i32, title: &str, hint: &str) -> i32 {
    let t = ui.t;
    ui.cv.fill(R::new(x, y + 7, 6, 6), t.red);
    let tw = ui.text_in(PX, R::new(x + 12, y, w / 2, 20), title, t.text);
    if !hint.is_empty() {
        ui.text_in(PX, R::new(x + 24 + tw, y, w - tw - 24, 20), hint, t.text_faint);
    }
    y + 26
}

fn device(ui: &mut Ui, a: &A, d: &Dev, r: R) {
    let t = ui.t;
    ui.cv.pxbox(r, &BoxStyle::new(t.panel.alpha(0.9), t.border).shadow(3));
    ui.zone(r, Act::Block, Cur::Default);
    let sub = [d.vendor.as_str(), d.product.as_str()].iter().filter(|s| !s.is_empty() && **s != d.desc).cloned().collect::<Vec<_>>().join(" · ");
    ui.header(R::new(r.x, r.y, r.w, 30), if d.kind == Kind::Bluez { "bt" } else { "speaker" }, &d.desc, &sub);
    let c = a.edit.devices.get(&d.name).cloned().unwrap_or_default();
    let x = r.x + 16;
    let right = r.right() - 16;
    let cw = right - x;
    let mut y = r.y + 44;
    ui.cv.push_clip(r.inset(1));
    match d.kind {
        Kind::Alsa => {
            y = section(ui, x, y, cw, "bit depth", "sample format sent to the device");
            let mut ch = Chips::new(x, y, right);
            ch.chip(ui, "auto", c.format.is_none(), true, Act::Fmt(None));
            for f in &d.formats {
                ch.chip(ui, pw::bits(f), c.format.as_deref() == Some(f), true, Act::Fmt(Some(f.clone())));
            }
            y = ch.end() + 16;
            y = section(ui, x, y, cw, "sample rate", "fixed: everything is resampled to it");
            let mut ch = Chips::new(x, y, right);
            ch.chip(ui, "auto", c.rate.is_none(), true, Act::Rate(None));
            for rate in &d.rates {
                ch.chip(ui, &pw::khz(*rate), c.rate == Some(*rate), true, Act::Rate(Some(*rate)));
            }
            y = ch.end() + 16;
            y = section(ui, x, y, cw, "channels", "");
            let mut ch = Chips::new(x, y, right);
            ch.chip(ui, "auto", c.channels.is_none(), true, Act::Ch(None));
            for n in &d.channels {
                ch.chip(ui, &format!("{n} ch"), c.channels == Some(*n), true, Act::Ch(Some(*n)));
            }
            y = ch.end() + 20;
            let live = match &d.live {
                Some(l) => format!("{} · {} ch · {} Hz", l.format, l.channels, l.rate),
                None => "idle: nothing is playing".into(),
            };
            let max = format!("{} · {} ch · {}", d.formats.last().map(|f| pw::bits(f)).unwrap_or("?"), d.channels.last().copied().unwrap_or(2), d.rates.last().map(|r| pw::khz(*r)).unwrap_or_default());
            let rows = vec![
                ("hardware now", live),
                ("device max", max),
                ("bus", format!("{}{}", d.bus, d.card.map(|c| format!(" · card {c}")).unwrap_or_default())),
                ("output", d.sinks.first().cloned().unwrap_or_else(|| "—".into())),
            ];
            info_rows(ui, x, y, cw, rows);
        }
        Kind::Bluez => {
            let a2dp: Vec<&pw::Prof> = d.profiles.iter().filter(|p| pw::profile_codec(&p.name).is_some()).collect();
            let other: Vec<&pw::Prof> = d.profiles.iter().filter(|p| pw::profile_codec(&p.name).is_none() && p.name != "off").collect();
            let cur = d.cur_profile().map(|p| p.name.clone());
            let want = c.profile.clone().or(cur.clone());
            y = section(ui, x, y, cw, "codec", "A2DP, high quality playback");
            let mut ch = Chips::new(x, y, right);
            if a2dp.is_empty() {
                ui.text_in(PX, R::new(x, y, cw, 26), "no A2DP profile: is the device connected for audio?", t.text_faint);
            }
            for p in &a2dp {
                let codec = pw::profile_codec(&p.name).unwrap_or("");
                ch.chip(ui, &pw::codec_label(codec), want.as_deref() == Some(p.name.as_str()), p.available, Act::Prof(Some(p.name.clone())));
            }
            y = ch.end() + 14;
            if !other.is_empty() {
                y = section(ui, x, y, cw, "call profiles", "microphone on, lower quality");
                let mut ch = Chips::new(x, y, right);
                for p in &other {
                    ch.chip(ui, &short_profile(p), want.as_deref() == Some(p.name.as_str()), p.available, Act::Prof(Some(p.name.clone())));
                }
                y = ch.end() + 14;
            }
            let codec = pw::codec_of(d, c.profile.as_deref());
            y = section(ui, x, y, cw, "bitrate", &pw::codec_label(&codec));
            match codec.as_str() {
                "ldac" => {
                    let mut ch = Chips::new(x, y, right);
                    for (v, l) in pw::LDAC {
                        let sel = c.ldac.as_deref().unwrap_or("auto") == *v;
                        ch.chip(ui, l, sel, true, Act::Ldac(if *v == "auto" { None } else { Some(v.to_string()) }));
                    }
                    y = ch.end() + 14;
                }
                "aac" | "aac_eld" => {
                    let mut ch = Chips::new(x, y, right);
                    for (v, l) in pw::AAC {
                        let sel = c.aac.unwrap_or(0) == *v;
                        ch.chip(ui, l, sel, true, Act::Aac(if *v == 0 { None } else { Some(*v) }));
                    }
                    y = ch.end() + 14;
                }
                _ => {
                    let b = pw::codec_bitrate(&codec);
                    let s = if b.is_empty() { "set by the codec".to_string() } else { format!("{b} · fixed by the codec") };
                    ui.cv.text_in(ui.f, PX, R::new(x, y, cw, 26), &s, t.text_dim);
                    y += 26 + 14;
                }
            }
            y = section(ui, x, y, cw, "sample rate", "all Bluetooth devices · if the codec allows");
            let mut ch = Chips::new(x, y, right);
            ch.chip(ui, "auto", a.edit.bt_rate == 0, true, Act::BtRate(0));
            for r in pw::BT_RATES {
                ch.chip(ui, &pw::khz(*r), a.edit.bt_rate == *r, true, Act::BtRate(*r));
            }
            y = ch.end() + 20;
            let now = if d.sinks.is_empty() {
                "no audio stream".to_string()
            } else {
                let mut s = pw::codec_label(&d.codec);
                if d.sink_rate > 0 {
                    s = format!("{s} · {} Hz", d.sink_rate);
                }
                if !d.sink_format.is_empty() {
                    s = format!("{s} · {}", d.sink_format);
                }
                s
            };
            let rows = vec![
                ("now", now),
                ("profile", d.cur_profile().map(|p| p.desc.clone()).unwrap_or_else(|| "—".into())),
                ("address", d.name.trim_start_matches("bluez_card.").replace('_', ":")),
            ];
            info_rows(ui, x, y, cw, rows);
        }
    }
    ui.cv.pop_clip();
    // per-device reset in the header
    let has = a.edit.devices.get(&d.name).map(|c| !c.is_empty()).unwrap_or(false);
    let rw = ui.w(PX, "defaults") + 26;
    ui.button(R::new(r.right() - rw - 6, r.y + 3, rw, 24), "defaults", "", Tone::Ghost, false, has && !a.busy, Act::Btn("reset"));
}

fn short_profile(p: &pw::Prof) -> String {
    // "Headset Head Unit (HSP/HFP, codec mSBC)" → "HSP/HFP mSBC"
    let inner = p.desc.split_once('(').map(|x| x.1.trim_end_matches(')')).unwrap_or(&p.desc);
    let mut parts: Vec<&str> = inner.split(',').map(|s| s.trim()).collect();
    if let Some(c) = parts.iter_mut().find(|s| s.starts_with("codec ")) {
        *c = c.trim_start_matches("codec ");
    }
    let s = parts.join(" ");
    if s.is_empty() {
        p.name.clone()
    } else {
        s
    }
}

fn info_rows(ui: &mut Ui, x: i32, y: i32, w: i32, rows: Vec<(&str, String)>) {
    let t = ui.t;
    let h = rows.len() as i32 * 24 + 12;
    ui.cv.pxbox(R::new(x, y, w, h), &BoxStyle::new(t.code_bg, t.border));
    let mut yy = y + 6;
    for (k, v) in rows {
        ui.text_in(PX, R::new(x + 12, yy, 130, 22), k, t.text_faint);
        ui.cv.text_in(ui.f, PX, R::new(x + 144, yy, w - 156, 22), &v, t.text_dim);
        yy += 24;
    }
}

fn bottom(ui: &mut Ui, a: &A, w: i32, h: i32) {
    let t = ui.t;
    let r = R::new(12, h - 54, w - 24, 42);
    ui.cv.pxbox(r, &BoxStyle::new(t.panel.alpha(0.96), t.border.lerp(t.red, 0.5)).shadow(4));
    ui.zone(r, Act::Block, Cur::Default);
    let dirty = a.dirty();
    let aw = ui.w(PX, "apply") + 50;
    let vw = ui.w(PX, "revert") + 30;
    ui.button(R::new(r.right() - aw - 8, r.y + 7, aw, 28), "apply", "check", Tone::Primary, false, dirty && !a.busy, Act::Btn("apply"));
    ui.button(R::new(r.right() - aw - vw - 16, r.y + 7, vw, 28), "revert", "", Tone::Plain, false, dirty && !a.busy, Act::Btn("revert"));
    let msg = if a.busy {
        ui.anim = true;
        let dots = ".".repeat(1 + (a.born.elapsed().as_millis() / 250 % 3) as usize);
        (format!("applying, WirePlumber restarts{dots}"), t.ember)
    } else if dirty {
        ("unsaved changes · apply restarts WirePlumber (sound pauses ~1 s)".to_string(), t.warn)
    } else {
        (format!("saved in {}", pw::conf_path().to_string_lossy().replace(&crate::paths::home().to_string_lossy().to_string(), "~")), t.text_faint)
    };
    ui.cv.fill(R::new(r.x + 12, r.cy() - 3, 6, 6), if dirty || a.busy { msg.1 } else { t.border });
    ui.cv.text_in(ui.f, PX, R::new(r.x + 26, r.y, r.w - aw - vw - 52, r.h), &msg.0, msg.1);
}
