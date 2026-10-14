import asyncio
import logging
import os
import shutil
import uuid
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from telegram import (
    KeyboardButton,
    ReplyKeyboardMarkup,
    ReplyKeyboardRemove,
    Update,
)
from telegram.constants import ParseMode
from telegram.ext import (
    Application,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

from backend.config import TELEGRAM_BOT_TOKEN
from backend.database import (
    delete_config_key,
    get_all_configs,
    init_db,
    set_config_value,
)
from backend.pipeline import cleanup_files, generate_report
from backend.stt_service import transcribe_audio

logger = logging.getLogger(__name__)

UPLOADS_DIR = Path(__file__).parent / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)


# ==============================================================================
# Session State Model
# ==============================================================================

@dataclass
class ChatDraft:
    """Represents an active drafting session for a specific chat."""
    is_active: bool = False
    audio_paths: list[Path] = field(default_factory=list)
    photo_paths: list[Path] = field(default_factory=list)
    text_snippets: list[str] = field(default_factory=list)
    temp_files: list[Path] = field(default_factory=list)

    def is_empty(self) -> bool:
        return not (self.audio_paths or self.photo_paths or self.text_snippets)

    def summary(self) -> str:
        return (
            f"📷 फोटो: {len(self.photo_paths)} | "
            f"🎙️ व्हॉईस नोट्स: {len(self.audio_paths)} | "
            f"📝 टिपा: {len(self.text_snippets)}"
        )


# Global in-memory draft storage per chat_id
CHAT_DRAFTS: dict[int, ChatDraft] = {}


def get_or_create_draft(chat_id: int) -> ChatDraft:
    if chat_id not in CHAT_DRAFTS:
        CHAT_DRAFTS[chat_id] = ChatDraft()
    return CHAT_DRAFTS[chat_id]


def reset_draft(chat_id: int) -> None:
    if chat_id in CHAT_DRAFTS:
        draft = CHAT_DRAFTS[chat_id]
        cleanup_files(draft.temp_files)
        CHAT_DRAFTS[chat_id] = ChatDraft()


# ==============================================================================
# Keyboards
# ==============================================================================

# Idle keyboard shown when no report is actively being compiled
IDLE_KEYBOARD = ReplyKeyboardMarkup(
    [
        [KeyboardButton("📝 नवीन अहवाल सुरू करा (Start Creating)")],
        [KeyboardButton("⚙️ शाळा माहिती (Settings)"), KeyboardButton("ℹ️ मदत (Help)")],
    ],
    resize_keyboard=True,
    is_persistent=True,
)

# In-session keyboard shown while user is uploading photos/audio
IN_SESSION_KEYBOARD = ReplyKeyboardMarkup(
    [
        [KeyboardButton("🚀 अहवाल तयार करा (Create Report)")],
        [KeyboardButton("❌ रद्द करा (Cancel)")],
    ],
    resize_keyboard=True,
    is_persistent=True,
)


# ==============================================================================
# Command & Message Handlers
# ==============================================================================

