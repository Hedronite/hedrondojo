use crate::os::{fill_bg, App};
use crate::widgets::theme;
use ratatui::buffer::Buffer;
use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::{Paragraph, Widget};
pub struct Attach<'a> { pub app: &'a App }
impl Widget for &Attach<'_> {
    fn render(self, area: Rect, buf: &mut Buffer) {
        fill_bg(area, buf);
        let _ = self.app;
        Paragraph::new(vec![
            Line::from(Span::styled("ATTACH", theme::patina())),
            Line::from(""),
            Line::from(Span::styled("this folder is a Hedronite lab", theme::text())),
            Line::from(Span::styled("open it, then  @hedronite-lab", theme::text())),
            Line::from(""),
            Line::from(Span::styled("vault/     workshop notes", theme::muted())),
            Line::from(Span::styled("lessons    https://hedronite.com", theme::muted())),
            Line::from(Span::styled("tomes      checklists/tomes.md", theme::muted())),
        ]).render(area, buf);
    }
}
