import os

# Default model used across all agents if not overridden
DEFAULT_MODEL_NAME = os.getenv("GEMINI_MODEL", "gemma-4-31b-it")
