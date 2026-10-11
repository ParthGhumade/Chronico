import os

# Default model used across all agents if not overridden
DEFAULT_MODEL_NAME = os.getenv("GEMINI_MODEL", "gemini-flash-lite-latest")

# SQLite database path on this server
from pathlib import Path
DB_PATH = Path(os.getenv("CHRONICO_DB_PATH", Path(__file__).parent / "chronico.db"))

# Telegram Bot Token
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")


