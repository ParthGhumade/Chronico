import logging
import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from backend.bot import create_telegram_bot_app
from backend.config import TELEGRAM_BOT_TOKEN

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger("chronico_bot")


def main() -> None:
    token = TELEGRAM_BOT_TOKEN or os.getenv("TELEGRAM_BOT_TOKEN")
    if not token or token.strip() == "your_telegram_bot_token_here":
        logger.error(
            "TELEGRAM_BOT_TOKEN is missing or not configured in backend/.env!\n"
            "Please create a bot via Telegram's @BotFather and add your token to backend/.env:\n"
            "TELEGRAM_BOT_TOKEN=123456789:ABCDefgh..."
        )
        sys.exit(1)

    gemini_key = os.getenv("GEMINI_API_KEY")
    if not gemini_key:
        logger.error("GEMINI_API_KEY is missing in backend/.env!")
        sys.exit(1)

    sarvam_key = os.getenv("SARVAM_API_KEY")
    if not sarvam_key:
        logger.error("SARVAM_API_KEY is missing in backend/.env!")
        sys.exit(1)

    logger.info("Initializing Chronico Telegram Bot application...")
    app = create_telegram_bot_app(token)

    logger.info("Chronico Telegram Bot is starting polling loop...")
    logger.info("Press Ctrl+C to stop.")
    app.run_polling(drop_pending_updates=True)


if __name__ == "__main__":
    main()
