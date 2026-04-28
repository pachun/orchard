// Apple MTP trackpad palm-rejection shim.
//
// Reads raw multi-touch events from the kernel device, filters out palm
// contacts based on per-slot WIDTH_MAJOR / WIDTH_MINOR signals, and re-emits
// a cleaned event stream through a uinput virtual device. libinput sees only
// the virtual device (the source is grabbed exclusively).
//
// Algorithm (per slot, sticky from contact start to release):
//   Pending = no events forwarded yet
//     -> Palm   if WIDTH_MAJOR > WMAJ_PALM_THRESHOLD
//     -> Finger if WIDTH_MINOR >= WMIN_FINGER_THRESHOLD
//   Finger  = events forwarded
//     -> Palm   if WIDTH_MAJOR > WMAJ_PALM_THRESHOLD (late palm; cancel via TID=-1)
//   Palm    = sticky, all events dropped

use anyhow::{Context, Result};
use evdev::uinput::VirtualDevice;
use evdev::{
    AttributeSet, BusType, Device, EventType, InputEvent, InputId, KeyCode, PropType,
    UinputAbsSetup,
};
use std::env;

// Tunable thresholds. Override with env: PF_WMAJ_PALM, PF_WMIN_FINGER, PF_PENDING_TIMEOUT_MS.
const DEFAULT_WMAJ_PALM: i32 = 2200;
const DEFAULT_WMIN_FINGER: i32 = 1300;
const DEFAULT_PENDING_TIMEOUT_MS: u64 = 500;

const NUM_SLOTS: usize = 16;

// Raw evdev codes
const ABS_X: u16 = 0x00;
const ABS_Y: u16 = 0x01;
const ABS_MT_SLOT: u16 = 0x2f;
const ABS_MT_TOUCH_MAJOR: u16 = 0x30;
const ABS_MT_TOUCH_MINOR: u16 = 0x31;
const ABS_MT_WIDTH_MAJOR: u16 = 0x32;
const ABS_MT_WIDTH_MINOR: u16 = 0x33;
const ABS_MT_ORIENTATION: u16 = 0x34;
const ABS_MT_POSITION_X: u16 = 0x35;
const ABS_MT_POSITION_Y: u16 = 0x36;
const ABS_MT_TRACKING_ID: u16 = 0x39;

const BTN_TOUCH: u16 = 0x14a;
const BTN_TOOL_FINGER: u16 = 0x145;
const BTN_TOOL_QUINTTAP: u16 = 0x148;
const BTN_TOOL_DOUBLETAP: u16 = 0x14d;
const BTN_TOOL_TRIPLETAP: u16 = 0x14e;
const BTN_TOOL_QUADTAP: u16 = 0x14f;

const SYN_REPORT: u16 = 0;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum Class {
    Empty,
    Pending,
    Finger,
    Palm,
}

#[derive(Clone, Debug)]
struct Slot {
    class: Class,
    tracking_id: i32,
    started_at_frame: u64,
    touch_major: i32,
    touch_minor: i32,
    width_major: i32,
    width_minor: i32,
    orientation: i32,
    pos_x: i32,
    pos_y: i32,
    // True for the frame in which the slot transitioned Pending -> Finger.
    just_promoted: bool,
    // True for the frame in which the slot transitioned Finger -> Palm.
    just_cancelled: bool,
    // Whether libinput has been told about this contact via a TRACKING_ID start.
    emitted_open: bool,
}

impl Slot {
    fn empty() -> Self {
        Self {
            class: Class::Empty,
            tracking_id: -1,
            started_at_frame: 0,
            touch_major: 0,
            touch_minor: 0,
            width_major: 0,
            width_minor: 0,
            orientation: 0,
            pos_x: 0,
            pos_y: 0,
            just_promoted: false,
            just_cancelled: false,
            emitted_open: false,
        }
    }
}

struct Filter {
    slots: Vec<Slot>,
    current_slot: usize,
    frame_count: u64,
    wmaj_palm: i32,
    wmin_finger: i32,
    pending_timeout_frames: u64, // approximate; ~125Hz so 8ms/frame
    // Buffer for the current frame's events (between SYN_REPORTs).
    frame_events: Vec<InputEvent>,
    // Slots touched by the current frame.
    touched_this_frame: Vec<u16>,
    // Saw a TID-end for these slots in this frame (to defer reset until after emit).
    closed_this_frame: Vec<u16>,
}

