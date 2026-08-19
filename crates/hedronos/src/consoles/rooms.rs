use crate::os::{fill_bg, App};
use crate::widgets::theme;
use ratatui::buffer::Buffer;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::style::Style;
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Paragraph, Widget};

pub(crate) fn room(title: &str, body: Vec<Line>, area: Rect, buf: &mut Buffer) {
    fill_bg(area, buf);
    let chunks = Layout::default().direction(Direction::Vertical)
        .constraints([Constraint::Min(3), Constraint::Length(1)]).split(area);
    let block = Block::default().borders(Borders::ALL).border_style(Style::default().fg(theme::COPPER))
        .style(Style::default().bg(theme::BG_FOCUS)).title(Span::styled(title, theme::copper()));
    let inner = block.inner(chunks[0]);
    block.render(chunks[0], buf);
    Paragraph::new(body).render(inner, buf);
    if chunks[0].width > 2 {
        let x = chunks[0].x.saturating_add(chunks[0].width.saturating_sub(2));
        buf.get_mut(x, chunks[0].y).set_fg(theme::LAPIS).set_symbol("◆");
    }
    Paragraph::new(Span::styled("esc / h  home    q  quit", theme::muted())).style(Style::default().bg(theme::BG)).render(chunks[1], buf);
}

pub struct Lessons<'a> { pub app: &'a App }
pub struct Lab<'a> { pub app: &'a App }
pub struct Lattice<'a> { pub app: &'a App }
pub struct Tomes<'a> { pub app: &'a App }

impl Widget for &Lessons<'_> {
    fn render(self, area: Rect, buf: &mut Buffer) {
        let _ = self.app;
        room("LESSONS", vec![Line::from(Span::styled("feed  https://hedronite.com", theme::regent()))], area, buf);
    }
}
impl Widget for &Lab<'_> {
    fn render(self, area: Rect, buf: &mut Buffer) {
        let _ = self.app;
        room("LAB", vec![Line::from(Span::styled("one job at a time", theme::text()))], area, buf);
    }
}
impl Widget for &Lattice<'_> {
    fn render(self, area: Rect, buf: &mut Buffer) {
        let n = self.app.ready.as_ref().map(|r| r.rows()).unwrap_or(0);
        room("LATTICE", vec![Line::from(Span::styled(format!("{n} demo rows"), theme::text()))], area, buf);
    }
}
impl Widget for &Tomes<'_> {
    fn render(self, area: Rect, buf: &mut Buffer) {
        let _ = self.app;
        room("TOMES", vec![Line::from(Span::styled("checklists/tomes.md — buy / borrow", theme::text()))], area, buf);
    }
}
