"""Deepgram Speech-to-Text integration."""

import logging
from pathlib import Path

from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.discovery import async_load_platform

from .const import CONF_API_KEY, DOMAIN

_LOGGER = logging.getLogger(__name__)


async def async_setup(hass: HomeAssistant, config: dict) -> bool:
    """Set up Deepgram STT from configuration.yaml."""
    hass.data.setdefault(DOMAIN, {})

    # Load STT platform if integration is configured.
    # Modern Home Assistant doesn't support YAML STT configuration directly,
    # so we use discovery helper to bridge YAML config to platform (PR #313).
    if DOMAIN in config:
        # Read API key from sops secret (not secrets.yaml - avoid circular dependency)
        sops_secret_path = Path("/run/secrets/deepgram-api-key")

        try:
            api_key = sops_secret_path.read_text().strip()
        except (FileNotFoundError, PermissionError) as e:
            _LOGGER.error("Failed to read Deepgram API key from %s: %s", sops_secret_path, e)
            return False

        # Pass YAML config + API key to platform via discovery_info
        discovery_info = {
            **config.get(DOMAIN, {}),
            CONF_API_KEY: api_key,
        }
        await async_load_platform(hass, "stt", DOMAIN, discovery_info, config)

    return True


async def async_setup_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    """Set up Deepgram STT from config entry."""
    hass.data.setdefault(DOMAIN, {})
    return True


async def async_unload_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    """Unload a config entry."""
    return True
