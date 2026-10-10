import json
import os
from typing import Any
from dotenv import load_dotenv
from google import genai
from google.genai import types

from backend.config import DEFAULT_MODEL_NAME
from backend.models import Context

load_dotenv()

CRITIC_SYSTEM_INSTRUCTION = """You are an expert Marathi administrative editor.

Your responsibility is to review the verified event report and polish its formal Marathi grammar, administrative tone, sentence flow, readability, and structural formatting.

STRICT CONSTRAINTS:
- You MUST NOT modify, add, or delete any facts, names, dates, numbers, venues, titles, or event activities.
- Preserve all factual content with 100% precision.

RULE ON EDITS:
- IF AND ONLY IF changes are needed to fix grammatical errors, awkward sentence structures, or informal tone, return the polished report.
- IF NO changes are needed (the report is already grammatically accurate, readable, and formally structured), return the EXACT original report text unchanged.

OUTPUT:
Return ONLY the report text itself. Do not add introductory or concluding remarks, explanations, or meta-comments."""


def run_critic_agent(
    verified_report: str,
    context: Context | dict[str, Any] | None = None,
    api_key: str | None = None,
    model_name: str | None = None,
) -> str:
    """
    Critic Agent function that checks and polishes formal Marathi grammar, administrative tone,
    and structure if and only if changes are needed, without altering any facts.

    Args:
        verified_report: The factual report string approved by the Verifier Agent.
        context: Optional Context object for reference.
        api_key: Optional explicit Gemini API key.
        model_name: Optional Gemini model name.

    Returns:
        Polished Marathi event report string (or original string if no edits were necessary).
    """
    resolved_api_key = api_key or os.getenv("GEMINI_API_KEY")
    if not resolved_api_key:
        raise ValueError(
            "Gemini API key is required. Please set GEMINI_API_KEY environment variable or pass api_key."
        )

    resolved_model = model_name or DEFAULT_MODEL_NAME

    context_info = ""
    if context:
        if isinstance(context, Context):
            context_dict = context.model_dump()
        else:
            context_dict = context
        context_info = f"\n\nReference Context:\n{json.dumps(context_dict, ensure_ascii=False, indent=2)}"

    prompt = f"""Verified Report to Review:
{verified_report}{context_info}

Review the report above. Improve grammar, official wording, and sentence structure IF AND ONLY IF changes are required. Do not change any facts, dates, names, or numbers."""

    client = genai.Client(api_key=resolved_api_key)

    config = types.GenerateContentConfig(
        system_instruction=CRITIC_SYSTEM_INSTRUCTION,
        temperature=0.2,  # Low temperature for precise editing without creative additions
    )

    response = client.models.generate_content(
        model=resolved_model,
        contents=prompt,
        config=config,
    )

    edited_report = response.text.strip() if response.text else verified_report
    return edited_report