async def start_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Welcomes the user and displays primary actions."""
    if not update.effective_message:
        return

    chat_id = update.effective_chat.id
    reset_draft(chat_id)

    welcome_text = (
        "नमस्कार! 🙏\n\n"
        "मी **Chronico** — शालेय कार्यक्रम अहवाल तयार करणारा तुमचा डिजिटल सहाय्यक आहे.\n\n"
        "📌 **कसे वापरावे:**\n"
        "१. **'📝 नवीन अहवाल सुरू करा'** बटण दाबा.\n"
        "२. कार्यक्रमाचे फोटो, मराठी व्हॉईस नोट किंवा मजकूर पाठवा.\n"
        "३. सर्व पाठवून झाल्यावर **'🚀 अहवाल तयार करा'** बटण दाबा.\n"
        "४. काही सेकंदांत प्रिंट करण्यायोग्य अधिकृत **PDF अहवाल** तयार होईल!\n\n"
        "शाळा किंवा मुख्याध्यापकांची माहिती पाहण्यासाठी खालील '⚙️ शाळा माहिती' बटण दाबा."
    )
    await update.effective_message.reply_text(
        welcome_text,
        parse_mode=ParseMode.MARKDOWN,
        reply_markup=IDLE_KEYBOARD,
    )


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Displays help and command instructions."""
    if not update.effective_message:
        return

    help_text = (
        "📖 **Chronico मदत व मार्गदर्शक:**\n\n"
        "• `/new` किंवा **'📝 नवीन अहवाल सुरू करा'**: नवीन अहवाल सत्र सुरू करा.\n"
        "• `/create` किंवा **'🚀 अहवाल तयार करा'**: गोळा केलेल्या साहित्यातून अहवाल व PDF तयार करा.\n"
        "• `/cancel` किंवा **'❌ रद्द करा'**: चालू सत्र रद्द करा.\n"
        "• `/config`: सध्या साठवलेली शाळा व संस्था माहिती पहा.\n"
        "• `/set <की> <मूल्य>`: शाळेची माहिती जोडा किंवा बदला.\n"
        "   उदा. `/set मुख्याध्यापक श्री. आनंद कांबळे`\n"
        "• `/delete_config <की>`: विशिष्ट माहिती हटवा.\n\n"
        "💡 *टीप: व्हॉईस नोटमध्ये बोलताना कार्यक्रमाचे नाव, प्रमुख पाहुणे आणि महत्त्वाच्या घडामोडी स्पष्ट सांगा.*"
    )
    await update.effective_message.reply_text(
        help_text,
        parse_mode=ParseMode.MARKDOWN,
    )


async def start_session_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Begins a report drafting session."""
    if not update.effective_message:
        return

    chat_id = update.effective_chat.id
    reset_draft(chat_id)
    draft = get_or_create_draft(chat_id)
    draft.is_active = True

    await update.effective_message.reply_text(
        "📝 **नवीन अहवाल सत्र सुरू झाले आहे!**\n\n"
        "आता तुम्ही:\n"
        "• 📷 **कार्यक्रम फोटो** पाठवू शकता (एक किंवा अनेक)\n"
        "• 🎙️ **मराठी व्हॉईस नोट** (Voice message) पाठवू शकता\n"
        "• ✍️ **मजकूर किंवा नोंदी** लिहून पाठवू शकता\n\n"
        "सर्व साहित्य पाठवून झाल्यावर खालील **'🚀 अहवाल तयार करा'** बटण दाबा.",
        parse_mode=ParseMode.MARKDOWN,
        reply_markup=IN_SESSION_KEYBOARD,
    )


async def cancel_session_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Cancels the active drafting session and deletes any downloaded temporary files."""
    if not update.effective_message:
        return

    chat_id = update.effective_chat.id
    reset_draft(chat_id)

    await update.effective_message.reply_text(
        "❌ **अहवाल निर्मिती रद्द करण्यात आली आहे.**\n"
        "सर्व तात्पुरत्या फायली हटवण्यात आल्या आहेत.",
        reply_markup=IDLE_KEYBOARD,
    )


async def download_telegram_media(
    media_obj: Any,
    target_path: Path,
    max_retries: int = 3,
) -> bool:
    """
    Downloads media from Telegram with validation, retry loop, and custom timeouts.
    """
    file_size = getattr(media_obj, "file_size", None)
    if file_size and file_size > 20 * 1024 * 1024:
        raise ValueError(
            f"फाईल आकार ({file_size / (1024 * 1024):.1f}MB) टेलिग्रामच्या २०MB मर्यादेपेक्षा जास्त आहे."
        )

    last_error = None
    for attempt in range(1, max_retries + 1):
        try:
            tg_file = await media_obj.get_file(
                read_timeout=60.0,
                write_timeout=60.0,
                connect_timeout=30.0,
            )
            await tg_file.download_to_drive(
                custom_path=target_path,
                read_timeout=120.0,
                write_timeout=120.0,
                connect_timeout=30.0,
            )
            return True
        except Exception as e:
            last_error = e
            logger.warning(
                f"Download attempt {attempt}/{max_retries} failed for "
                f"{getattr(media_obj, 'file_id', 'unknown')}: {e}"
            )
            if attempt < max_retries:
                await asyncio.sleep(1.5 * attempt)
            else:
                raise last_error
    return False


