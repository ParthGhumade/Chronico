import sqlite3
import json
import time
from typing import Dict, List, Optional, Any

def get_connection(db_path: str = "chronico_local.db") -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn

def init_db(db_path: str = "chronico_local.db") -> None:
    """Initializes SQLite database tables according to local_db.md schema."""
    with get_connection(db_path) as conn:
        cursor = conn.cursor()
        
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS events (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            event_date INTEGER NOT NULL,
            venue TEXT,
            category TEXT,
            ramble TEXT,
            report TEXT,
            pdf_path TEXT,
            is_dirty INTEGER DEFAULT 0,
            created_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
            updated_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
            last_synced_at INTEGER
        );
        """)

        cursor.execute("""
        CREATE TABLE IF NOT EXISTS photos (
            id TEXT PRIMARY KEY,
            event_id TEXT NOT NULL,
            path TEXT NOT NULL,
            created_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
            FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
        );
        """)

        cursor.execute("""
        CREATE TABLE IF NOT EXISTS presets (
            key TEXT PRIMARY KEY,
            value TEXT
        );
        """)
        conn.commit()

# --- Events Operations ---

def upsert_event(event_data: Dict[str, Any], photos: Optional[List[str]] = None, db_path: str = "chronico_local.db") -> None:
    now_ms = int(time.time() * 1000)
    with get_connection(db_path) as conn:
        cursor = conn.cursor()
        cursor.execute("""
        INSERT INTO events (id, title, event_date, venue, category, ramble, report, pdf_path, is_dirty, created_at, updated_at, last_synced_at)
        VALUES (:id, :title, :event_date, :venue, :category, :ramble, :report, :pdf_path, :is_dirty, :created_at, :updated_at, :last_synced_at)
        ON CONFLICT(id) DO UPDATE SET
            title=excluded.title,
            event_date=excluded.event_date,
            venue=excluded.venue,
            category=excluded.category,
            ramble=excluded.ramble,
            report=excluded.report,
            pdf_path=excluded.pdf_path,
            is_dirty=excluded.is_dirty,
            updated_at=excluded.updated_at,
            last_synced_at=excluded.last_synced_at;
        """, {
            "id": event_data["id"],
            "title": event_data.get("title", ""),
            "event_date": event_data.get("event_date", now_ms),
            "venue": event_data.get("venue"),
            "category": event_data.get("category"),
            "ramble": event_data.get("ramble"),
            "report": json.dumps(event_data["report"]) if isinstance(event_data.get("report"), dict) else event_data.get("report"),
            "pdf_path": event_data.get("pdf_path"),
            "is_dirty": event_data.get("is_dirty", 0),
            "created_at": event_data.get("created_at", now_ms),
            "updated_at": event_data.get("updated_at", now_ms),
            "last_synced_at": event_data.get("last_synced_at"),
        })

        if photos is not None:
            cursor.execute("DELETE FROM photos WHERE event_id = ?;", (event_data["id"],))
            for idx, photo_path in enumerate(photos):
                cursor.execute("""
                INSERT INTO photos (id, event_id, path, created_at)
                VALUES (?, ?, ?, ?);
                """, (f"{event_data['id']}_photo_{idx}", event_data["id"], photo_path, now_ms))

        conn.commit()

def get_events(db_path: str = "chronico_local.db") -> List[Dict[str, Any]]:
    with get_connection(db_path) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM events ORDER BY event_date DESC;")
        rows = cursor.fetchall()
        result = []
        for row in rows:
            item = dict(row)
            cursor.execute("SELECT path FROM photos WHERE event_id = ?;", (item["id"],))
            item["photos"] = [p["path"] for p in cursor.fetchall()]
            result.append(item)
        return result

def get_event_by_id(event_id: str, db_path: str = "chronico_local.db") -> Optional[Dict[str, Any]]:
    with get_connection(db_path) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM events WHERE id = ?;", (event_id,))
        row = cursor.fetchone()
        if not row:
            return None
        item = dict(row)
        cursor.execute("SELECT path FROM photos WHERE event_id = ?;", (event_id,))
        item["photos"] = [p["path"] for p in cursor.fetchall()]
        return item

def delete_event(event_id: str, db_path: str = "chronico_local.db") -> None:
    with get_connection(db_path) as conn:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM events WHERE id = ?;", (event_id,))
        conn.commit()

# --- Presets Operations ---

def set_preset(key: str, value: str, db_path: str = "chronico_local.db") -> None:
    with get_connection(db_path) as conn:
        cursor = conn.cursor()
        cursor.execute("""
        INSERT INTO presets (key, value)
        VALUES (?, ?)
        ON CONFLICT(key) DO UPDATE SET value=excluded.value;
        """, (key, value))
        conn.commit()

def get_preset(key: str, db_path: str = "chronico_local.db") -> Optional[str]:
    with get_connection(db_path) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT value FROM presets WHERE key = ?;", (key,))
        row = cursor.fetchone()
        return row["value"] if row else None

def get_all_presets(db_path: str = "chronico_local.db") -> Dict[str, str]:
    with get_connection(db_path) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT key, value FROM presets;")
        rows = cursor.fetchall()
        return {row["key"]: row["value"] for row in rows}

def delete_preset(key: str, db_path: str = "chronico_local.db") -> None:
    with get_connection(db_path) as conn:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM presets WHERE key = ?;", (key,))
        conn.commit()

if __name__ == "__main__":
    init_db()
    print("Database initialized successfully.")
