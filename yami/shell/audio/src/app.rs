// Window of yami-audio: xdg-toplevel, shm buffer, mouse and keyboard (same setup as
// yami-view). pw-dump, config writes and WirePlumber restarts run in a worker thread so the
// window never blocks; the list refreshes every 3 s.

use crate::font::Fonts;
use crate::gfx::Canvas;
use crate::icons::Icons;
use crate::panel::{Act, Fx, Ui, A};
use crate::pw::{self, Cfg, Dev};
use calloop::channel::{self, Sender};
use calloop::timer::{TimeoutAction, Timer};
use calloop::{EventLoop, LoopHandle};
use calloop_wayland_source::WaylandSource;
use smithay_client_toolkit::{
    compositor::{CompositorHandler, CompositorState, Region},
    delegate_compositor, delegate_keyboard, delegate_output, delegate_pointer, delegate_registry, delegate_seat, delegate_shm, delegate_xdg_shell, delegate_xdg_window,
    output::{OutputHandler, OutputState},
    registry::{ProvidesRegistryState, RegistryState},
    registry_handlers,
    seat::{
        keyboard::{KeyEvent, KeyboardHandler, Keysym, Modifiers, RawModifiers},
        pointer::{cursor_shape::CursorShapeManager, PointerEvent, PointerEventKind, PointerHandler},
        Capability, SeatHandler, SeatState,
    },
    shell::{
        xdg::{
            window::{Window, WindowConfigure, WindowDecorations, WindowHandler},
            XdgShell,
        },
        WaylandSurface,
    },
    shm::{slot::SlotPool, Shm, ShmHandler},
};
use std::time::{Duration, Instant};
use wayland_client::{
    globals::registry_queue_init,
    protocol::{wl_keyboard, wl_output, wl_pointer, wl_seat, wl_shm, wl_surface},
    Connection, Dispatch, QueueHandle,
};
use wayland_protocols::ext::background_effect::v1::client::{ext_background_effect_manager_v1, ext_background_effect_surface_v1};
use wayland_protocols::wp::cursor_shape::v1::client::wp_cursor_shape_device_v1::{Shape, WpCursorShapeDeviceV1};
use wayland_protocols::wp::fractional_scale::v1::client::{wp_fractional_scale_manager_v1 as frac_mgr, wp_fractional_scale_v1 as frac};
use wayland_protocols::wp::viewporter::client::{wp_viewport, wp_viewporter};

pub enum Ev {
    Scanned(Result<Vec<Dev>, String>),
    Applied(Cfg, Result<String, String>),
}

enum Job {
    Scan,
    Apply(Cfg),
}

pub struct App {
    conn: Connection,
    qh: QueueHandle<App>,
    handle: LoopHandle<'static, App>,
    jobs: std::sync::mpsc::Sender<Job>,
    registry: RegistryState,
    seat: SeatState,
    outputs: OutputState,
    compositor: CompositorState,
    shm: Shm,
    window: Window,
    cursor_mgr: Option<CursorShapeManager>,
    cursor_dev: Option<WpCursorShapeDeviceV1>,
    cursor_now: Option<Shape>,
    enter_serial: u32,
    fx_mgr: Option<ext_background_effect_manager_v1::ExtBackgroundEffectManagerV1>,
    fx: Option<ext_background_effect_surface_v1::ExtBackgroundEffectSurfaceV1>,
    /// HiDPI: buffer in physical pixels (wp_fractional_scale + viewport), canvas logical
    scale: f64,
    hidpi: Option<(frac::WpFractionalScaleV1, wp_viewport::WpViewport)>,
    scratch: Vec<u32>,
    blur_on: bool,
    pointer: Option<wl_pointer::WlPointer>,
    keyboard: Option<wl_keyboard::WlKeyboard>,
    mods: Modifiers,
    press_act: Option<Act>,
    pool: Option<SlotPool>,
    configured: bool,
    dirty: bool,
    frame_pending: bool,
    anim: bool,
    zones: Vec<yami_px::ui::Zone<Act>>,
    fonts: Fonts,
    icons: Icons,
    a: A,
    quit: bool,
    last_scan: Instant,
    scanning: bool,
}

