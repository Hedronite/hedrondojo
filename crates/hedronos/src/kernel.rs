use serde::Deserialize;
use std::env;
use std::io::{Read, Write};
use std::net::TcpStream;
use std::time::Duration;

#[derive(Debug, Clone, Default, Deserialize)]
pub struct Ready {
    pub ok: bool,
    #[serde(default)]
    pub version: String,
    #[serde(default)]
    pub lattice_rows: Option<u64>,
    #[serde(default)]
    pub feed_fetched_at: Option<String>,
    #[serde(default)]
    pub fetched_at: Option<String>,
    #[serde(default)]
    pub error: Option<String>,
}

impl Ready {
    pub fn freshness(&self) -> Option<&str> {
        self.feed_fetched_at.as_deref().or(self.fetched_at.as_deref()).filter(|s| !s.is_empty())
    }
    pub fn rows(&self) -> u64 { self.lattice_rows.unwrap_or(0) }
}

pub fn kernel_base() -> String {
    env::var("HEDRON_KERNEL").unwrap_or_else(|_| "http://127.0.0.1:18800".into())
}

fn hostport(base: &str) -> &str {
    base.trim_start_matches("http://").trim_end_matches('/')
}

fn http_json(method: &str, path: &str, body: Option<&[u8]>) -> Result<(u16, String), String> {
    let base = kernel_base();
    let hp = hostport(&base);
    let mut stream = TcpStream::connect(hp).map_err(|e| e.to_string())?;
    stream.set_read_timeout(Some(Duration::from_millis(800))).ok();
    stream.set_write_timeout(Some(Duration::from_millis(800))).ok();
    let payload = body.unwrap_or(b"");
    let extra = if method == "POST" {
        format!("Content-Type: application/json\r\nContent-Length: {}\r\n", payload.len())
    } else {
        String::new()
    };
    let req = format!(
        "{method} {path} HTTP/1.1\r\nHost: 127.0.0.1\r\n{extra}Connection: close\r\n\r\n"
    );
    stream.write_all(req.as_bytes()).map_err(|e| e.to_string())?;
    if !payload.is_empty() {
        stream.write_all(payload).map_err(|e| e.to_string())?;
    }
    let mut buf = String::new();
    stream.read_to_string(&mut buf).map_err(|e| e.to_string())?;
    let (head, rest) = buf.split_once("\r\n\r\n").unwrap_or((buf.as_str(), ""));
    let status = head.split_whitespace().nth(1).and_then(|s| s.parse().ok()).unwrap_or(0);
    Ok((status, rest.trim().to_string()))
}

pub fn get_ready() -> Result<Ready, String> {
    let (status, body) = http_json("GET", "/ready", None)?;
    if status != 200 && status != 503 {
        return Err(format!("GET /ready {status}"));
    }
    serde_json::from_str(&body).map_err(|e| e.to_string())
}

#[allow(dead_code)]
pub fn get_lessons() -> Result<String, String> {
    let (status, body) = http_json("GET", "/lessons", None)?;
    if status != 200 {
        return Err(format!("GET /lessons {status}"));
    }
    Ok(body)
}

#[allow(dead_code)]
pub fn post_job(job: &str, lesson_id: Option<&str>) -> Result<(u16, String), String> {
    let payload = match lesson_id {
        Some(id) => format!(r#"{{"job":"{}","lesson_id":{}}}"#, job, serde_json::to_string(id).unwrap_or_else(|_| "null".into())),
        None => format!(r#"{{"job":"{}"}}"#, job),
    };
    http_json("POST", "/jobs", Some(payload.as_bytes()))
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn ready_503_same_keys() {
        let body = r#"{"ok":false,"version":"0.1","lattice_rows":null,"feed_fetched_at":null,"error":"lattice missing"}"#;
        let r: Ready = serde_json::from_str(body).unwrap();
        assert!(!r.ok);
        assert_eq!(r.version, "0.1");
        assert_eq!(r.rows(), 0);
        assert_eq!(r.error.as_deref(), Some("lattice missing"));
    }
}