impl Filter {
    fn new(wmaj_palm: i32, wmin_finger: i32, pending_timeout_ms: u64) -> Self {
        // Apple MTP reports at ~125 Hz (8ms/frame). Convert ms to frames conservatively.
        let pending_timeout_frames = pending_timeout_ms / 8 + 1;
        Self {
            slots: vec![Slot::empty(); NUM_SLOTS],
            current_slot: 0,
            frame_count: 0,
            wmaj_palm,
            wmin_finger,
            pending_timeout_frames,
            frame_events: Vec::with_capacity(64),
            touched_this_frame: Vec::with_capacity(8),
            closed_this_frame: Vec::with_capacity(8),
        }
    }

    fn mark_touched(&mut self, slot: u16) {
        if !self.touched_this_frame.contains(&slot) {
            self.touched_this_frame.push(slot);
        }
    }

    // Process a single event. Returns true if it was a SYN_REPORT (caller should flush).
    fn ingest(&mut self, ev: &InputEvent) -> bool {
        match ev.event_type() {
            EventType::SYNCHRONIZATION => ev.code() == SYN_REPORT,
            EventType::ABSOLUTE => {
                let code = ev.code();
                let val = ev.value();
                match code {
                    ABS_MT_SLOT => {
                        self.current_slot = val as usize;
                    }
                    ABS_MT_TRACKING_ID => {
                        let s = self.current_slot;
                        if val == -1 {
                            // Mark for close; preserve state until emit phase.
                            if !self.closed_this_frame.contains(&(s as u16)) {
                                self.closed_this_frame.push(s as u16);
                            }
                            self.mark_touched(s as u16);
                        } else {
                            // New contact starting.
                            let mut fresh = Slot::empty();
                            fresh.class = Class::Pending;
                            fresh.tracking_id = val;
                            fresh.started_at_frame = self.frame_count;
                            self.slots[s] = fresh;
                            self.mark_touched(s as u16);
                        }
                    }
                    ABS_MT_TOUCH_MAJOR => {
                        self.slots[self.current_slot].touch_major = val;
                        self.mark_touched(self.current_slot as u16);
                    }
                    ABS_MT_TOUCH_MINOR => {
                        self.slots[self.current_slot].touch_minor = val;
                        self.mark_touched(self.current_slot as u16);
                    }
                    ABS_MT_WIDTH_MAJOR => {
                        self.slots[self.current_slot].width_major = val;
                        self.mark_touched(self.current_slot as u16);
                    }
                    ABS_MT_WIDTH_MINOR => {
                        self.slots[self.current_slot].width_minor = val;
                        self.mark_touched(self.current_slot as u16);
                    }
                    ABS_MT_ORIENTATION => {
                        self.slots[self.current_slot].orientation = val;
                        self.mark_touched(self.current_slot as u16);
                    }
                    ABS_MT_POSITION_X => {
                        self.slots[self.current_slot].pos_x = val;
                        self.mark_touched(self.current_slot as u16);
                    }
                    ABS_MT_POSITION_Y => {
                        self.slots[self.current_slot].pos_y = val;
                        self.mark_touched(self.current_slot as u16);
                    }
                    ABS_X | ABS_Y => { /* regenerated below */ }
                    _ => {
                        // Unknown ABS — pass through.
                        self.frame_events.push(*ev);
                    }
                }
                false
            }
            EventType::KEY => {
                let code = ev.code();
                match code {
                    BTN_TOUCH | BTN_TOOL_FINGER | BTN_TOOL_DOUBLETAP | BTN_TOOL_TRIPLETAP
                    | BTN_TOOL_QUADTAP | BTN_TOOL_QUINTTAP => { /* regenerated */ }
                    _ => {
                        // BTN_LEFT etc — pass through.
                        self.frame_events.push(*ev);
                    }
                }
                false
            }
            _ => {
                self.frame_events.push(*ev);
                false
            }
        }
    }