async def photo_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Downloads incoming photos and attaches them to the active session."""
    if not update.effective_message or not update.effective_message.photo:
        return

    chat_id = update.effective_chat.id
    draft = get_or_create_draft(chat_id)
    if not draft.is_active:
        draft.is_active = True

    try:
        await context.bot.send_chat_action(chat_id=chat_id, action="upload_photo")
    except Exception:
        pass

    # Get the highest resolution version
    photo_file = update.effective_message.photo[-1]
    target_path = UPLOADS_DIR / f"img_{uuid.uuid4().hex[:8]}.jpg"

    try:
        await download_telegram_media(photo_file, target_path)
    except Exception as e:
        logger.error(f"Failed to download photo from chat {chat_id}: {e}", exc_info=True)
        await update.effective_message.reply_text(
            "⚠️ **फोटो डाउनलोड करताना समस्या आली (नेटवर्क टाइमआउट).**\n"
            "कृपया तोच फोटो पुन्हा पाठवून पहा.",
            parse_mode=ParseMode.MARKDOWN,
        )
        return

    draft.photo_paths.append(target_path)
    draft.temp_files.append(target_path)

    # If photo has a caption, store it as text snippet
    caption = update.effective_message.caption
    if caption and caption.strip():
        draft.text_snippets.append(caption.strip())

    await update.effective_message.reply_text(
        f"📷 **फोटो जोडला गेला!**\n"
        f"सध्या जमा झालेले साहित्य:\n{draft.summary()}\n\n"
        "आणखी साहित्य पाठवा किंवा खालील **'🚀 अहवाल तयार करा'** बटण दाबा.",
        parse_mode=ParseMode.MARKDOWN,
        reply_markup=IN_SESSION_KEYBOARD,
    )


async def voice_or_audio_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Downloads voice notes or audio files and attaches them to the active session."""
    if not update.effective_message:
        return

    chat_id = update.effective_chat.id
    draft = get_or_create_draft(chat_id)
    if not draft.is_active:
        draft.is_active = True

    msg = update.effective_message
    audio_obj = msg.voice or msg.audio
    if not audio_obj:
        return

    try:
        await context.bot.send_chat_action(chat_id=chat_id, action="record_voice")
    except Exception:
        pass

    suffix = ".ogg" if msg.voice else Path(getattr(audio_obj, "file_name", "audio.mp3")).suffix or ".ogg"
    target_path = UPLOADS_DIR / f"voice_{uuid.uuid4().hex[:8]}{suffix}"

    try:
        await download_telegram_media(audio_obj, target_path)
    except Exception as e:
        logger.error(f"Failed to download audio from chat {chat_id}: {e}", exc_info=True)
        await update.effective_message.reply_text(
            "⚠️ **व्हॉईस नोट डाउनलोड करताना समस्या आली (नेटवर्क टाइमआउट).**\n"
            "कृपया तीच व्हॉईस नोट पुन्हा पाठवून पहा.",
            parse_mode=ParseMode.MARKDOWN,
        )
        return

    draft.audio_paths.append(target_path)
    draft.temp_files.append(target_path)

    await update.effective_message.reply_text(
        f"🎙️ **व्हॉईस नोट जोडली गेली!**\n"
        f"सध्या जमा झालेले साहित्य:\n{draft.summary()}\n\n"
        "आणखी साहित्य पाठवा किंवा खालील **'🚀 अहवाल तयार करा'** बटण दाबा.",
        parse_mode=ParseMode.MARKDOWN,
        reply_markup=IN_SESSION_KEYBOARD,
    )


