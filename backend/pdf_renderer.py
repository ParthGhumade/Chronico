import logging
import os
from pathlib import Path
from typing import Any

from jinja2 import Environment, FileSystemLoader
from weasyprint import HTML

from backend.models import Context

logger = logging.getLogger(__name__)

def _markdown_to_html(text: str) -> str:
    """
    Basic converter for markdown to HTML.
    Converts **bold** to <b>bold</b> and newlines to <p> tags.
    """
    formatted_text = text

    # Basic Markdown bold to HTML bold conversion
    while "**" in formatted_text:
        formatted_text = formatted_text.replace("**", "<b>", 1).replace("**", "</b>", 1)

    # Convert newlines to paragraphs
    paragraphs = formatted_text.split("\n")
    html_paragraphs = []
    for para in paragraphs:
        cleaned = para.strip()
        if cleaned:
            html_paragraphs.append(f"<p>{cleaned}</p>")
            
    return "\n".join(html_paragraphs)


def generate_pdf_report(
    report_text: str,
    context: Context | dict[str, Any],
    output_path: str | None = None,
) -> bytes | str:
    """
    Generates a formatted PDF report with Marathi language support using WeasyPrint and Jinja2.

    Args:
        report_text: The final polished report string in markdown format.
        context: The Context object containing school and event metadata.
        output_path: Optional file path where the PDF should be saved. If None, returns PDF bytes.

    Returns:
        bytes if output_path is None, else output_path string.
    """
    logger.info("Initializing PDF generation with WeasyPrint...")
    
    if isinstance(context, dict):
        context_data = Context(**context)
    else:
        context_data = context

    # 1. Convert markdown to HTML
    report_html = _markdown_to_html(report_text)
    
    # Filter photos that actually exist on disk
    valid_photos = []
    if hasattr(context_data, "photos") and context_data.photos:
        for photo in context_data.photos:
            if photo.path and os.path.exists(photo.path):
                valid_photos.append(photo)
            else:
                logger.warning(f"Skipping photo {photo.id} - file not found at path: {photo.path}")

    # 2. Setup Jinja2 Environment
    template_dir = Path(__file__).parent / "templates"
    env = Environment(loader=FileSystemLoader(str(template_dir)))
    template = env.get_template("report_template.html")

    # 3. Render HTML
    rendered_html = template.render(
        school_name=context_data.school.name,
        school_address=context_data.school.address,
        event_title=context_data.event.title,
        event_date=context_data.event.date,
        report_html=report_html,
        signatory=context_data.school.signatory,
        photos=valid_photos,
    )
    
    # 4. Build PDF
    if output_path:
        logger.info(f"Building PDF at: {output_path}")
        output_dir = Path(output_path).parent
        output_dir.mkdir(parents=True, exist_ok=True)
        
        HTML(string=rendered_html, base_url=str(Path(__file__).parent)).write_pdf(output_path)
        logger.info("PDF generation complete.")
        return output_path
    else:
        logger.info("Building PDF as byte stream...")
        pdf_bytes = HTML(string=rendered_html, base_url=str(Path(__file__).parent)).write_pdf()
        logger.info("PDF byte stream generation complete.")
        return pdf_bytes
