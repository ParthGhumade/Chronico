import logging
from pathlib import Path
from fastapi import FastAPI, HTTPException, Response
from fastapi.responses import FileResponse
from pydantic import BaseModel

from backend.models import Context, ExportPdfRequest, PipelineResult
from backend.pdf_renderer import generate_pdf_report
from backend.pipeline import run_writer_verifier_pipeline

app = FastAPI(title="Chronico API")

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")


class GenerateReportRequest(BaseModel):
    context: Context
    max_retries: int = 3
    enable_critic: bool = True
    export_pdf: bool = True


@app.post("/api/generate_report", response_model=PipelineResult)
def generate_report(request: GenerateReportRequest):
    try:
        pipeline_result = run_writer_verifier_pipeline(
            context=request.context,
            max_retries=request.max_retries,
            enable_critic=request.enable_critic,
        )

        if request.export_pdf and pipeline_result.final_report:
            event_id = request.context.event.id or "report"
            filename = f"{event_id}.pdf"
            output_dir = Path(__file__).parent / "generated_reports"
            output_path = str(output_dir / filename)

            generate_pdf_report(
                report_text=pipeline_result.final_report,
                context=request.context,
                output_path=output_path,
            )
            pipeline_result.pdf_url = f"/api/download_pdf/{filename}"

        return pipeline_result
    except Exception as e:
        logging.error(f"Error generating report: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/download_pdf/{filename}")
def download_pdf(filename: str):
    """
    Downloads a previously generated PDF report file.
    """
    file_path = Path(__file__).parent / "generated_reports" / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="PDF report not found.")
    return FileResponse(
        path=file_path,
        media_type="application/pdf",
        filename=filename,
    )

'''@app.post("/api/export_pdf")
def export_pdf(request: ExportPdfRequest):
    """
    Directly converts final report markdown + context into a downloadable PDF binary stream.
    """
    try:
        pdf_bytes = generate_pdf_report(
            report_text=request.report_text,
            context=request.context,
            output_path=None,
        )
        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename=report_{request.context.event.id}.pdf"},
        )
    except Exception as e:
        logging.error(f"Error exporting PDF: {e}")
        raise HTTPException(status_code=500, detail=str(e))
'''
