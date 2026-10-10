import logging
import time
from typing import Any

from backend.critic import run_critic_agent
from backend.models import Context, PipelineResult, VerificationResult
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