    // Apply classification transitions and produce the output event stream.
    fn emit_frame(&mut self, vd: &mut VirtualDevice) -> Result<()> {
        // Phase 1: classify Pending slots and detect late-palm Finger -> Palm transitions.
        for s_idx in &self.touched_this_frame {
            let s = &mut self.slots[*s_idx as usize];
            s.just_promoted = false;
            s.just_cancelled = false;
            match s.class {
                Class::Pending => {
                    if s.width_major > self.wmaj_palm {
                        s.class = Class::Palm;
                    } else if s.width_minor >= self.wmin_finger {
                        s.class = Class::Finger;
                        s.just_promoted = true;
                    } else if self.frame_count.saturating_sub(s.started_at_frame)
                        >= self.pending_timeout_frames
                    {
                        s.class = Class::Palm;
                    }
                }
                Class::Finger => {
                    if s.width_major > self.wmaj_palm {
                        s.class = Class::Palm;
                        s.just_cancelled = true;
                    }
                }
                _ => {}
            }
        }

        // Phase 2: emit slot events (in slot index order, with explicit MT_SLOT switches).
        let mut out: Vec<InputEvent> = Vec::with_capacity(64);
        let mut emitted_slot: Option<u16> = None;
        let mut touched_sorted = self.touched_this_frame.clone();
        touched_sorted.sort();

        for s_idx in &touched_sorted {
            let closing = self.closed_this_frame.contains(s_idx);
            let s = &self.slots[*s_idx as usize];
            // Decide what (if anything) to emit for this slot.
            let emit_state = match s.class {
                Class::Finger => true,
                Class::Palm => {
                    // If it had been emitted to libinput before, we owe a close.
                    s.emitted_open && closing || s.just_cancelled
                }
                _ => false,
            };
            if !emit_state {
                continue;
            }

            if emitted_slot != Some(*s_idx) {
                out.push(abs(ABS_MT_SLOT, *s_idx as i32));
                emitted_slot = Some(*s_idx);
            }

            match s.class {
                Class::Finger => {
                    if !s.emitted_open || s.just_promoted {
                        // First time libinput sees this contact: emit TRACKING_ID start
                        // and a full state snapshot.
                        out.push(abs(ABS_MT_TRACKING_ID, s.tracking_id));
                    }
                    out.push(abs(ABS_MT_TOUCH_MAJOR, s.touch_major));
                    out.push(abs(ABS_MT_TOUCH_MINOR, s.touch_minor));
                    out.push(abs(ABS_MT_WIDTH_MAJOR, s.width_major));
                    out.push(abs(ABS_MT_WIDTH_MINOR, s.width_minor));
                    out.push(abs(ABS_MT_ORIENTATION, s.orientation));
                    out.push(abs(ABS_MT_POSITION_X, s.pos_x));
                    out.push(abs(ABS_MT_POSITION_Y, s.pos_y));
                    if closing {
                        out.push(abs(ABS_MT_TRACKING_ID, -1));
                    }
                }
                Class::Palm => {
                    // Late-cancelled or close-out for previously-Finger contact.
                    out.push(abs(ABS_MT_TRACKING_ID, -1));
                }
                _ => unreachable!(),
            }
        }

        // Phase 3: post-emit bookkeeping (mark slots opened).
        for s_idx in &touched_sorted {
            let s = &mut self.slots[*s_idx as usize];
            if s.class == Class::Finger {
                s.emitted_open = true;
            }
        }

        // Phase 4: regenerate aggregate events. Count active Finger slots, find primary.
        let mut finger_count: usize = 0;
        let mut primary: Option<usize> = None;
        for (i, s) in self.slots.iter().enumerate() {
            if s.class == Class::Finger {
                finger_count += 1;
                if primary.is_none() {
                    primary = Some(i);
                }
            }
        }

        out.push(key(BTN_TOUCH, if finger_count >= 1 { 1 } else { 0 }));
        out.push(key(BTN_TOOL_FINGER, if finger_count == 1 { 1 } else { 0 }));
        out.push(key(BTN_TOOL_DOUBLETAP, if finger_count == 2 { 1 } else { 0 }));
        out.push(key(BTN_TOOL_TRIPLETAP, if finger_count == 3 { 1 } else { 0 }));
        out.push(key(BTN_TOOL_QUADTAP, if finger_count == 4 { 1 } else { 0 }));
        out.push(key(BTN_TOOL_QUINTTAP, if finger_count >= 5 { 1 } else { 0 }));

        if let Some(p) = primary {
            out.push(abs(ABS_X, self.slots[p].pos_x));
            out.push(abs(ABS_Y, self.slots[p].pos_y));
        }

        // Forward any non-slot events captured this frame (e.g. BTN_LEFT).
        for ev in &self.frame_events {
            out.push(*ev);
        }

        // Reset closed slots to Empty now that emits are queued.
        for s_idx in &self.closed_this_frame {
            self.slots[*s_idx as usize] = Slot::empty();
        }

        // Terminate the frame.
        out.push(InputEvent::new(EventType::SYNCHRONIZATION.0, SYN_REPORT, 0));

        vd.emit(&out)?;

        self.frame_events.clear();
        self.touched_this_frame.clear();
        self.closed_this_frame.clear();
        self.frame_count = self.frame_count.wrapping_add(1);
        Ok(())
    }
}