async def text_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handles text messages and button presses."""
    if not update.effective_message or not update.effective_message.text:
        return

    raw_text = update.effective_message.text.strip()
    chat_id = update.effective_chat.id

    # 1. Match Keyboard Actions
    if "नवीन अहवाल सुरू करा" in raw_text or raw_text == "/new":
        await start_session_handler(update, context)
        return

    if "अहवाल तयार करा" in raw_text or raw_text == "/create":
        await create_report_handler(update, context)
        return

    if "रद्द करा" in raw_text or raw_text == "/cancel":
        await cancel_session_handler(update, context)
        return

    if "शाळा माहिती" in raw_text or raw_text == "/config":
        await config_command(update, context)
        return

    if "मदत" in raw_text or raw_text == "/help":
        await help_command(update, context)
        return

    # 2. Text input inside session
    draft = get_or_create_draft(chat_id)
    if draft.is_active:
        draft.text_snippets.append(raw_text)
        await update.effective_message.reply_text(
            f"✍️ **नोंद जोडली गेली:** \"{raw_text[:60]}{'...' if len(raw_text) > 60 else ''}\"\n"
            f"सध्या जमा झालेले साहित्य:\n{draft.summary()}\n\n"
            "तयार झाल्यावर खालील **'🚀 अहवाल तयार करा'** बटण दाबा.",
            parse_mode=ParseMode.MARKDOWN,
            reply_markup=IN_SESSION_KEYBOARD,
        )
    else:
        # Prompt user to start session
        await update.effective_message.reply_text(
            "💡 नवीन अहवाल तयार करण्यासाठी कृपया खालील **'📝 नवीन अहवाल सुरू करा'** बटण दाबा.",
            reply_markup=IDLE_KEYBOARD,
        )


async def safe_update_status(status_msg, update: Update, text: str, parse_mode=None):
    """
    Safely edits the status message or sends a new message if Telegram rejects editing.
    """
    try:
        return await status_msg.edit_text(text, parse_mode=parse_mode)
    except Exception as e:
        logger.warning(f"Could not edit status message ({e}), sending new message.")
        try:
            return await update.effective_message.reply_text(text, parse_mode=parse_mode)
        except Exception:
            return status_msg


async def create_report_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Compiles all collected media & text and executes the report pipeline."""
    if not update.effective_message:
        return

    chat_id = update.effective_chat.id
    draft = get_or_create_draft(chat_id)

    if not draft.is_active or draft.is_empty():
        await update.effective_message.reply_text(
            "⚠️ **सध्या कोणतेही साहित्य उपलब्ध नाही.**\n"
            "कृपया अहवालासाठी किमान एक व्हॉईस नोट, फोटो किंवा मजकूर पाठवा.",
            reply_markup=IN_SESSION_KEYBOARD if draft.is_active else IDLE_KEYBOARD,
        )
        return

    status_msg = await update.effective_message.reply_text(
        "⏳ **अहवाल निर्मिती प्रक्रिया सुरू झाली आहे...**\n"
        "कृपया काही सेकंद प्रतीक्षा करा.",
        parse_mode=ParseMode.MARKDOWN,
    )

    try:
        combined_narration_parts: list[str] = []

        # 1. Transcribe any audio files
        if draft.audio_paths:
            status_msg = await safe_update_status(
                status_msg,
                update,
                "🎙️ **व्हॉईस नोटचे मराठीत भाषांतर (Sarvam AI STT) होत आहे...**",
                parse_mode=ParseMode.MARKDOWN,
            )
            for audio_path in draft.audio_paths:
                transcript = transcribe_audio(
                    audio_source=audio_path,
                    filename=audio_path.name,
                    language_code="mr-IN",
                )
                if transcript and transcript.strip():
                    combined_narration_parts.append(transcript.strip())

        # 2. Add text snippets
        if draft.text_snippets:
            combined_narration_parts.extend(draft.text_snippets)

        final_narration = "\n\n".join(combined_narration_parts)
        if not final_narration.strip():
            final_narration = "शाळेत कार्यक्रम उत्साहात संपन्न झाला."

        # 3. Multi-Agent Pipeline
        status_msg = await safe_update_status(
            status_msg,
            update,
            "🤖 **मल्टि-एजंट प्रणाली अहवाल तयार करत आहे...**\n"
            "(Writer ➔ Verifier ➔ Critic ➔ PDF)",
            parse_mode=ParseMode.MARKDOWN,
        )

        loop = asyncio.get_running_loop()
        photo_str_paths = [str(p) for p in draft.photo_paths]
        temp_str_files = [str(p) for p in draft.temp_files]

        # Run pipeline in worker thread to avoid blocking asyncio event loop
        result = await loop.run_in_executor(
            None,
            lambda: generate_report(
                narration=final_narration,
                photos=photo_str_paths,
                temp_files_to_cleanup=temp_str_files,
                cleanup_temp_files=True,
            ),
        )

        if not result.success or not result.pdf_path:
            error_details = result.error or "अहवाल निर्मितीत त्रुटी आली."
            await safe_update_status(
                status_msg,
                update,
                f"❌ **अहवाल तयार करता आला नाही:**\n{error_details}",
            )
            await update.effective_message.reply_text(
                "कृपया पुन्हा प्रयत्न करा.",
                reply_markup=IDLE_KEYBOARD,
            )
            return

        # 4. Deliver PDF Document
        pdf_path = Path(result.pdf_path)
        await safe_update_status(
            status_msg,
            update,
            "📄 **PDF अहवाल तयार झाला आहे! पाठवत आहे...**",
            parse_mode=ParseMode.MARKDOWN,
        )

        caption_text = (
            f"✅ **{result.event.title}**\n\n"
            f"📅 **दिनांक:** {result.event.date}\n"
            f"📍 **स्थळ:** {result.event.venue}\n"
            f"🏫 **शाळा:** {result.school.name}\n\n"
            f"📄 अधिकृत अहवाल PDF स्वरूपात सोबत जोडला आहे."
        )

        with open(pdf_path, "rb") as pdf_file:
            await update.effective_message.reply_document(
                document=pdf_file,
                filename=pdf_path.name,
                caption=caption_text,
                parse_mode=ParseMode.MARKDOWN,
            )

        # 5. Reset Draft & Restore Idle Keyboard
        CHAT_DRAFTS[chat_id] = ChatDraft()
        await update.effective_message.reply_text(
            "🎉 **अहवाल यशस्वीरीत्या पूर्ण झाला!**\nपुढील अहवालासाठी खालील बटण वापरा.",
            reply_markup=IDLE_KEYBOARD,
        )

    except Exception as e:
        logger.error(f"Error in create_report_handler: {e}", exc_info=True)
        await update.effective_message.reply_text(
            f"❌ **अहवाल तयार करताना त्रुटी आली:**\n`{str(e)}`",
            parse_mode=ParseMode.MARKDOWN,
            reply_markup=IDLE_KEYBOARD,
        )
    finally:
        reset_draft(chat_id)


