"""Gemini API key retrieval from environment."""

import os


def get_gemini_api_key() -> str:
    """Get Gemini API key from environment.

    Checks NANO_BANANA_API_KEY first (preferred), then falls back to GEMINI_API_KEY.

    Returns:
        The API key string

    Raises:
        EnvironmentError: If neither API key is set
    """
    # Prefer NANO_BANANA_API_KEY (always available)
    api_key = os.environ.get("NANO_BANANA_API_KEY")
    if api_key:
        return api_key

    # Fall back to GEMINI_API_KEY for backwards compatibility
    api_key = os.environ.get("GEMINI_API_KEY")
    if api_key:
        return api_key

    raise EnvironmentError(
        "NANO_BANANA_API_KEY or GEMINI_API_KEY not set in environment"
    )