fn abs(code: u16, val: i32) -> InputEvent {
    InputEvent::new(EventType::ABSOLUTE.0, code, val)
}
fn key(code: u16, val: i32) -> InputEvent {
    InputEvent::new(EventType::KEY.0, code, val)
}

fn build_virtual_device(src: &Device) -> Result<VirtualDevice> {
    let id = src.input_id();
    let mut builder = VirtualDevice::builder()?
        .name("Apple MTP multi-touch (palm-filtered)")
        .input_id(InputId::new(
            BusType::BUS_VIRTUAL,
            id.vendor(),
            id.product(),
            id.version(),
        ));

    if let Some(keys) = src.supported_keys() {
        let mut k = AttributeSet::<KeyCode>::new();
        for kc in keys.iter() {
            k.insert(kc);
        }
        builder = builder.with_keys(&k)?;
    }

    {
        let props = src.properties();
        let mut p = AttributeSet::<PropType>::new();
        for pp in props.iter() {
            p.insert(pp);
        }
        builder = builder.with_properties(&p)?;
    }

    if let Some(axes) = src.supported_absolute_axes() {
        for axis in axes.iter() {
            let info = src.get_absinfo()?.find(|(a, _)| a.0 == axis.0).map(|(_, i)| i);
            if let Some(info) = info {
                let setup = UinputAbsSetup::new(axis, info);
                builder = builder.with_absolute_axis(&setup)?;
            }
        }
    }

    Ok(builder.build()?)
}

fn main() -> Result<()> {
    let source_path = env::args()
        .nth(1)
        .unwrap_or_else(|| "/dev/input/event2".to_string());

    let wmaj_palm: i32 = env::var("PF_WMAJ_PALM")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(DEFAULT_WMAJ_PALM);
    let wmin_finger: i32 = env::var("PF_WMIN_FINGER")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(DEFAULT_WMIN_FINGER);
    let pending_timeout_ms: u64 = env::var("PF_PENDING_TIMEOUT_MS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(DEFAULT_PENDING_TIMEOUT_MS);

    eprintln!(
        "palm-filter: source={} wmaj_palm={} wmin_finger={} pending_timeout_ms={}",
        source_path, wmaj_palm, wmin_finger, pending_timeout_ms
    );

    let mut src = Device::open(&source_path).with_context(|| format!("opening {}", source_path))?;
    eprintln!("source: {:?}", src.name());

    let mut vd = build_virtual_device(&src).context("building virtual device")?;
    // Brief pause so udev/libinput can pick up the new device before we start.
    std::thread::sleep(std::time::Duration::from_millis(150));
    eprintln!("virtual device created");

    src.grab().context("grabbing source device")?;
    eprintln!("grabbed source; entering event loop");

    let mut filter = Filter::new(wmaj_palm, wmin_finger, pending_timeout_ms);

    loop {
        let events = src.fetch_events()?;
        for ev in events {
            let is_syn = filter.ingest(&ev);
            if is_syn {
                filter.emit_frame(&mut vd)?;
            }
        }
    }
}
