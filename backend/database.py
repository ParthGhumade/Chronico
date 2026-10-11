import logging
import sqlite3
from pathlib import Path
from typing import Any

from backend.config import DB_PATH

logger = logging.getLogger(__name__)


def get_db_connection(db_path: Path | str | None = None) -> sqlite3.Connection:
    """
    Returns a configured SQLite connection to the local database file.
    """
    resolved_path = Path(db_path or DB_PATH)
    resolved_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(resolved_path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode = WAL;")
    return conn


def init_db(db_path: Path | str | None = None) -> None:
    """
    Initializes the SQLite schema on this server.
    Creates the 'config' key-value store table if it does not already exist.
    """
    with get_db_connection(db_path) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS config (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """
        )
        # Also create presets table/alias for schema completeness
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS presets (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );
            """
        )
        conn.commit()
    logger.info(f"Database initialized at {db_path or DB_PATH}")


def set_config_value(key: str, value: str, db_path: Path | str | None = None) -> None:
    """
    Inserts or updates a single key-value pair in the database.
    """
    init_db(db_path)
    with get_db_connection(db_path) as conn:
        conn.execute(
            """
            INSERT INTO config (key, value, updated_at)
            VALUES (?, ?, CURRENT_TIMESTAMP)
            ON CONFLICT(key) DO UPDATE SET
                value = excluded.value,
                updated_at = CURRENT_TIMESTAMP;
            """,
            (key.strip(), str(value).strip()),
        )
        conn.commit()


def set_configs(items: dict[str, Any], db_path: Path | str | None = None) -> dict[str, str]:
    """
    Inserts or updates multiple key-value pairs in the database.
    Returns the complete updated config dictionary.
    """
    init_db(db_path)
    with get_db_connection(db_path) as conn:
        for k, v in items.items():
            if k is not None and v is not None:
                conn.execute(
                    """
                    INSERT INTO config (key, value, updated_at)
                    VALUES (?, ?, CURRENT_TIMESTAMP)
                    ON CONFLICT(key) DO UPDATE SET
                        value = excluded.value,
                        updated_at = CURRENT_TIMESTAMP;
                    """,
                    (str(k).strip(), str(v).strip()),
                )
        conn.commit()
    return get_all_configs(db_path)


def get_config_value(key: str, db_path: Path | str | None = None) -> str | None:
    """
    Retrieves the value for a specific key from the database.
    """
    init_db(db_path)
    with get_db_connection(db_path) as conn:
        cursor = conn.execute("SELECT value FROM config WHERE key = ?", (key.strip(),))
        row = cursor.fetchone()
        return row["value"] if row else None


def get_all_configs(db_path: Path | str | None = None) -> dict[str, str]:
    """
    Retrieves all stored key-value pairs from the database.
    """
    init_db(db_path)
    with get_db_connection(db_path) as conn:
        cursor = conn.execute("SELECT key, value FROM config ORDER BY key ASC")
        rows = cursor.fetchall()
        return {row["key"]: row["value"] for row in rows}


def delete_config_key(key: str, db_path: Path | str | None = None) -> bool:
    """
    Deletes a specific key from the database.
    """
    init_db(db_path)
    with get_db_connection(db_path) as conn:
        cursor = conn.execute("DELETE FROM config WHERE key = ?", (key.strip(),))
        conn.commit()
        return cursor.rowcount > 0


def clear_all_configs(db_path: Path | str | None = None) -> None:
    """
    Clears all key-value pairs from the database.
    """
    init_db(db_path)
    with get_db_connection(db_path) as conn:
        conn.execute("DELETE FROM config")
        conn.commit()


def inject_config_into_text(narration: str, configs: dict[str, str] | None = None) -> str:
    """
    Injects stored or provided key-value configuration into the narration text
    before passing it to the first layer of the agent (Writer / Extractor).

    1. Replaces any `{key}` template placeholders found in narration with actual values.
    2. Prepends an explicit, structured Devanagari institutional context block so the
       agent preserves these facts without hallucinating.
    """
    active_configs = configs if configs is not None else get_all_configs()
    if not active_configs:
        return narration

    processed_narration = narration

    # 1. Substitute any placeholder patterns {key}
    for k, v in active_configs.items():
        placeholder = f"{{{k}}}"
        if placeholder in processed_narration:
            processed_narration = processed_narration.replace(placeholder, v)

    # If the text already has the injection header, avoid duplicate block prepending
    if "पूर्वतयारी संदर्भ व संस्था तपशील" in processed_narration:
        return processed_narration

    # 2. Build structured configuration context block
    config_lines = [f"- {k}: {v}" for k, v in sorted(active_configs.items()) if v]
    if not config_lines:
        return processed_narration

    config_header = (
        "【 पूर्वतयारी संदर्भ व संस्था तपशील (School & Institutional Configuration) 】\n"
        + "\n".join(config_lines)
    )

    return f"{config_header}\n\n【 कार्यक्रमाचे प्रत्यक्ष वर्णन (Event Narration) 】\n{processed_narration.strip()}"
