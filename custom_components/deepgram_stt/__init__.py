"""Deepgram Speech-to-Text integration."""

import logging
from pathlib import Path

from homeassistant.config_entries import ConfigEntry
from homeassistant.const import Platform
from homeassistant.core import HomeAssistant

from .const import CONF_API_KEY, CONF_LANGUAGE, CONF_MODEL, DEFAULT_LANGUAGE, DEFAULT_MODEL, DOMAIN

_LOGGER = logging.getLogger(__name__)

PLATFORMS: list[Platform] = [Platform.STT]


async def async_setup(hass: HomeAssistant, config: dict) -> bool:
    """Set up Deepgram STT component."""
    hass.data.setdefault(DOMAIN, {})

    # Auto-create config entry from sops secret if none exists (for declarative NixOS setup)
    # User can still add via UI if needed
    existing_entries = hass.config_entries.async_entries(DOMAIN)
    if not existing_entries:
        sops_secret_path = Path("/run/secrets/deepgram-api-key")

        if sops_secret_path.exists():
            try:
                api_key = await hass.async_add_executor_job(sops_secret_path.read_text)
                api_key = api_key.strip()

                if not api_key:
                    _LOGGER.warning("Deepgram API key is empty")
                    return True

                _LOGGER.info("Auto-configuring Deepgram STT from sops secret")
                hass.async_create_task(
                    hass.config_entries.flow.async_init(
                        DOMAIN,
                        context={"source": "import"},
                        data={
                            CONF_API_KEY: api_key,
                            CONF_MODEL: DEFAULT_MODEL,
                            CONF_LANGUAGE: DEFAULT_LANGUAGE,
                        },
                    )
                )
            except (PermissionError, OSError) as e:
                _LOGGER.warning("Could not auto-configure from sops secret: %s", e)

    return True


async def async_setup_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    """Set up Deepgram STT from config entry."""
    hass.data.setdefault(DOMAIN, {})
    await hass.config_entries.async_forward_entry_setups(entry, PLATFORMS)
    return True


async def async_unload_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    """Unload a config entry."""
    return await hass.config_entries.async_unload_platforms(entry, PLATFORMS)
