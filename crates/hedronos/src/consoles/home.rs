use crate::os::{fill_bg, App};
use crate::widgets::theme;
use ratatui::buffer::Buffer;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::style::{Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Paragraph, Widget};

pub struct Home<'a> { pub app: &'a App }
const ROOMS: [&str; 5] = ["LESSONS", "LAB", "LATTICE", "TOMES", "ATTACH"];

impl Widget for &Home<'_> {
    fn render(self, area: Rect, buf: &mut Buffer) {
        fill_bg(area, buf);
        let chunks = Layout::default().direction(Direction::Vertical)
            .constraints([Constraint::Min(3), Constraint::Length(1)]).split(area);
        let grid = chunks[0];
        if area.width >= 100 {
            let rows = Layout::default().direction(Direction::Vertical)
                .constraints([Constraint::Percentage(50), Constraint::Percentage(50)]).split(grid);
            let top = Layout::default().direction(Direction::Horizontal)
                .constraints([Constraint::Percentage(34), Constraint::Percentage(33), Constraint::Percentage(33)]).split(rows[0]);
            let bot = Layout::default().direction(Direction::Horizontal)
                .constraints([Constraint::Percentage(34), Constraint::Percentage(33), Constraint::Percentage(33)]).split(rows[1]);
            let cells = [top[0], top[1], top[2], bot[0], bot[1], bot[2]];
            for (i, name) in ROOMS.iter().enumerate() {
                tile(name, self.app.home_sel == Some(i), cells[i], buf);
            }
            mark(self.app, cells[5], buf);
        } else {
            let rows = Layout::default().direction(Direction::Vertical)
                .constraints([Constraint::Percentage(20); 5]).split(grid);
            for (i, name) in ROOMS.iter().enumerate() {
                tile(name, self.app.home_sel == Some(i), rows[i], buf);
            }
        }
        status_line(self.app, chunks[1], buf);
    }
}

fn tile(title: &str, focus: bool, area: Rect, buf: &mut Buffer) {
    let border = if focus { theme::COPPER } else { theme::BORDER };
    let fill = if focus { theme::BG_FOCUS } else { theme::BG_PANEL };
    let title_style = if focus { theme::copper() } else { theme::patina() };
    let block = Block::default().borders(Borders::ALL).border_style(Style::default().fg(border))
        .style(Style::default().bg(fill)).title(Span::styled(title, title_style));
    block.render(area, buf);
    if focus && area.width > 2 {
        let x = area.x.saturating_add(area.width.saturating_sub(2));
        buf.get_mut(x, area.y).set_fg(theme::LAPIS).set_symbol("◆");
    }
}

fn mark(app: &App, area: Rect, buf: &mut Buffer) {
    let block = Block::default().borders(Borders::ALL).border_style(Style::default().fg(theme::BORDER))
        .style(Style::default().bg(theme::BG_PANEL));
    let inner = block.inner(area);
    block.render(area, buf);
    let gem = if app.lapis_tick() > 0.5 { "◆" } else { "·" };
    Paragraph::new(Line::from(vec![Span::styled("H 0.1  ", theme::patina()), Span::styled(gem, theme::lapis())])).render(inner, buf);
}

fn status_line(app: &App, area: Rect, buf: &mut Buffer) {
    let ready = app.ready.as_ref();
    let ver = ready.map(|r| r.version.as_str()).filter(|s| !s.is_empty()).unwrap_or("HedronOS 0.1");
    let rows = ready.map(|r| r.rows()).unwrap_or(0);
    let (feed, fs) = match ready.and_then(|r| r.freshness()) {
        Some(ts) => (format!("feed {ts}"), theme::regent()),
        None => ("feed ·".into(), theme::muted()),
    };
    let attach = if app.bot_attached { Span::styled("attach yes", Style::default().fg(theme::AETHER)) } else { Span::styled("attach ·", theme::muted()) };
    Paragraph::new(Line::from(vec![
        Span::styled(format!("{ver}    "), theme::copper().add_modifier(Modifier::BOLD)),
        Span::styled(format!("lattice {rows}    "), theme::muted()),
        Span::styled(format!("{feed}    "), fs),
        attach, Span::raw("      "), Span::styled("h l r d t a q", theme::muted()),
    ])).style(Style::default().bg(theme::BG)).render(area, buf);
}
