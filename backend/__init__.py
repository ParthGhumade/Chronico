"""
Backend package for Chronico.
"""

from backend.critic import run_critic_agent
from backend.extractor import extract_event_metadata
from backend.models import (
    AudioReportResponse,
    Context,
    Event,
    Photo,
    PipelineResult,
    ReportRequest,
    ReportResponse,
    School,
    STTResponse,
    VerificationResult,
)
from backend.pdf_renderer import generate_pdf_report
from backend.pipeline import (
    cleanup_files,
    generate_report,
    get_next_serial_report_path,
    run_writer_verifier_pipeline,
)
from backend.stt_service import transcribe_audio
from backend.verifier import run_verifier_agent
from backend.writer import run_writer_agent

__all__ = [
    # Core Agents & STT
    "run_writer_agent",
    "run_verifier_agent",
    "run_critic_agent",
    "extract_event_metadata",
    "transcribe_audio",
    # Pipelines & Utilities
    "generate_report",
    "run_writer_verifier_pipeline",
    "generate_pdf_report",
    "get_next_serial_report_path",
    "cleanup_files",
    # Models
    "ReportRequest",
    "ReportResponse",
    "AudioReportResponse",
    "STTResponse",
    "Context",
    "School",
    "Event",
    "Photo",
    "VerificationResult",
    "PipelineResult",
]
