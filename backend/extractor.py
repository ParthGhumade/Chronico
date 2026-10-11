import json
import logging
import os
import re
import uuid
from datetime import datetime
from dotenv import load_dotenv
from google import genai
from google.genai import types

from backend.config import DEFAULT_MODEL_NAME
from backend.date_tool import get_date
from backend.models import Event

load_dotenv()
logger = logging.getLogger(__name__)

EXTRACTOR_SYSTEM_INSTRUCTION = """You are an administrative data extractor for Marathi school reports.
Given a raw event narration (in Marathi or English), extract the key event metadata into JSON.

Required JSON structure:
{
  "title": "Title of the event in Marathi (e.g., वार्षिक स्नेहसंमेलन, प्रजासत्ताक दिन, क्रीडा स्पर्धा)",
  "date": "Exact calendar date in Marathi (e.g. 11 ऑक्टोबर 2026). When relative dates like आज, काल, उद्या, परवा, yesterday, today, last week are mentioned, call the get_date tool to resolve them to the actual calendar date. NEVER output relative words like 'आज' or 'काल' or 'today' as the date.",
  "venue": "Venue of the event (e.g., शाळा प्रांगण, क्रीडा संकुल)",
  "category": "Category of the event (e.g., सांस्कृतिक, क्रीडा, राष्ट्रीय सण, शैक्षणिक)"
}

If a field is not explicitly mentioned, provide a reasonable default (e.g. venue: "शाळा प्रांगण", category: "शालेय कार्यक्रम").
Output ONLY valid JSON."""


def extract_event_metadata(
    narration: str,
    api_key: str | None = None,
    model_name: str | None = None,
) -> Event:
    """
    Extracts event title, date, venue, and category from raw narration using Gemini,
    utilizing the get_date tool to resolve relative date words (e.g. आज, काल, उद्या)
    to concrete calendar dates.
    """
    event_id = f"evt_{uuid.uuid4().hex[:8]}"
    default_date = datetime.now().strftime("%Y-%m-%d")
    default_event = Event(
        id=event_id,
        title="शालेय कार्यक्रम अहवाल",
        date=default_date,
        venue="शाळा प्रांगण",
        category="कार्यक्रम",
    )

    resolved_api_key = api_key or os.getenv("GEMINI_API_KEY")
    if not resolved_api_key or not narration.strip():
        return default_event

    resolved_model = model_name or DEFAULT_MODEL_NAME

    try:
        client = genai.Client(api_key=resolved_api_key)
        config = types.GenerateContentConfig(
            system_instruction=EXTRACTOR_SYSTEM_INSTRUCTION,
            temperature=0.1,
            tools=[get_date],
        )
        chat = client.chats.create(model=resolved_model, config=config)
        response = chat.send_message(f"Narration:\n{narration}\n\nExtract metadata into valid JSON:")
        if response.text:
            cleaned = re.sub(r"^```(?:json)?\s*", "", response.text.strip(), flags=re.MULTILINE)
            cleaned = re.sub(r"\s*```$", "", cleaned, flags=re.MULTILINE).strip()
            data = json.loads(cleaned)
            return Event(
                id=event_id,
                title=data.get("title") or default_event.title,
                date=data.get("date") or default_event.date,
                venue=data.get("venue") or default_event.venue,
                category=data.get("category") or default_event.category,
            )
    except Exception as e:
        logger.warning(f"Metadata extraction LLM call failed, using default Event: {e}")

    return default_event