# ==============================================================================
# Configuration Management Handlers
# ==============================================================================

async def config_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Displays current institutional settings stored in SQLite."""
    if not update.effective_message:
        return

    configs = get_all_configs()
    if not configs:
        msg = (
            "⚙️ **शाळा व संस्था माहिती (रिक्त आहे):**\n\n"
            "अजून कोणतीही माहिती जोडलेली नाही.\n\n"
            "माहिती जोडण्यासाठी पुढीलप्रमाणे संदेश पाठवा:\n"
            "`/set शाळेचे नाव जिल्हा परिषद प्राथमिक शाळा, शिवणे`\n"
            "`/set मुख्याध्यापक श्री. आनंद कांबळे`\n"
            "`/set तालुका हवेली`\n"
            "`/set जिल्हा पुणे`"
        )
    else:
        lines = [f"• **{k}**: {v}" for k, v in configs.items()]
        msg = (
            "⚙️ **सध्या साठवलेली शाळा माहिती:**\n\n"
            + "\n".join(lines)
            + "\n\n"
            "नवीन माहिती जोडण्यासाठी:\n"
            "`/set <की> <मूल्य>`\n\n"
            "माहिती हटवण्यासाठी:\n"
            "`/delete_config <की>`"
        )

    await update.effective_message.reply_text(msg, parse_mode=ParseMode.MARKDOWN)


async def set_config_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Sets a key-value configuration in SQLite DB."""
    if not update.effective_message:
        return

    args = context.args or []
    if len(args) < 2:
        await update.effective_message.reply_text(
            "⚠️ **वापर:** `/set <की> <मूल्य>`\n"
            "उदा. `/set मुख्याध्यापक श्री. आनंद कांबळे`"
        )
        return

    key = args[0].strip()
    value = " ".join(args[1:]).strip()
    set_config_value(key, value)

    await update.effective_message.reply_text(
        f"✅ **माहिती जतन झाली:**\n• **{key}**: {value}",
        parse_mode=ParseMode.MARKDOWN,
    )


