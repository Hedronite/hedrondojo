use crate::consoles::{Attach, Boot, Home, Lab, Lattice, Lessons, Tomes};
use crate::kernel::{self, Ready};
use crate::widgets::theme;
use crossterm::event::{KeyCode, KeyEvent};
use ratatui::layout::Rect;
use ratatui::Frame;
use std::time::Instant;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Console { Boot, Home, Lessons, Lab, Lattice, Tomes, Attach }

pub struct App {
    pub console: Console,
    pub ready: Option<Ready>,
    pub dead: bool,
    pub fault: Option<String>,
    pub bot_attached: bool,
    pub home_sel: Option<usize>,
    pub tick: u64,
    started: Instant,
    should_quit: bool,
}

impl App {
    pub fn new() -> Self {
        Self { console: Console::Boot, ready: None, dead: false, fault: None, bot_attached: false, home_sel: None, tick: 0, started: Instant::now(), should_quit: false }
    }
    pub fn should_quit(&self) -> bool { self.should_quit }
    pub fn lapis_tick(&self) -> f32 { self.lapis_tick_phased(0.0, 1.0) }
    pub fn lapis_tick_phased(&self, index: f32, n: f32) -> f32 {
        let span = if n <= 0.0 { 5.0 } else { 5.0 / n };
        let t = (self.started.elapsed().as_secs_f32() + index * span) % 5.0 / 5.0;
        if t < 0.618 { t / 0.618 } else { 1.0 - (t - 0.618) / 0.382 }
    }
    pub fn step_boot(&mut self) {
        match kernel::get_ready() {
            Ok(r) if r.ok => { self.ready = Some(r); self.dead = false; self.fault = None; self.console = Console::Home; }
            Ok(r) => { self.dead = true; self.fault = Some(r.error.unwrap_or_else(|| "kernel refused".into())); }
            Err(_) => { self.dead = true; self.fault = Some("runtime missing".into()); }
        }
    }
    pub fn on_key(&mut self, key: KeyEvent) {
        if self.console == Console::Boot && self.dead && key.code == KeyCode::Enter {
            self.dead = false; self.fault = None; self.step_boot(); return;
        }
        match key.code {
            KeyCode::Char('q') => self.should_quit = true,
            KeyCode::Esc | KeyCode::Char('h') => self.console = Console::Home,
            KeyCode::Char('l') => { self.home_sel = Some(0); self.console = Console::Lessons; }
            KeyCode::Char('r') => { self.home_sel = Some(1); self.console = Console::Lab; }
            KeyCode::Char('d') => { self.home_sel = Some(2); self.console = Console::Lattice; }
            KeyCode::Char('t') => { self.home_sel = Some(3); self.console = Console::Tomes; }
            KeyCode::Char('a') => { self.home_sel = Some(4); self.console = Console::Attach; }
            _ => {}
        }
    }
    pub fn tick(&mut self) { self.tick = self.tick.wrapping_add(1); }
    pub fn draw(&self, frame: &mut Frame) {
        let area = frame.size();
        frame.render_widget(ratatui::widgets::Clear, area);
        match self.console {
            Console::Boot => frame.render_widget(&Boot { app: self }, area),
            Console::Home => frame.render_widget(&Home { app: self }, area),
            Console::Lessons => frame.render_widget(&Lessons { app: self }, area),
            Console::Lab => frame.render_widget(&Lab { app: self }, area),
            Console::Lattice => frame.render_widget(&Lattice { app: self }, area),
            Console::Tomes => frame.render_widget(&Tomes { app: self }, area),
            Console::Attach => frame.render_widget(&Attach { app: self }, area),
        }
    }
}

pub fn fill_bg(area: Rect, buf: &mut ratatui::buffer::Buffer) {
    for y in area.y..area.y.saturating_add(area.height) {
        for x in area.x..area.x.saturating_add(area.width) {
            let cell = buf.get_mut(x, y);
            cell.set_bg(theme::BG);
            cell.set_fg(theme::TEXT);
            cell.set_symbol(" ");
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crossterm::event::{KeyCode, KeyEvent, KeyModifiers};
    #[test]
    fn boot_reaches_home() {
        let mut app = App::new();
        app.step_boot();
        assert_eq!(app.console, Console::Home);
        assert!(app.ready.as_ref().map(|r| r.ok).unwrap_or(false));
    }
    #[test]
    fn keys_route_rooms() {
        let mut app = App::new();
        app.console = Console::Home;
        app.on_key(KeyEvent::new(KeyCode::Char('l'), KeyModifiers::NONE));
        assert_eq!(app.console, Console::Lessons);
        app.on_key(KeyEvent::new(KeyCode::Esc, KeyModifiers::NONE));
        assert_eq!(app.console, Console::Home);
        assert_eq!(app.home_sel, Some(0));
    }
    #[test]
    fn home_starts_idle() {
        let app = App::new();
        assert_eq!(app.home_sel, None);
    }
}
