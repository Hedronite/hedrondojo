mod consoles; mod kernel; mod os; mod widgets;
use crossterm::event::{self, Event, KeyEventKind};
use crossterm::execute;
use crossterm::terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen};
use os::{App, Console};
use ratatui::backend::{CrosstermBackend, TestBackend};
use ratatui::Terminal;
use std::io::{self, stdout};
use std::time::Duration;

fn main() -> io::Result<()> {
    if std::env::args().any(|a| a == "--smoke") { return smoke_home(); }
    let mut app = App::new();
    enable_raw_mode()?;
    execute!(stdout(), EnterAlternateScreen)?;
    let mut terminal = Terminal::new(CrosstermBackend::new(stdout()))?;
    terminal.draw(|f| app.draw(f))?;
    app.step_boot();
    let result = run_loop(&mut terminal, &mut app);
    disable_raw_mode()?;
    execute!(stdout(), LeaveAlternateScreen)?;
    result
}

fn run_loop<B: ratatui::backend::Backend>(terminal: &mut Terminal<B>, app: &mut App) -> io::Result<()> {
    loop {
        app.tick();
        terminal.draw(|f| app.draw(f))?;
        if event::poll(Duration::from_millis(80))? {
            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Press { app.on_key(key); }
            }
        }
        if app.should_quit() { break; }
    }
    Ok(())
}

fn smoke_home() -> io::Result<()> {
    let mut app = App::new();
    app.step_boot();
    if app.console != Console::Home {
        return Err(io::Error::new(io::ErrorKind::Other, format!("smoke: expected Home after Boot, got {:?}", app.console)));
    }
    let mut terminal = Terminal::new(TestBackend::new(120, 36))?;
    terminal.draw(|f| app.draw(f))?;
    Ok(())
}