pub fn run(a: A) -> i32 {
    let Ok(conn) = Connection::connect_to_env() else {
        eprintln!("yami-audio: no Wayland display (try `yami-audio list`)");
        return 1;
    };
    let (globals, mut queue) = registry_queue_init::<App>(&conn).expect("wayland registry");
    let qh = queue.handle();
    let mut ev: EventLoop<'static, App> = EventLoop::try_new().expect("event loop");
    let handle = ev.handle();
    let (tx, rx) = channel::channel::<Ev>();
    handle
        .insert_source(rx, |e, _, app: &mut App| {
            if let channel::Event::Msg(m) = e {
                app.on_ev(m);
            }
        })
        .expect("channel");
    let jobs = worker(tx);
    let compositor = CompositorState::bind(&globals, &qh).expect("wl_compositor");
    let xdg = XdgShell::bind(&globals, &qh).expect("xdg_shell");
    let shm = Shm::bind(&globals, &qh).expect("wl_shm");
    let surface = compositor.create_surface(&qh);
    let window = xdg.create_window(surface, WindowDecorations::RequestServer, &qh);
    window.set_app_id("yami-audio");
    window.set_title("audio devices");
    window.set_min_size(Some((640, 500)));
    window.commit();
    let hidpi = {
        let fm: Option<frac_mgr::WpFractionalScaleManagerV1> = globals.bind(&qh, 1..=1, ()).ok();
        let vpr: Option<wp_viewporter::WpViewporter> = globals.bind(&qh, 1..=1, ()).ok();
        match (fm, vpr) {
            (Some(fm), Some(vpr)) => Some((fm.get_fractional_scale(window.wl_surface(), &qh, ()), vpr.get_viewport(window.wl_surface(), &qh, ()))),
            _ => None,
        }
    };
    let font = a.look.font("view").to_string();
    let mut app = App {
        conn: conn.clone(),
        qh: qh.clone(),
        handle: handle.clone(),
        jobs,
        registry: RegistryState::new(&globals),
        seat: SeatState::new(&globals, &qh),
        outputs: OutputState::new(&globals, &qh),
        compositor,
        shm,
        window,
        cursor_mgr: CursorShapeManager::bind(&globals, &qh).ok(),
        cursor_dev: None,
        cursor_now: None,
        enter_serial: 0,
        fx_mgr: globals.bind(&qh, 1..=1, ()).ok(),
        fx: None,
        scale: 1.0,
        hidpi,
        scratch: vec![],
        blur_on: false,
        pointer: None,
        keyboard: None,
        mods: Modifiers::default(),
        press_act: None,
        pool: None,
        configured: false,
        dirty: true,
        frame_pending: false,
        anim: false,
        zones: vec![],
        fonts: Fonts::with(&font),
        icons: Icons::new(""),
        a,
        quit: false,
        last_scan: Instant::now(),
        scanning: false,
    };
    app.effects();
    handle
        .insert_source(Timer::from_duration(Duration::from_millis(50)), |_, _, app: &mut App| {
            if app.a.look.stale() {
                let font = app.a.look.font("view").to_string();
                app.a.look = crate::look::Look::load();
                if app.a.look.font("view") != font {
                    app.fonts = Fonts::with(app.a.look.font("view"));
                }
                app.dirty = true;
            }
            // live state (what the DAC runs at, codec) follows playback
            if !app.a.busy && !app.scanning && app.last_scan.elapsed() > Duration::from_secs(3) {
                app.a.fx.push(Fx::Scan);
                app.effects();
            }
            if app.a.animating() {
                app.dirty = true;
            }
            app.flush();
            TimeoutAction::ToDuration(Duration::from_millis(if app.a.animating() { 40 } else { 500 }))
        })
        .expect("timer");
    let _ = queue.roundtrip(&mut app);
    WaylandSource::new(conn.clone(), queue).insert(handle.clone()).expect("wayland source");
    loop {
        if ev.dispatch(Some(Duration::from_secs(2)), &mut app).is_err() {
            break;
        }
        app.flush();
        if app.quit {
            break;
        }
    }
    0
}

/// one thread for all PipeWire work: jobs run in order, a pile of scans collapses into one
fn worker(tx: Sender<Ev>) -> std::sync::mpsc::Sender<Job> {
    let (jtx, jrx) = std::sync::mpsc::channel::<Job>();
    std::thread::spawn(move || {
        while let Ok(first) = jrx.recv() {
            let mut q = vec![first];
            while let Ok(j) = jrx.try_recv() {
                q.push(j);
            }
            let mut scan = false;
            for j in q {
                match j {
                    Job::Scan => scan = true,
                    Job::Apply(c) => {
                        let r = pw::apply(&c);
                        let _ = tx.send(Ev::Applied(c, r));
                        scan = true;
                    }
                }
            }
            if scan {
                let _ = tx.send(Ev::Scanned(pw::scan()));
            }
        }
    });
    jtx
}

