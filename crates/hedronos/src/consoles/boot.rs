use crate::os::{fill_bg, App};
use crate::widgets::theme;
use ratatui::buffer::Buffer;
use ratatui::layout::{Alignment, Rect};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Paragraph, Widget};

pub struct Boot<'a> { pub app: &'a App }

impl Widget for &Boot<'_> {
    fn render(self, area: Rect, buf: &mut Buffer) {
        fill_bg(area, buf);
        if self.app.dead {
            Paragraph::new(vec![
                Line::from(Span::styled("HEDRONOS", theme::copper())).alignment(Alignment::Center),
                Line::from(Span::styled("0.1", theme::patina())).alignment(Alignment::Center),
                Line::from(""),
                Line::from(Span::styled("HedronVM is powered off", theme::fire())).alignment(Alignment::Center),
                Line::from(""),
                Line::from(Span::styled("[ power on ]", theme::copper())).alignment(Alignment::Center),
                Line::from(Span::styled(self.app.fault.as_deref().unwrap_or(""), theme::muted())).alignment(Alignment::Center),
            ]).render(area, buf);
            return;
        }
        let gem = |i: f32| {
            if self.app.lapis_tick_phased(i, 3.0) > 0.35 {
                Span::styled("◆", theme::lapis())
            } else {
                Span::styled("◆", theme::muted())
            }
        };
        Paragraph::new(vec![
            Line::from(Span::styled("HEDRONOS", theme::copper())).alignment(Alignment::Center),
            Line::from(Span::styled("0.1", theme::patina())).alignment(Alignment::Center),
            Line::from(""),
            Line::from(Span::styled("student lab", theme::italic_regent())).alignment(Alignment::Center),
            Line::from(Span::styled("not the mesh", theme::italic_regent())).alignment(Alignment::Center),
            Line::from(""),
            Line::from(vec![gem(0.0), Span::raw("  "), Span::styled("runtime     ", theme::muted()), Span::styled("ok", theme::text())]).alignment(Alignment::Center),
            Line::from(vec![gem(1.0), Span::raw("  "), Span::styled("kernel      ", theme::muted()), Span::styled("waiting", theme::text())]).alignment(Alignment::Center),
            Line::from(vec![gem(2.0), Span::raw("  "), Span::styled("vault       ", theme::muted()), Span::styled("mounting", theme::text())]).alignment(Alignment::Center),
        ]).render(area, buf);
    }
}
