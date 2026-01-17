"""Constants for Deepgram STT integration."""

DOMAIN = "deepgram_stt"

# API Configuration
API_URL = "wss://api.deepgram.com/v1/listen"
DEFAULT_MODEL = "nova-3"
DEFAULT_LANGUAGE = "pl"
DEFAULT_ENCODING = "linear16"
DEFAULT_SAMPLE_RATE = 16000

# Config Keys
CONF_API_KEY = "api_key"
CONF_MODEL = "model"
CONF_LANGUAGE = "language"
