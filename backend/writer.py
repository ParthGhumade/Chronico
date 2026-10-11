import json
import os
from typing import Any
from dotenv import load_dotenv
from google import genai
from google.genai import types

from backend.config import DEFAULT_MODEL_NAME
from backend.date_tool import get_date
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
- Date resolution: When relative time expressions (such as आज, काल, उद्या, परवा, yesterday, today, last week) are mentioned in the narration, use the get_date tool to find the exact calendar date. In the report header and text, always write the concrete calendar date (e.g., दिनांक: 11 ऑक्टोबर 2026) rather than leaving relative words like 'आज' or 'काल'.
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
    Writer Agent function that calls the Gemini API to generate a formal Marathi school event report,
    using the get_date tool to accurately translate relative dates into exact calendar dates.
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
        tools=[get_date],
    )

    chat = client.chats.create(model=resolved_model, config=config)
    response = chat.send_message(prompt)

    return response.text.strip() if response.text else ""