impl App {
    fn on_ev(&mut self, e: Ev) {
        match e {
            Ev::Scanned(r) => {
                self.scanning = false;
                self.last_scan = Instant::now();
                if r.as_ref().ok() != Some(&self.a.devs) || !self.a.scanned {
                    self.a.on_scan(r);
                    self.dirty = true;
                }
            }
            Ev::Applied(c, r) => {
                self.a.on_applied(c, r);
                self.dirty = true;
            }
        }
        self.effects();
    }

    fn effects(&mut self) {
        for f in std::mem::take(&mut self.a.fx) {
            match f {
                Fx::Close => self.quit = true,
                Fx::Scan => {
                    self.scanning = true;
                    let _ = self.jobs.send(Job::Scan);
                }
                Fx::Apply(c) => {
                    let _ = self.jobs.send(Job::Apply(c));
                }
            }
        }
    }

    fn flush(&mut self) {
        if self.dirty && self.configured && !self.frame_pending {
            self.draw();
        }
        let _ = self.conn.flush();
    }

    fn draw(&mut self) {
        self.dirty = false;
        let (w, h) = (self.a.w, self.a.h);
        let (pw, ph) = if self.hidpi.is_none() || self.scale == 1.0 { (w, h) } else { yami_px::gfx::phys(w, h, self.scale) };
        let up = (pw, ph) != (w, h);
        let need = (pw * ph * 4) as usize;
        if self.pool.as_ref().map(|p| p.len() < need).unwrap_or(true) {
            self.pool = SlotPool::new(need * 2, &self.shm).ok();
        }
        let Some(pool) = self.pool.as_mut() else { return };
        let Ok((buffer, bytes)) = pool.create_buffer(pw, ph, pw * 4, wl_shm::Format::Argb8888) else { return };
        let (out_ptr, out_len) = (bytes.as_mut_ptr() as *mut u32, bytes.len() / 4);
        let mut scratch = std::mem::take(&mut self.scratch);
        let buf: &mut [u32] = if up {
            scratch.clear();
            scratch.resize((w * h) as usize, 0);
            &mut scratch
        } else {
            unsafe { std::slice::from_raw_parts_mut(out_ptr, out_len) }
        };
        {
            let mut ui = Ui { cv: Canvas::new(buf, w, h), f: &mut self.fonts, ic: &mut self.icons, t: self.a.look.theme, zones: vec![], ptr: self.a.ptr, down: self.press_act.is_some(), anim: false, blink: true, tr: crate::tr };
            crate::panel::draw(&mut ui, &self.a, w, h);
            self.zones = std::mem::take(&mut ui.zones);
            self.anim = ui.anim;
        }
        if up {
            yami_px::gfx::upscale(&scratch, w, h, unsafe { std::slice::from_raw_parts_mut(out_ptr, out_len) }, pw, ph);
        }
        self.scratch = scratch;
        let surf = self.window.wl_surface().clone();
        if let Some((_, vp)) = &self.hidpi {
            vp.set_destination(w, h);
        }
        surf.damage_buffer(0, 0, pw, ph);
        // glass under the window while the theme background is translucent
        let want_blur = self.a.look.blur;
        if want_blur != self.blur_on {
            if let Some(mgr) = &self.fx_mgr {
                let fx = self.fx.get_or_insert_with(|| mgr.get_background_effect(&surf, &self.qh, ()));
                if want_blur {
                    if let Ok(r) = Region::new(&self.compositor) {
                        r.add(0, 0, i32::MAX / 2, i32::MAX / 2);
                        fx.set_blur_region(Some(r.wl_region()));
                    }
                } else {
                    fx.set_blur_region(None);
                }
            }
            self.blur_on = want_blur;
        }
        if self.anim {
            surf.frame(&self.qh, surf.clone());
            self.frame_pending = true;
        }
        let _ = buffer.attach_to(&surf);
        surf.commit();
    }

    fn zone_at(&self, x: f64, y: f64) -> Option<yami_px::ui::Zone<Act>> {
        self.zones.iter().rev().find(|z| z.r.contains(x, y)).cloned()
    }

    fn set_cursor(&mut self, c: Shape) {
        if self.cursor_now == Some(c) {
            return;
        }
        self.cursor_now = Some(c);
        if let Some(d) = &self.cursor_dev {
            d.set_shape(self.enter_serial, c);
        }
    }

