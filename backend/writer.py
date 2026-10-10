import json
import os
from typing import Any
from dotenv import load_dotenv
from google import genai
from google.genai import types

from backend.config import DEFAULT_MODEL_NAME
from backend.models import Context

# Load environment variables from .env file if present
load_dotenv()

WRITER_SYSTEM_INSTRUCTION = """You are an expert Marathi administrative report writer.

Your responsibility is to convert rough event narration into a formal school event report.

Objectives:
- Preserve facts.
- Do not invent information.
- Use official Marathi.
- Use school information when relevant.
- If uncertain, omit rather than hallucinate.

Output:
Plain Marathi report."""


def run_writer_agent(
    context: Context | dict[str, Any],
    retry_issues: list[str] | str | None = None,
    current_draft: str | None = None,
    api_key: str | None = None,
    model_name: str | None = None,
) -> str:
    """
    Writer Agent function that calls the Gemini API to generate a formal Marathi school event report.

    Args:
        context: The shared context object (Context Pydantic model or dict) containing school, event, photo details, and raw narration.
        retry_issues: Optional list of issues or feedback string from the Verifier agent for retry runs.
        current_draft: Optional current draft report being corrected during a retry run.
        api_key: Optional explicit Gemini API key. Defaults to GEMINI_API_KEY env var.
        model_name: Optional Gemini model name. Defaults to GEMINI_MODEL env var or 'gemini-2.5-flash'.

    Returns:
        Generated plain Marathi event report string.
    """
    resolved_api_key = api_key or os.getenv("GEMINI_API_KEY")
    if not resolved_api_key:
        raise ValueError(
            "Gemini API key is required. Please set GEMINI_API_KEY environment variable or pass api_key."
        )

    resolved_model = model_name or DEFAULT_MODEL_NAME

    # Serialize context to readable JSON string
    if isinstance(context, Context):
        context_dict = context.model_dump()
    else:
        context_dict = context

    context_str = json.dumps(context_dict, ensure_ascii=False, indent=2)

    # Build prompt based on whether this is a first run or a retry
    if retry_issues:
        if isinstance(retry_issues, list):
            issues_formatted = "\n".join(f"- {issue}" for issue in retry_issues)
        else:
            issues_formatted = str(retry_issues)

        prompt = f"""Shared Context:
{context_str}

Current Draft:
{current_draft or ""}

The verifier found issues in the report.
Fix only the listed issues.
Do not rewrite unrelated sections.
Do not introduce new facts.

Verifier Feedback:
{issues_formatted}"""
    else:
        prompt = f"""Shared Context:
{context_str}

Please convert the narration and context above into a formal Marathi school event report."""

    client = genai.Client(api_key=resolved_api_key)

    config = types.GenerateContentConfig(
        system_instruction=WRITER_SYSTEM_INSTRUCTION,
        temperature=0.6,  # Medium temperature as per PROMPTS.md specification
    )

    response = client.models.generate_content(
        model=resolved_model,
        contents=prompt,
        config=config,
    )

    return response.text.strip() if response.text else ""
