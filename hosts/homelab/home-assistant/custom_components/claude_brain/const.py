"""Constants for Claude Brain integration."""
from typing import Final

DOMAIN: Final = "claude_brain"
SERVER_URL: Final = "http://192.168.20.107:8742"
TIMEOUT: Final = 10

INPUT_TEXT_SESSION: Final = "input_text.claude_session"
INPUT_TEXT_RESPONSE: Final = "input_text.claude_response"
INPUT_TEXT_PENDING_ACTION: Final = "input_text.claude_pending_action"
INPUT_BOOLEAN_AWAITING: Final = "input_boolean.claude_awaiting_confirmation"