    fn key(&mut self, e: &KeyEvent) {
        let c = self.mods.ctrl;
        let a = &mut self.a;
        match e.keysym {
            Keysym::Escape => a.btn("close"),
            Keysym::Up | Keysym::k => a.go(-1),
            Keysym::Down | Keysym::j | Keysym::Tab => a.go(1),
            Keysym::F5 => a.btn("scan"),
            Keysym::Return | Keysym::KP_Enter => a.btn("apply"),
            _ => match e.raw_code {
                // physical keys, so they work in any layout
                16 => a.btn("close"),            // q
                19 if !c => a.btn("scan"),       // r
                31 if c => a.btn("apply"),       // ctrl+s
                44 if c => a.btn("revert"),      // ctrl+z
                _ => {}
            },
        }
        self.effects();
        self.dirty = true;
    }

    fn on_pointer(&mut self, e: &PointerEvent) {
        let (x, y) = e.position;
        match e.kind {
            PointerEventKind::Enter { serial } => {
                self.enter_serial = serial;
                self.cursor_now = None;
                self.a.ptr = Some((x, y));
                self.set_cursor(Shape::Default);
            }
            PointerEventKind::Leave { .. } => {
                self.a.ptr = None;
                self.dirty = true;
            }
            PointerEventKind::Motion { .. } => {
                self.a.ptr = Some((x, y));
                let shape = match self.zone_at(x, y).map(|z| z.cur) {
                    Some(yami_px::ui::Cur::Pointer) => Shape::Pointer,
                    _ => Shape::Default,
                };
                self.set_cursor(shape);
                self.dirty = true;
            }
            PointerEventKind::Press { button, .. } => {
                if button == 0x110 {
                    self.press_act = self.zone_at(x, y).map(|z| z.act).filter(|a| !matches!(a, Act::Bg | Act::Block));
                }
                self.dirty = true;
            }
            PointerEventKind::Release { button, .. } => {
                if button == 0x110 {
                    if let Some(a) = self.press_act.take() {
                        if self.zone_at(x, y).map(|z| z.act == a).unwrap_or(false) {
                            self.a.act(a);
                        }
                    }
                }
                self.effects();
                self.dirty = true;
            }
            PointerEventKind::Axis { vertical, .. } => {
                // wheel over the list: next / previous device
                let d = if vertical.value120 != 0 { vertical.value120 as f64 / 120.0 } else if vertical.discrete != 0 { vertical.discrete as f64 } else { vertical.absolute / 15.0 };
                if d.abs() >= 0.5 && matches!(self.zone_at(x, y).map(|z| z.act), Some(Act::Dev(_))) {
                    self.a.go(if d > 0.0 { 1 } else { -1 });
                    self.dirty = true;
                }
            }
        }
    }
}

impl CompositorHandler for App {
    fn scale_factor_changed(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &wl_surface::WlSurface, _: i32) {}
    fn transform_changed(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &wl_surface::WlSurface, _: wl_output::Transform) {}
    fn frame(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &wl_surface::WlSurface, _: u32) {
        self.frame_pending = false;
        if self.anim {
            self.dirty = true;
        }
    }
    fn surface_enter(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &wl_surface::WlSurface, _: &wl_output::WlOutput) {}
    fn surface_leave(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &wl_surface::WlSurface, _: &wl_output::WlOutput) {}
}

impl OutputHandler for App {
    fn output_state(&mut self) -> &mut OutputState {
        &mut self.outputs
    }
    fn new_output(&mut self, _: &Connection, _: &QueueHandle<Self>, _: wl_output::WlOutput) {}
    fn update_output(&mut self, _: &Connection, _: &QueueHandle<Self>, _: wl_output::WlOutput) {}
    fn output_destroyed(&mut self, _: &Connection, _: &QueueHandle<Self>, _: wl_output::WlOutput) {}
}

impl WindowHandler for App {
    fn request_close(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &Window) {
        self.quit = true;
    }
    fn configure(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &Window, c: WindowConfigure, _: u32) {
        if let (Some(w), Some(h)) = c.new_size {
            self.a.w = w.get() as i32;
            self.a.h = h.get() as i32;
        }
        self.configured = true;
        self.dirty = true;
        self.frame_pending = false;
        self.draw();
    }
}