async def delete_config_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Deletes a key from configuration."""
    if not update.effective_message:
        return

    args = context.args or []
    if not args:
        await update.effective_message.reply_text(
            "⚠️ **वापर:** `/delete_config <की>`\n"
            "उदा. `/delete_config तालुका`"
        )
        return

    key = args[0].strip()
    deleted = delete_config_key(key)
    if deleted:
        await update.effective_message.reply_text(f"🗑️ '{key}' हटवले गेले.")
    else:
        await update.effective_message.reply_text(f"⚠️ '{key}' सापडले नाही.")


# ==============================================================================
# Application Factory
# ==============================================================================

async def global_error_handler(update: object, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Logs unhandled exceptions and notifies user gracefully."""
    logger.error("Exception while handling an update:", exc_info=context.error)
    if isinstance(update, Update) and update.effective_message:
        try:
            from telegram.error import NetworkError, TimedOut
            if isinstance(context.error, (TimedOut, NetworkError)):
                await update.effective_message.reply_text(
                    "⚠️ **नेटवर्क टाइमआउट:** टेलिग्राम सर्व्हरकडून प्रतिसाद मिळण्यास उशीर झाला. कृपया पुन्हा प्रयत्न करा."
                )
            else:
                await update.effective_message.reply_text(
                    "⚠️ प्रक्रियेदरम्यान तांत्रिक त्रुटी आली. कृपया पुन्हा प्रयत्न करा."
                )
        except Exception:
            pass


def create_telegram_bot_app(token: str) -> Application:
    """Builds and returns the configured python-telegram-bot Application."""
    from telegram.request import HTTPXRequest

    init_db()

    request_config = HTTPXRequest(
        connection_pool_size=32,
        connect_timeout=30.0,
        read_timeout=60.0,
        write_timeout=60.0,
        pool_timeout=30.0,
        media_write_timeout=60.0,
    )

    app = Application.builder().token(token).request(request_config).build()

    # Global error handler
    app.add_error_handler(global_error_handler)

    # Commands
    app.add_handler(CommandHandler("start", start_command))
    app.add_handler(CommandHandler("help", help_command))
    app.add_handler(CommandHandler("new", start_session_handler))
    app.add_handler(CommandHandler("create", create_report_handler))
    app.add_handler(CommandHandler("cancel", cancel_session_handler))
    app.add_handler(CommandHandler("config", config_command))
    app.add_handler(CommandHandler("set", set_config_command))
    app.add_handler(CommandHandler("delete_config", delete_config_command))

    # Media and messages
    app.add_handler(MessageHandler(filters.PHOTO, photo_handler))
    app.add_handler(MessageHandler(filters.VOICE | filters.AUDIO, voice_or_audio_handler))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, text_handler))

    return app
