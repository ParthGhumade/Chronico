# Pipeline Testing & Execution Rules

## 1. Strict Real Execution (No Unauthorized Mocking)
- When instructed to test, run, or verify a pipeline, workflow, or integration, **NEVER fake, mock, stub, or simulate any step** unless explicitly instructed by the user.
- All tests must execute against real code, live models, and actual APIs.

## 2. Immediate Halt on Errors (Fail-Fast)
- If an error occurs at any point during testing — such as:
  - Missing or invalid API keys / credentials
  - Network, timeout, or external API errors (e.g., 401, 403, 429, 500)
  - Code exceptions, import failures, or syntax issues
- **HALT IMMEDIATELY**.
- Do **not** bypass the failed step.
- Do **not** supply synthetic or fallback data to make downstream steps appear functional.
- Do **not** proceed to subsequent stages (e.g., rendering, saving, or reporting success).
- Clearly report the exact point of failure, error message, and required resolution (e.g., "Stopped at Step 2: SARVAM_API_KEY is missing in backend/.env").
