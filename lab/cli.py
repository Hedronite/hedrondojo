"""lab fetch | status | query | serve

Kernel HTTP on :18800: GET /ready, GET /lessons, POST /jobs.
"""

from __future__ import annotations

import json
import os
import re
import sqlite3
import sys
import threading
import urllib.error
import urllib.request
from datetime import datetime, timezone
from html.parser import HTMLParser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

FEED = os.environ.get("LESSONS_FEED", "https://hedronite.com")
BIND = os.environ.get("LAB_BIND", "0.0.0.0")
PORT = int(os.environ.get("LAB_PORT", "18800"))
JOB_LOCK = threading.Lock()


class _Strip(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self._parts: list[str] = []

    def handle_data(self, data: str) -> None:
        self._parts.append(data)

    def text(self) -> str:
        return re.sub(r"\s+", " ", "".join(self._parts)).strip()


def strip_html(raw: str) -> str:
    if "<" not in raw:
        return raw
    parser = _Strip()
    try:
        parser.feed(raw)
        parser.close()
    except Exception:
        return re.sub(r"<[^>]+>", " ", raw)
    return parser.text()


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def db_path() -> Path:
    return Path(os.environ.get("LATTICE_DB", repo_root() / "seed" / "lattice.db"))


def connect() -> sqlite3.Connection:
    path = db_path()
    if not path.exists():
        raise FileNotFoundError(str(path))
    conn = sqlite3.connect(str(path))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def cmd_status() -> int:
    print(f"kernel: 127.0.0.1:{PORT}")
    print(f"lattice: {db_path()}")
    print(f"feed: {FEED}")
    return 0


def cmd_query() -> int:
    try:
        conn = connect()
    except FileNotFoundError:
        print("lattice missing", file=sys.stderr)
        return 1
    try:
        rows = conn.execute("SELECT title FROM documents ORDER BY id").fetchall()
    finally:
        conn.close()
    if not rows:
        print("(no documents)")
        return 0
    for row in rows:
        print(row["title"])
    return 0


def cmd_fetch() -> int:
    """Freshness ping only. Does not treat the marketing homepage as a lesson."""
    req = urllib.request.Request(FEED, headers={"User-Agent": "hedron-lab/0.1"})
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            resp.read(64)
    except urllib.error.URLError as exc:
        print(f"feed ping failed: {exc}", file=sys.stderr)
        return 1
    print(f"feed reachable: {FEED}")
    return 0


def _lattice_rows(conn: sqlite3.Connection) -> int:
    return int(conn.execute("SELECT COUNT(*) FROM documents").fetchone()[0])


def _feed_fetched_at(conn: sqlite3.Connection):
    row = conn.execute("SELECT MAX(fetched_at) FROM lessons").fetchone()
    if not row or not row[0]:
        return None
    return str(row[0])


def _lesson_body(row: sqlite3.Row) -> str:
    keys = row.keys()
    if "body_text" in keys and row["body_text"]:
        return strip_html(str(row["body_text"]))
    if "html" in keys and row["html"]:
        return strip_html(str(row["html"]))
    return ""


def _lessons_payload(conn: sqlite3.Connection) -> dict:
    cols = {r[1] for r in conn.execute("PRAGMA table_info(lessons)")}
    select = "id, url, title, fetched_at"
    if "body_text" in cols:
        select += ", body_text"
    if "html" in cols:
        select += ", html"
    if "cached" in cols:
        select += ", cached"
    order = "id" if "id" in cols else "url"
    rows = conn.execute(f"SELECT {select} FROM lessons ORDER BY {order}").fetchall()
    lessons = []
    for r in rows:
        keys = r.keys()
        lessons.append(
            {
                "id": r["id"] if "id" in keys else r["url"],
                "url": r["url"],
                "title": r["title"],
                "body_text": _lesson_body(r),
                "fetched_at": r["fetched_at"],
                "cached": bool(r["cached"]) if "cached" in keys else True,
            }
        )
    return {"lessons": lessons}


def _ready_payload() -> tuple[int, dict]:
    if not db_path().exists():
        return 503, {
            "ok": False,
            "version": "0.1",
            "lattice_rows": None,
            "feed_fetched_at": None,
            "error": "lattice missing",
        }
    try:
        conn = connect()
        try:
            payload = {
                "ok": True,
                "version": "0.1",
                "lattice_rows": _lattice_rows(conn),
                "feed_fetched_at": _feed_fetched_at(conn),
            }
        finally:
            conn.close()
    except sqlite3.Error as exc:
        return 503, {
            "ok": False,
            "version": "0.1",
            "lattice_rows": None,
            "feed_fetched_at": None,
            "error": str(exc),
        }
    return 200, payload


def _lookup_lesson(conn: sqlite3.Connection, lesson_id):
    if lesson_id is None or lesson_id == "":
        return None
    cols = {r[1] for r in conn.execute("PRAGMA table_info(lessons)")}
    if "id" in cols:
        row = conn.execute("SELECT * FROM lessons WHERE id = ?", (lesson_id,)).fetchone()
        if row:
            return row
    return conn.execute("SELECT * FROM lessons WHERE url = ?", (str(lesson_id),)).fetchone()


class KernelHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("kernel: " + (fmt % args) + "\n")

    def _send(self, code: int, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        path = self.path.split("?", 1)[0]
        if path == "/ready":
            code, payload = _ready_payload()
            self._send(code, payload)
            return
        if path == "/lessons":
            try:
                conn = connect()
            except FileNotFoundError:
                self._send(503, {
                    "ok": False,
                    "version": "0.1",
                    "lattice_rows": None,
                    "feed_fetched_at": None,
                    "error": "lattice missing",
                })
                return
            try:
                self._send(200, _lessons_payload(conn))
            finally:
                conn.close()
            return
        self._send(404, {"error": "not found"})

    def do_POST(self) -> None:
        path = self.path.split("?", 1)[0]
        if path != "/jobs":
            self._send(404, {"error": "not found"})
            return
        length = int(self.headers.get("Content-Length", "0") or 0)
        raw = self.rfile.read(length) if length else b"{}"
        try:
            body = json.loads(raw.decode("utf-8") or "{}")
        except json.JSONDecodeError:
            self._send(400, {"error": "invalid json"})
            return
        job = str(body.get("job") or "demo")
        lesson_id = body.get("lesson_id")
        if not JOB_LOCK.acquire(blocking=False):
            self._send(409, {"error": "busy"})
            return
        try:
            if job != "demo":
                self._send(404, {"error": "unknown job", "job": job})
                return
            try:
                conn = connect()
            except FileNotFoundError:
                self._send(
                    503,
                    {
                        "job": job,
                        "lesson_id": lesson_id,
                        "stdout": "",
                        "stderr": "lattice missing",
                        "exit": 1,
                    },
                )
                return
            try:
                lesson = None
                if lesson_id is not None and lesson_id != "":
                    lesson = _lookup_lesson(conn, lesson_id)
                    if lesson is None:
                        self._send(404, {"error": "unknown lesson", "lesson_id": lesson_id})
                        return
                n = _lattice_rows(conn)
                title = lesson["title"] if lesson is not None else "demo"
            finally:
                conn.close()
            stdout = f"lab demo ok\nlesson={title}\nlattice_rows={n}\n"
            self._send(
                200,
                {
                    "job": "demo",
                    "lesson_id": lesson_id if lesson is not None else None,
                    "stdout": stdout,
                    "stderr": "",
                    "exit": 0,
                },
            )
        finally:
            JOB_LOCK.release()


def cmd_serve() -> int:
    server = ThreadingHTTPServer((BIND, PORT), KernelHandler)
    print(f"kernel listening on {BIND}:{PORT}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    cmd = args[0] if args else "status"
    if cmd == "fetch":
        return cmd_fetch()
    if cmd == "status":
        return cmd_status()
    if cmd == "query":
        return cmd_query()
    if cmd == "serve":
        return cmd_serve()
    print("usage: python3 -m lab fetch|status|query|serve", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
