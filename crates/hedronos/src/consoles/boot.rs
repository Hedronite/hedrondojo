use crate::os::{fill_bg, App, PostStatus};
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
        Paragraph::new(vec![
            Line::from(Span::styled("HEDRONOS", theme::copper())).alignment(Alignment::Center),
            Line::from(Span::styled("0.1", theme::patina())).alignment(Alignment::Center),
            Line::from(""),
            Line::from(Span::styled("student lab", theme::italic_regent())).alignment(Alignment::Center),
            Line::from(Span::styled("not the mesh", theme::italic_regent())).alignment(Alignment::Center),
            Line::from(""),
            post_line(0.0, "runtime", self.app.post_runtime, "ok", self.app),
            post_line(1.0, "kernel", self.app.post_kernel, kernel_label(self.app.post_kernel), self.app),
            post_line(2.0, "vault", self.app.post_vault, vault_label(self.app.post_vault), self.app),
        ]).render(area, buf);
    }
}

fn kernel_label(s: PostStatus) -> &'static str {
    match s {
        PostStatus::Ok => "ready",
        PostStatus::Fail => "fault",
        PostStatus::Waiting => "waiting",
    }
}

fn vault_label(s: PostStatus) -> &'static str {
    match s {
        PostStatus::Ok => "ok",
        PostStatus::Fail => "fault",
        PostStatus::Waiting => "mounting",
    }
}

fn post_line(index: f32, label: &'static str, status: PostStatus, value: &'static str, app: &App) -> Line<'static> {
    let gem = match status {
        PostStatus::Fail => Span::styled("◆", theme::fire()),
        PostStatus::Ok => Span::styled("◆", theme::lapis()),
        PostStatus::Waiting if app.lapis_tick_phased(index, 3.0) > 0.35 => Span::styled("◆", theme::lapis()),
        PostStatus::Waiting => Span::styled("◆", theme::muted()),
    };
    let value_style = match status {
        PostStatus::Fail => theme::fire(),
        _ => theme::text(),
    };
    Line::from(vec![
        gem,
        Span::raw("  "),
        Span::styled(format!("{label:<12}", label = label), theme::muted()),
        Span::styled(value, value_style),
    ]).alignment(Alignment::Center)
}
