from typing import Literal
from pydantic import BaseModel


class School(BaseModel):
    name: str
    address: str
    principal: str
    signatory: str


class Event(BaseModel):
    id: str
    title: str
    date: str
    venue: str
    category: str


class Photo(BaseModel):
    id: str
    path: str | None = None
    description: str | None = None
    ocr: str | None = None


class Context(BaseModel):
    school: School
    event: Event
    photos: list[Photo]
    raw_narration: str


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


