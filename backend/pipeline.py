import logging
import time
from pathlib import Path
from typing import Any

from backend.models import (
    Context,
    Event,
    Photo,
    PipelineResult,
    ReportResponse,
    School,
    VerificationResult,
)
from backend.critic import run_critic_agent
from backend.verifier import run_verifier_agent
from backend.writer import run_writer_agent

logger = logging.getLogger(__name__)


def run_writer_verifier_pipeline(
    context: Context | dict[str, Any],
    max_retries: int = 3,
    enable_critic: bool = True,
    api_key: str | None = None,
    model_name: str | None = None,
) -> PipelineResult:
    """
    Executes the full Writer -> Verifier (with up to `max_retries` attempts) -> Critic agent pipeline.

    The pipeline process:
    1. Writer Agent generates an initial Marathi report draft from raw context.
    2. Verifier Agent checks the draft for hallucinations, unverified claims, or missing facts.
    3. If rejected, Verifier comments/issues are passed back to Writer Agent to fix the draft (up to max_retries iterations).
    4. Once approved (or max retries reached), Critic Agent checks formal Marathi grammar and structure, editing if and only if changes are needed without modifying any facts.

    Args:
        context: Shared Context containing school, event, photo details, and raw narration.
        max_retries: Maximum number of retry attempts allowed (default: 3).
        enable_critic: Whether to run the Critic agent for final grammar & tone polishing (default: True).
        api_key: Optional Gemini API key.
        model_name: Optional Gemini model name.

    Returns:
        PipelineResult containing the final report string, approval status, iteration count, and verification logs.
    """
    # 1. Initial draft generation
    logger.info("Starting Writer Agent (initial draft generation)...")
    current_draft = run_writer_agent(
        context=context,
        api_key=api_key,
        model_name=model_name,
    )

    history: list[VerificationResult] = []
    is_approved = False
    final_iterations = max_retries

    # 2. Iterative Verification & Retry Loop
    for iteration in range(1, max_retries + 1):
        time.sleep(4)  # Delay to avoid API rate limits
        logger.info(f"Running Verifier Agent (Attempt {iteration}/{max_retries})...")
        verification = run_verifier_agent(
            context=context,
            draft_report=current_draft,
            api_key=api_key,
            model_name=model_name,
        )
        history.append(verification)

        if verification.status == "approved":
            logger.info(f"Report approved on attempt {iteration}!")
            is_approved = True
            final_iterations = iteration
            break

        logger.warning(
            f"Verification failed on attempt {iteration}. Issues found: {verification.issues}"
        )

        # If not approved and retries remain, ask Writer Agent to fix issues
        if iteration < max_retries:
            time.sleep(4)  # Delay to avoid API rate limits
            logger.info(f"Sending feedback back to Writer Agent for retry {iteration}...")
            current_draft = run_writer_agent(
                context=context,
                retry_issues=verification.issues,
                current_draft=current_draft,
                api_key=api_key,
                model_name=model_name,
            )

    if not is_approved:
        logger.warning(
            f"Pipeline reached max retries ({max_retries}) without full verification approval."
        )

    # 3. Critic Agent Polish (if enabled)
    if enable_critic:
        time.sleep(4)  # Delay to avoid API rate limits
        logger.info("Running Critic Agent for grammar and structure check...")
        current_draft = run_critic_agent(
            verified_report=current_draft,
            context=context,
            api_key=api_key,
            model_name=model_name,
        )

    return PipelineResult(
        final_report=current_draft,
        approved=is_approved,
        iterations=final_iterations,
        verification_history=history,
    )


def get_next_serial_report_path(reports_dir: Path | str | None = None) -> Path:
    """
    Scans the generated reports directory and returns the next serial report file path:
    e.g. report_001.pdf, report_002.pdf, report_003.pdf, etc.
    """
    import re

    if reports_dir is None:
        target_dir = Path(__file__).parent / "generated_reports"
    else:
        target_dir = Path(reports_dir)

    target_dir.mkdir(parents=True, exist_ok=True)
    existing_nums: list[int] = []

    for file in target_dir.glob("report_*.pdf"):
        match = re.search(r"report_(\d+)\.pdf$", file.name)
        if match:
            try:
                existing_nums.append(int(match.group(1)))
            except ValueError:
                pass

    next_num = max(existing_nums, default=0) + 1
    return target_dir / f"report_{next_num:03d}.pdf"


def cleanup_files(file_paths: list[str | Path]) -> None:
    """
    Safely removes temporary files from disk.
    """
    for file_path in file_paths:
        try:
            p = Path(file_path)
            if p.exists() and p.is_file():
                p.unlink()
                logger.info(f"Cleaned up temporary file: {p}")
        except Exception as e:
            logger.warning(f"Failed to remove temporary file {file_path}: {e}")