impl SeatHandler for App {
    fn seat_state(&mut self) -> &mut SeatState {
        &mut self.seat
    }
    fn new_seat(&mut self, _: &Connection, _: &QueueHandle<Self>, _: wl_seat::WlSeat) {}
    fn new_capability(&mut self, _: &Connection, qh: &QueueHandle<Self>, seat: wl_seat::WlSeat, cap: Capability) {
        if cap == Capability::Keyboard && self.keyboard.is_none() {
            let h = self.handle.clone();
            self.keyboard = self.seat.get_keyboard_with_repeat(qh, &seat, None, h, Box::new(|app: &mut App, _, e| app.key(&e))).ok();
        }
        if cap == Capability::Pointer && self.pointer.is_none() {
            if let Ok(p) = self.seat.get_pointer(qh, &seat) {
                if let Some(m) = &self.cursor_mgr {
                    self.cursor_dev = Some(m.get_shape_device(&p, qh));
                }
                self.pointer = Some(p);
            }
        }
    }
    fn remove_capability(&mut self, _: &Connection, _: &QueueHandle<Self>, _: wl_seat::WlSeat, cap: Capability) {
        if cap == Capability::Keyboard {
            if let Some(k) = self.keyboard.take() {
                k.release();
            }
        }
        if cap == Capability::Pointer {
            if let Some(p) = self.pointer.take() {
                p.release();
            }
            self.cursor_dev = None;
        }
    }
    fn remove_seat(&mut self, _: &Connection, _: &QueueHandle<Self>, _: wl_seat::WlSeat) {}
}

impl KeyboardHandler for App {
    fn enter(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &wl_keyboard::WlKeyboard, _: &wl_surface::WlSurface, _: u32, _: &[u32], _: &[Keysym]) {}
    fn leave(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &wl_keyboard::WlKeyboard, _: &wl_surface::WlSurface, _: u32) {}
    fn press_key(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &wl_keyboard::WlKeyboard, _: u32, e: KeyEvent) {
        self.key(&e);
    }
    fn repeat_key(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &wl_keyboard::WlKeyboard, _: u32, e: KeyEvent) {
        if matches!(e.keysym, Keysym::Up | Keysym::Down | Keysym::j | Keysym::k) {
            self.key(&e);
        }
    }
    fn release_key(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &wl_keyboard::WlKeyboard, _: u32, _: KeyEvent) {}
    fn update_modifiers(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &wl_keyboard::WlKeyboard, _: u32, m: Modifiers, _: RawModifiers, _: u32) {
        self.mods = m;
    }
}

impl PointerHandler for App {
    fn pointer_frame(&mut self, _: &Connection, _: &QueueHandle<Self>, _: &wl_pointer::WlPointer, events: &[PointerEvent]) {
        for e in events {
            self.on_pointer(e);
        }
    }
}

impl ShmHandler for App {
    fn shm_state(&mut self) -> &mut Shm {
        &mut self.shm
    }
}

impl ProvidesRegistryState for App {
    fn registry(&mut self) -> &mut RegistryState {
        &mut self.registry
    }
    registry_handlers![OutputState, SeatState];
}

impl Dispatch<frac_mgr::WpFractionalScaleManagerV1, ()> for App {
    fn event(_: &mut Self, _: &frac_mgr::WpFractionalScaleManagerV1, _: frac_mgr::Event, _: &(), _: &Connection, _: &QueueHandle<Self>) {}
}
impl Dispatch<wp_viewporter::WpViewporter, ()> for App {
    fn event(_: &mut Self, _: &wp_viewporter::WpViewporter, _: wp_viewporter::Event, _: &(), _: &Connection, _: &QueueHandle<Self>) {}
}
impl Dispatch<wp_viewport::WpViewport, ()> for App {
    fn event(_: &mut Self, _: &wp_viewport::WpViewport, _: wp_viewport::Event, _: &(), _: &Connection, _: &QueueHandle<Self>) {}
}
impl Dispatch<frac::WpFractionalScaleV1, ()> for App {
    fn event(app: &mut Self, _: &frac::WpFractionalScaleV1, e: frac::Event, _: &(), _: &Connection, _: &QueueHandle<Self>) {
        if let frac::Event::PreferredScale { scale } = e {
            let v = scale as f64 / 120.0;
            if v != app.scale {
                app.scale = v;
                app.dirty = true;
            }
        }
    }
}

impl Dispatch<ext_background_effect_manager_v1::ExtBackgroundEffectManagerV1, ()> for App {
    fn event(_: &mut Self, _: &ext_background_effect_manager_v1::ExtBackgroundEffectManagerV1, _: ext_background_effect_manager_v1::Event, _: &(), _: &Connection, _: &QueueHandle<Self>) {}
}
impl Dispatch<ext_background_effect_surface_v1::ExtBackgroundEffectSurfaceV1, ()> for App {
    fn event(_: &mut Self, _: &ext_background_effect_surface_v1::ExtBackgroundEffectSurfaceV1, _: ext_background_effect_surface_v1::Event, _: &(), _: &Connection, _: &QueueHandle<Self>) {}
}

delegate_compositor!(App);
delegate_output!(App);
delegate_shm!(App);
delegate_seat!(App);
delegate_keyboard!(App);
delegate_pointer!(App);
delegate_xdg_shell!(App);
delegate_xdg_window!(App);
delegate_registry!(App);
