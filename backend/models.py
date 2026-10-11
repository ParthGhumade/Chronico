import uuid
from datetime import datetime
from typing import Any, Literal
from pydantic import BaseModel, Field


class School(BaseModel):
    name: str = "जिल्हा परिषद प्राथमिक शाळा"
    address: str = "महाराष्ट्र"
    principal: str = "मुख्याध्यापक"
    signatory: str = "मुख्याध्यापक"


class Event(BaseModel):
    id: str = Field(default_factory=lambda: f"evt_{uuid.uuid4().hex[:8]}")
    title: str = "शालेय कार्यक्रम अहवाल"
    date: str = Field(default_factory=lambda: datetime.now().strftime("%Y-%m-%d"))
    venue: str = "शाळा प्रांगण"
    category: str = "कार्यक्रम"


class Photo(BaseModel):
    id: str = Field(default_factory=lambda: f"photo_{uuid.uuid4().hex[:6]}")
    path: str | None = None
    description: str | None = None
    ocr: str | None = None


class Context(BaseModel):
    school: School = Field(default_factory=School)
    event: Event = Field(default_factory=Event)
    photos: list[Photo] = Field(default_factory=list)
    raw_narration: str
    config: dict[str, str] = Field(default_factory=dict)


class VerificationResult(BaseModel):
    status: Literal["approved", "retry"]
    issues: list[str] = []


class PipelineResult(BaseModel):
    final_report: str
    approved: bool
    iterations: int
    verification_history: list[VerificationResult] = []
    pdf_url: str | None = None


class ExportPdfRequest(BaseModel):
    report_text: str
    context: Context


# --- Single I/O Unified API Models ---

class ReportRequest(BaseModel):
    """
    Input schema for the single I/O report generation API.
    Only `narration` is required. Photos, school, and event details are optional.
    """
    narration: str
    photos: list[str | Photo] = Field(default_factory=list)
    school: School | None = None
    event: Event | None = None
    max_retries: int = 3
    enable_critic: bool = True
    output_pdf_path: str | None = None


class ReportResponse(BaseModel):
    """
    Output schema for the single I/O report generation API.
    Contains the final Marathi report text, generated PDF path & URL, metadata, and verification results.
    """
    success: bool
    report_text: str
    pdf_path: str | None = None
    pdf_url: str | None = None
    event: Event
    school: School
    approved: bool
    iterations: int
    verification_history: list[VerificationResult] = Field(default_factory=list)
    error: str | None = None


class AudioReportResponse(ReportResponse):
    """
    Output schema for the Audio Single I/O report generation API.
    Extends ReportResponse with the raw transcribed narration from Sarvam AI STT.
    """
    transcript: str = ""


class STTResponse(BaseModel):
    """
    Output schema for standalone STT transcription requests.
    """
    success: bool
    transcript: str
    language_code: str = "mr-IN"
    error: str | None = None
 
 
class ConfigUpdateRequest(BaseModel):
    configs: dict[str, str] = Field(default_factory=dict)


class ConfigResponse(BaseModel):
    status: str = "ok"
    configs: dict[str, str] = Field(default_factory=dict)
    message: str = ""