def generate_report(
    narration: str,
    photos: list[str | Photo] | None = None,
    school: School | dict[str, Any] | None = None,
    event: Event | dict[str, Any] | None = None,
    custom_configs: dict[str, str] | None = None,
    max_retries: int = 3,
    enable_critic: bool = True,
    output_pdf_path: str | None = None,
    temp_files_to_cleanup: list[str | Path] | None = None,
    cleanup_temp_files: bool = True,
    api_key: str | None = None,
    model_name: str | None = None,
) -> ReportResponse:
    """
    Unified Single I/O pipeline interface.

    Inputs:
        narration: Raw Marathi event narration text.
        photos: Optional list of photo file paths or Photo models.
        school: Optional School profile (or dict). Defaults to standard school profile.
        event: Optional Event details (or dict). If omitted, metadata is auto-extracted from narration.
        custom_configs: Optional key-value pairs to inject and merge with database configs.
        max_retries: Max verification retry attempts.
        enable_critic: Whether to run Critic agent for tone/grammar polishing.
        output_pdf_path: Custom output PDF file path. If None, saves serially to report_001.pdf, report_002.pdf, etc.
        temp_files_to_cleanup: Optional list of temporary files (e.g. uploaded images or audio) to delete after PDF rendering.
        cleanup_temp_files: Whether to automatically delete temporary files after generation (default: True).
        api_key: Optional Gemini API key.
        model_name: Optional model override.

    Returns:
        ReportResponse containing the generated report text, serial PDF path, download URL, event/school metadata,
        and verification status.
    """
    from backend.database import get_all_configs, inject_config_into_text
    from backend.extractor import extract_event_metadata
    from backend.pdf_renderer import generate_pdf_report

    try:
        # 1. Resolve Configuration & Stored Key-Value Pairs
        active_configs = get_all_configs()
        if custom_configs:
            active_configs.update(custom_configs)

        # 2. Inject stored configuration into narration text for the first layer of the agent
        injected_narration = inject_config_into_text(narration, active_configs)

        # 3. Resolve School (hydrated from config if default)
        if isinstance(school, School):
            resolved_school = school
        elif isinstance(school, dict):
            resolved_school = School(**school)
        else:
            resolved_school = School(
                name=active_configs.get("school_name") or active_configs.get("शाळा") or active_configs.get("शाळेचे नाव") or "जिल्हा परिषद प्राथमिक शाळा",
                address=active_configs.get("school_address") or active_configs.get("address") or active_configs.get("पत्ता") or "महाराष्ट्र",
                principal=active_configs.get("principal") or active_configs.get("मुख्याध्यापक") or "मुख्याध्यापक",
                signatory=active_configs.get("signatory") or active_configs.get("स्वाक्षरी") or "मुख्याध्यापक",
            )

        # 4. Resolve Event (auto-extract from injected narration if not provided)
        if isinstance(event, Event):
            resolved_event = event
        elif isinstance(event, dict):
            resolved_event = Event(**event)
        else:
            resolved_event = extract_event_metadata(
                narration=injected_narration,
                api_key=api_key,
                model_name=model_name,
            )

        # 5. Resolve Photos
        resolved_photos: list[Photo] = []
        if photos:
            for idx, p in enumerate(photos):
                if isinstance(p, Photo):
                    resolved_photos.append(p)
                elif isinstance(p, str):
                    resolved_photos.append(Photo(id=f"photo_{idx + 1}", path=p))

        # 6. Construct Immutable Context with Config and Injected Narration
        context = Context(
            school=resolved_school,
            event=resolved_event,
            photos=resolved_photos,
            raw_narration=injected_narration,
            config=active_configs,
        )

        # 5. Run Writer -> Verifier -> Critic Agent Pipeline
        pipeline_result = run_writer_verifier_pipeline(
            context=context,
            max_retries=max_retries,
            enable_critic=enable_critic,
            api_key=api_key,
            model_name=model_name,
        )

        # 6. Render PDF with Serial Naming
        if output_pdf_path:
            target_pdf_path = Path(output_pdf_path)
            target_pdf_path.parent.mkdir(parents=True, exist_ok=True)
        else:
            target_pdf_path = get_next_serial_report_path()

        generate_pdf_report(
            report_text=pipeline_result.final_report,
            context=context,
            output_path=str(target_pdf_path),
        )

        pdf_filename = target_pdf_path.name
        pdf_url = f"/api/download_pdf/{pdf_filename}"

        return ReportResponse(
            success=True,
            report_text=pipeline_result.final_report,
            pdf_path=str(target_pdf_path),
            pdf_url=pdf_url,
            event=resolved_event,
            school=resolved_school,
            approved=pipeline_result.approved,
            iterations=pipeline_result.iterations,
            verification_history=pipeline_result.verification_history,
        )

    except Exception as e:
        logger.error(f"Single I/O pipeline execution failed: {e}", exc_info=True)
        fallback_school = school if isinstance(school, School) else School()
        fallback_event = event if isinstance(event, Event) else Event()
        return ReportResponse(
            success=False,
            report_text="",
            event=fallback_event,
            school=fallback_school,
            approved=False,
            iterations=0,
            error=str(e),
        )
    finally:
        # Cleanup temporary files (e.g., uploaded photos or audio)
        if cleanup_temp_files and temp_files_to_cleanup:
            logger.info("Cleaning up temporary input files...")
            cleanup_files(temp_files_to_cleanup)



