import logging
import os
import shutil
import uuid
from pathlib import Path
from typing import Annotated

from fastapi import FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse

from backend.database import (
    clear_all_configs,
    delete_config_key,
    get_all_configs,
    init_db,
    set_configs,
)
from backend.models import (
    AudioReportResponse,
    ConfigResponse,
    ConfigUpdateRequest,
    ReportResponse,
    School,
)
from backend.pipeline import cleanup_files, generate_report
from backend.stt_service import transcribe_audio

# Initialize local SQLite database
init_db()

app = FastAPI(
    title="Chronico API",
    description="Chronico API with Config persistence and Multi-Agent serial Marathi event PDF report generation from voice or text.",
    version="1.1.0",
)

# Enable CORS for local testing and web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

UPLOADS_DIR = Path(__file__).parent / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)


# ==========================================================================
# 1. HEALTH CHECK
# ==========================================================================

@app.get("/api/health")
def health_check():
    """Health check endpoint."""
    return {"status": "ok", "service": "Chronico API"}


# ==========================================================================
# 2. GENERATE PDF FROM VOICE
# ==========================================================================

@app.post("/api/generate/voice", response_class=FileResponse)
async def generate_pdf_from_voice(
    audio: UploadFile = File(..., description="Voice note recording (.ogg, .oga, .mp3, .wav)"),
    photos: list[UploadFile] = File(default=[], description="Optional event photos to embed in the report"),
):
    """
    Generate PDF from Voice:
    - Input: raw audio recording + optional event photos.
    - Output: serial PDF binary stream (application/pdf).
    (School information and institutional context are automatically loaded from local config database).
    """
    temp_files: list[str] = []
    try:
        # Save temporary audio file
        audio_suffix = Path(audio.filename or "recording.ogg").suffix or ".ogg"
        temp_audio_path = UPLOADS_DIR / f"voice_{uuid.uuid4().hex[:8]}{audio_suffix}"
        with open(temp_audio_path, "wb") as buffer:
            shutil.copyfileobj(audio.file, buffer)
        temp_files.append(str(temp_audio_path))

        # Save temporary photo files
        saved_photo_paths: list[str] = []
        for photo in photos:
            if photo.filename:
                target_path = UPLOADS_DIR / f"img_{uuid.uuid4().hex[:8]}_{photo.filename}"
                with open(target_path, "wb") as buffer:
                    shutil.copyfileobj(photo.file, buffer)
                saved_photo_paths.append(str(target_path))
                temp_files.append(str(target_path))

        # Transcribe voice note
        logger.info(f"Transcribing voice note with Sarvam AI STT ({audio.filename})...")
        transcription = transcribe_audio(
            audio_source=temp_audio_path,
            filename=audio.filename,
            language_code="mr-IN",
        )

        # Execute multi-agent report pipeline (school & config auto-injected from database)
        result = generate_report(
            narration=transcription,
            photos=saved_photo_paths,
            temp_files_to_cleanup=temp_files,
            cleanup_temp_files=True,
        )

        if not result.success or not result.pdf_path:
            raise HTTPException(status_code=500, detail=result.error or "Report generation failed.")

        # Always return the generated PDF file stream
        return FileResponse(
            path=result.pdf_path,
            media_type="application/pdf",
            filename=Path(result.pdf_path).name,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Generate PDF from voice failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cleanup_files(temp_files)


# ==========================================================================
# 3. GENERATE PDF FROM TEXT
# ==========================================================================

@app.post("/api/generate/text", response_class=FileResponse)
async def generate_pdf_from_text(
    request: Request,
    narration: Annotated[str | None, Form()] = None,
    photos: list[UploadFile] = File(default=[], description="Optional event photos to embed in the report"),
):
    """
    Generate PDF from Text:
    - Input: raw text narration + optional event photos.
    - Output: serial PDF binary stream (application/pdf).
    (School information and institutional context are automatically loaded from local config database).
    """
    temp_files: list[str] = []
    try:
        resolved_narration = narration
        photo_paths_to_use: list[str] = []

        # Check if caller passed JSON instead of multipart form
        content_type = request.headers.get("content-type", "")
        if "application/json" in content_type:
            payload = await request.json()
            resolved_narration = payload.get("narration", "")
            photo_paths_to_use = payload.get("photos", [])
        else:
            # Multipart form: save any uploaded photo files
            for photo in photos:
                if photo.filename:
                    target_path = UPLOADS_DIR / f"img_{uuid.uuid4().hex[:8]}_{photo.filename}"
                    with open(target_path, "wb") as buffer:
                        shutil.copyfileobj(photo.file, buffer)
                    photo_paths_to_use.append(str(target_path))
                    temp_files.append(str(target_path))

        if not resolved_narration:
            raise HTTPException(status_code=400, detail="Missing required 'narration' field.")

        # Execute multi-agent report pipeline (school & config auto-injected from database)
        result = generate_report(
            narration=resolved_narration,
            photos=photo_paths_to_use,
            temp_files_to_cleanup=temp_files,
            cleanup_temp_files=True,
        )

        if not result.success or not result.pdf_path:
            raise HTTPException(status_code=500, detail=result.error or "Report generation failed.")

        # Always return the generated PDF file stream
        return FileResponse(
            path=result.pdf_path,
            media_type="application/pdf",
            filename=Path(result.pdf_path).name,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Generate PDF from text failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cleanup_files(temp_files)


# ==========================================================================
# 4. CONFIG API (Database-backed Key-Value Store)
# ==========================================================================

@app.get("/api/config", response_model=ConfigResponse)
def get_config():
    """
    Get all stored configuration key-value pairs from the local SQLite database.
    """
    configs = get_all_configs()
    return ConfigResponse(
        status="ok",
        configs=configs,
        message=f"Retrieved {len(configs)} config entries.",
    )


@app.post("/api/config", response_model=ConfigResponse)
async def update_config(
    request: Request,
    key: Annotated[str | None, Form()] = None,
    value: Annotated[str | None, Form()] = None,
):
    """
    Add or update key-value pairs stored in the SQLite database on this server.
    These key-value pairs are automatically injected into the narration text
    before passing to the first layer of the agent (Writer / Extractor).

    Accepts:
    - Direct JSON body: {"school_name": "ZP School", "principal": "Shri Patil"}
    - Wrapped JSON body: {"configs": {"school_name": "ZP School"}}
    - Multipart/URL-encoded form: key="school_name"&value="ZP School"
    """
    new_items: dict[str, str] = {}
    content_type = request.headers.get("content-type", "")

    if "application/json" in content_type:
        try:
            body = await request.json()
            if isinstance(body, dict):
                if "configs" in body and isinstance(body["configs"], dict):
                    new_items.update(body["configs"])
                elif "key" in body and "value" in body:
                    new_items[str(body["key"])] = str(body["value"])
                else:
                    for k, v in body.items():
                        new_items[str(k)] = str(v)
            else:
                raise HTTPException(status_code=400, detail="JSON body must be a dictionary.")
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid JSON payload: {e}")
    else:
        # Form fields
        if key:
            new_items[str(key)] = str(value or "")

    if not new_items:
        raise HTTPException(
            status_code=400,
            detail="No key-value pairs provided. Pass JSON body or 'key' and 'value' form fields.",
        )

    updated_configs = set_configs(new_items)
    return ConfigResponse(
        status="ok",
        configs=updated_configs,
        message=f"Successfully updated {len(new_items)} config entries.",
    )


@app.delete("/api/config/{key}", response_model=ConfigResponse)
def delete_config(key: str):
    """
    Delete a specific key-value pair from the local SQLite database.
    """
    deleted = delete_config_key(key)
    configs = get_all_configs()
    if not deleted:
        raise HTTPException(status_code=404, detail=f"Key '{key}' not found in configuration.")
    return ConfigResponse(
        status="ok",
        configs=configs,
        message=f"Key '{key}' deleted successfully.",
    )
