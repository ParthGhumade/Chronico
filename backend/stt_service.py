import logging
import mimetypes
import os
import shutil
import subprocess
import tempfile
import uuid
from pathlib import Path
from typing import BinaryIO
from dotenv import load_dotenv
import httpx

load_dotenv()
logger = logging.getLogger(__name__)

SARVAM_STT_URL = "https://api.sarvam.ai/speech-to-text"
DEFAULT_SARVAM_MODEL = os.getenv("SARVAM_MODEL", "saaras:v4")
DEFAULT_LANGUAGE_CODE = "mr-IN"

MIME_MAPPINGS = {
    ".ogg": "audio/ogg",
    ".oga": "audio/ogg",
    ".wav": "audio/wav",
    ".mp3": "audio/mpeg",
    ".m4a": "audio/mp4",
    ".aac": "audio/aac",
    ".flac": "audio/flac",
}


def get_audio_mime_type(file_path: str | Path) -> str:
    """Returns appropriate MIME type for audio file, especially handling Telegram .oga/.ogg."""
    ext = Path(file_path).suffix.lower()
    if ext in MIME_MAPPINGS:
        return MIME_MAPPINGS[ext]
    mime, _ = mimetypes.guess_type(str(file_path))
    return mime or "audio/ogg"


def get_audio_duration_seconds(file_path: Path) -> float | None:
    """Uses ffprobe to inspect the audio file duration in seconds."""
    try:
        cmd = [
            "ffprobe",
            "-v", "error",
            "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1",
            str(file_path),
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        raw_output = result.stdout.strip()
        if raw_output:
            return float(raw_output)
    except Exception as e:
        logger.warning(f"Could not determine audio duration with ffprobe for {file_path}: {e}")
    return None


def split_audio_into_chunks(file_path: Path, max_chunk_duration: float = 25.0) -> list[Path]:
    """
    Splits an audio file into chunks of at most `max_chunk_duration` seconds using ffmpeg.
    Sarvam synchronous STT enforces a strict 30-second maximum duration limit.
    """
    duration = get_audio_duration_seconds(file_path)
    if duration is None or duration <= max_chunk_duration:
        return [file_path]

    temp_dir = Path(tempfile.mkdtemp(prefix="audio_chunks_"))
    chunks: list[Path] = []
    ext = file_path.suffix.lower() or ".ogg"

    current_start = 0.0
    chunk_idx = 0

    while current_start < duration:
        chunk_file = temp_dir / f"chunk_{chunk_idx:03d}{ext}"
        cmd = [
            "ffmpeg",
            "-y",
            "-ss", str(current_start),
            "-i", str(file_path),
            "-t", str(max_chunk_duration),
            "-c:a", "copy",
            str(chunk_file),
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            # Fallback re-encode if stream copy fails
            cmd_reencode = [
                "ffmpeg",
                "-y",
                "-ss", str(current_start),
                "-i", str(file_path),
                "-t", str(max_chunk_duration),
                str(chunk_file),
            ]
            subprocess.run(cmd_reencode, capture_output=True, text=True, check=True)

        if chunk_file.exists() and chunk_file.stat().st_size > 0:
            chunks.append(chunk_file)
        chunk_idx += 1
        current_start += max_chunk_duration

    logger.info(f"Split {file_path.name} (duration: {duration:.1f}s) into {len(chunks)} chunks.")
    return chunks


def _transcribe_single_chunk(
    file_path: Path,
    language_code: str,
    resolved_model: str,
    resolved_api_key: str,
) -> str:
    """Submits a single audio file (must be <= 30 seconds) to Sarvam AI STT."""
    target_filename = file_path.name
    mime_type = get_audio_mime_type(file_path)
    with open(file_path, "rb") as f:
        file_bytes = f.read()

    logger.info(
        f"Submitting chunk to Sarvam AI STT ({len(file_bytes)} bytes, {target_filename}, model: {resolved_model}, lang: {language_code})..."
    )

    headers = {
        "api-subscription-key": resolved_api_key,
    }

    files = {
        "file": (target_filename, file_bytes, mime_type),
    }

    data = {
        "model": resolved_model,
        "language_code": language_code,
        "mode": "transcribe",
    }

    models_to_try = [resolved_model]
    if resolved_model != "saaras:v3" and resolved_model != "saarika:v2.5":
        models_to_try.append("saaras:v3")

    last_error = None
    for candidate_model in models_to_try:
        data["model"] = candidate_model
        try:
            with httpx.Client(timeout=45.0) as client:
                response = client.post(
                    SARVAM_STT_URL,
                    headers=headers,
                    files=files,
                    data=data,
                )

            if response.status_code == 200:
                result_json = response.json()
                transcript = result_json.get("transcript", "").strip()
                logger.info(f"Sarvam AI transcription chunk completed ({len(transcript)} chars).")
                return transcript
            else:
                last_error = f"HTTP {response.status_code}: {response.text}"
                logger.warning(f"Sarvam AI STT error with model '{candidate_model}': {last_error}")
                if candidate_model == models_to_try[-1]:
                    break
        except Exception as e:
            last_error = str(e)
            logger.warning(f"Failed to connect to Sarvam AI with model '{candidate_model}': {e}")
            if candidate_model == models_to_try[-1]:
                break

    raise RuntimeError(f"Sarvam AI Speech-to-Text transcription failed: {last_error}")


def transcribe_audio(
    audio_source: str | Path | BinaryIO | bytes,
    filename: str | None = None,
    language_code: str = DEFAULT_LANGUAGE_CODE,
    model: str | None = None,
    api_key: str | None = None,
) -> str:
    """
    Transcribes Marathi (or specified language) speech from an audio file using Sarvam AI STT.
    Automatically chunks audio exceeding 25 seconds to respect Sarvam's 30-second synchronous limit.
    """
    resolved_api_key = api_key or os.getenv("SARVAM_API_KEY")
    resolved_model = model or DEFAULT_SARVAM_MODEL

    if not resolved_api_key:
        raise ValueError(
            "Sarvam AI API subscription key is required. Please set SARVAM_API_KEY in your environment or backend/.env."
        )

    # Ensure we have a concrete file path on disk to allow duration inspection and chunking
    temp_dir_to_cleanup: Path | None = None
    file_to_process: Path

    if isinstance(audio_source, (str, Path)):
        file_to_process = Path(audio_source)
        if not file_to_process.exists():
            raise FileNotFoundError(f"Audio file not found at: {audio_source}")
    else:
        # Buffer or bytes: save to temp file
        temp_dir_to_cleanup = Path(tempfile.mkdtemp(prefix="stt_input_"))
        suffix = Path(filename or "voice.ogg").suffix or ".ogg"
        file_to_process = temp_dir_to_cleanup / f"input_{uuid.uuid4().hex[:8]}{suffix}"

        if isinstance(audio_source, bytes):
            with open(file_to_process, "wb") as f:
                f.write(audio_source)
        elif hasattr(audio_source, "read"):
            with open(file_to_process, "wb") as f:
                f.write(audio_source.read())

    try:
        # Check if duration requires chunking
        duration = get_audio_duration_seconds(file_to_process)
        if duration is not None and duration > 28.0:
            logger.info(f"Audio duration is {duration:.1f}s (> 28s limit). Slicing into 25s chunks for Sarvam STT.")
            chunks = split_audio_into_chunks(file_to_process, max_chunk_duration=25.0)
            chunk_transcripts: list[str] = []
            for chunk_path in chunks:
                chunk_text = _transcribe_single_chunk(
                    file_path=chunk_path,
                    language_code=language_code,
                    resolved_model=resolved_model,
                    resolved_api_key=resolved_api_key,
                )
                if chunk_text.strip():
                    chunk_transcripts.append(chunk_text.strip())

            # Cleanup chunks directory if generated
            if chunks and chunks[0] != file_to_process:
                shutil.rmtree(chunks[0].parent, ignore_errors=True)

            final_text = " ".join(chunk_transcripts)
            logger.info(f"Total merged transcription ({len(final_text)} chars) across {len(chunks)} chunks.")
            return final_text
        else:
            # Single chunk transcription
            return _transcribe_single_chunk(
                file_path=file_to_process,
                language_code=language_code,
                resolved_model=resolved_model,
                resolved_api_key=resolved_api_key,
            )
    finally:
        if temp_dir_to_cleanup and temp_dir_to_cleanup.exists():
            shutil.rmtree(temp_dir_to_cleanup, ignore_errors=True)
