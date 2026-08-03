# Local Database Schema (SQLite)

This document defines the SQLite schema used for local data persistence in Chronico.

---

## 1. Tables Overview

### `events`
Stores main event records, raw narration (`ramble`), generated report text, PDF paths, and synchronization metadata.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | Unique identifier (UUID v4) |
| `title` | `TEXT` | `NOT NULL` | Event title |
| `event_date` | `INTEGER` | `NOT NULL` | Event timestamp (Unix epoch in milliseconds or seconds) |
| `venue` | `TEXT` | | Location / venue of the event |
| `category` | `TEXT` | | Category of the event |
| `ramble` | `TEXT` | | Raw user narration / text notes |
| `report` | `TEXT` | | Final generated report content |
| `pdf_path` | `TEXT` | | Local path to generated PDF report |
| `is_dirty` | `INTEGER` | `DEFAULT 0` | Sync status flag (1 = unsynced changes, 0 = synced) |
| `created_at` | `INTEGER` | `DEFAULT (unixepoch())` | Record creation timestamp (Unix epoch) |
| `updated_at` | `INTEGER` | `DEFAULT (unixepoch())` | Last updated timestamp (Unix epoch) |
| `last_synced_at` | `INTEGER` | | Last cloud synchronization timestamp (Unix epoch) |

---

### `photos`
Stores photo metadata attached to specific events.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | Unique identifier (UUID v4) |
| `event_id` | `TEXT` | `NOT NULL`, `FOREIGN KEY` | Reference to `events(id)` |
| `path` | `TEXT` | `NOT NULL` | Local filesystem path to the photo |
| `created_at` | `INTEGER` | `DEFAULT (unixepoch())` | Photo record creation timestamp (Unix epoch) |

---

### `presets`
Key-value store for application configuration and school settings.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `key` | `TEXT` | `PRIMARY KEY` | Setting key (e.g., `school_name`, `principal`) |
| `value` | `TEXT` | | Setting value |

---

## 2. SQL DDL Statements

```sql
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
    created_at INTEGER DEFAULT (unixepoch()),
    updated_at INTEGER DEFAULT (unixepoch()),
    last_synced_at INTEGER
);

CREATE TABLE IF NOT EXISTS photos (
    id TEXT PRIMARY KEY,
    event_id TEXT NOT NULL,
    path TEXT NOT NULL,
    created_at INTEGER DEFAULT (unixepoch()),
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS presets (
    key TEXT PRIMARY KEY,
    value TEXT
);
```


