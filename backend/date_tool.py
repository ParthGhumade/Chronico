import json
import logging
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

MARATHI_MONTHS = {
    1: "जानेवारी",
    2: "फेब्रुवारी",
    3: "मार्च",
    4: "एप्रिल",
    5: "मे",
    6: "जून",
    7: "जुलै",
    8: "ऑगस्ट",
    9: "सप्टेंबर",
    10: "ऑक्टोबर",
    11: "नोव्हेंबर",
    12: "डिसेंबर",
}

MARATHI_WEEKDAYS = {
    0: "सोमवार",
    1: "मंगळवार",
    2: "बुधवार",
    3: "गुरुवार",
    4: "शुक्रवार",
    5: "शनिवार",
    6: "रविवार",
}


def format_marathi_date(dt: datetime) -> str:
    """Formats a datetime into formal Marathi date string, e.g. '11 ऑक्टोबर 2026'."""
    month_name = MARATHI_MONTHS.get(dt.month, str(dt.month))
    return f"{dt.day} {month_name} {dt.year}"


def get_date(relative_expression: str = "today", offset_days: int = 0) -> str:
    """
    Translates relative date expressions (like 'today'/'आज', 'yesterday'/'काल', 'tomorrow'/'उद्या',
    'day before yesterday'/'परवा', 'last week'/'मागील आठवड्यात', or numeric day offset)
    into the exact calendar date in both ISO format (YYYY-MM-DD) and formal Marathi format (e.g. '11 ऑक्टोबर 2026').

    Args:
        relative_expression: Relative time reference in Marathi or English
            (e.g., 'आज', 'काल', 'उद्या', 'परवा', 'तेरवा', 'today', 'yesterday', 'tomorrow').
        offset_days: Optional explicit offset in days (0 = today, -1 = yesterday, +1 = tomorrow).

    Returns:
        JSON string containing the resolved date, Marathi date format, day of week, and today's reference date.
    """
    now = datetime.now()
    expr = (relative_expression or "").strip().lower()

    # Determine day offset based on expression or offset_days
    calculated_offset = offset_days

    if calculated_offset == 0 and expr:
        if any(w in expr for w in ["काल", "yesterday", "गेल्या दिवशी", "मागील दिवशी"]):
            calculated_offset = -1
        elif any(w in expr for w in ["परवा", "day before yesterday", "दिवसापूर्वी"]):
            calculated_offset = -2
        elif any(w in expr for w in ["तेरवा"]):
            calculated_offset = -3
        elif any(w in expr for w in ["उद्या", "tomorrow"]):
            calculated_offset = 1
        elif any(w in expr for w in ["आज", "today", "चालू दिवशी"]):
            calculated_offset = 0
        elif any(w in expr for w in ["गेल्या आठवड्यात", "मागील आठवड्यात", "last week"]):
            calculated_offset = -7
        elif any(w in expr for w in ["पुढील आठवड्यात", "next week"]):
            calculated_offset = 7
        elif any(w in expr for w in ["गेल्या महिन्यात", "मागील महिन्यात", "last month"]):
            calculated_offset = -30

    target_dt = now + timedelta(days=calculated_offset)

    result = {
        "status": "success",
        "relative_expression": relative_expression,
        "offset_days": calculated_offset,
        "reference_today_iso": now.strftime("%Y-%m-%d"),
        "reference_today_marathi": format_marathi_date(now),
        "resolved_date_iso": target_dt.strftime("%Y-%m-%d"),
        "resolved_date_marathi": format_marathi_date(target_dt),
        "day_of_week_marathi": MARATHI_WEEKDAYS.get(target_dt.weekday(), ""),
        "formatted_for_report": f"{format_marathi_date(target_dt)} ({MARATHI_WEEKDAYS.get(target_dt.weekday(), '')})",
    }

    logger.info(f"get_date tool called: '{relative_expression}' -> {result['resolved_date_marathi']}")
    return json.dumps(result, ensure_ascii=False)
