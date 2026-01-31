"""Claude Brain integration for Home Assistant."""
import logging
import asyncio
from typing import Final
import aiohttp
import voluptuous as vol

from homeassistant.core import HomeAssistant, ServiceCall
from homeassistant.helpers import config_validation as cv
from homeassistant.helpers.aiohttp_client import async_get_clientsession

from .const import (
    DOMAIN,
    SERVER_URL,
    TIMEOUT,
    INPUT_TEXT_SESSION,
    INPUT_TEXT_RESPONSE,
    INPUT_TEXT_PENDING_ACTION,
    INPUT_BOOLEAN_AWAITING,
)

_LOGGER = logging.getLogger(__name__)

SERVICE_ASK = "ask"
SERVICE_CONFIRM = "confirm"
SERVICE_CANCEL = "cancel"

ASK_SCHEMA = vol.Schema({
    vol.Required("query"): cv.string,
})

async def async_setup(hass: HomeAssistant, config: dict) -> bool:
    """Set up Claude Brain component."""

    async def async_ask_claude(call: ServiceCall) -> None:
        """Ask Claude a question."""
        query = call.data["query"]
        session_id = hass.states.get(INPUT_TEXT_SESSION).state

        session = async_get_clientsession(hass)

        try:
            async with asyncio.timeout(TIMEOUT):
                async with session.post(
                    f"{SERVER_URL}/ask",
                    json={"query": query, "session_id": session_id},
                ) as resp:
                    data = await resp.json()

                    # Update HA state
                    await hass.services.async_call(
                        "input_text", "set_value",
                        {"entity_id": INPUT_TEXT_SESSION, "value": data.get("session_id", "")},
                        blocking=True,
                    )
                    await hass.services.async_call(
                        "input_text", "set_value",
                        {"entity_id": INPUT_TEXT_RESPONSE, "value": data.get("text", "")},
                        blocking=True,
                    )

                    # Handle permission request
                    if data.get("requires_permission"):
                        await hass.services.async_call(
                            "input_text", "set_value",
                            {"entity_id": INPUT_TEXT_PENDING_ACTION, "value": data.get("action_description", "")},
                            blocking=True,
                        )
                        await hass.services.async_call(
                            "input_boolean", "turn_on",
                            {"entity_id": INPUT_BOOLEAN_AWAITING},
                            blocking=True,
                        )
        except asyncio.TimeoutError:
            _LOGGER.error("Timeout calling Claude server")
            await hass.services.async_call(
                "input_text", "set_value",
                {"entity_id": INPUT_TEXT_RESPONSE, "value": "Przepraszam, nie mogę teraz odpowiedzieć"},
                blocking=True,
            )
        except Exception as err:
            _LOGGER.error("Error calling Claude server: %s", err)
            await hass.services.async_call(
                "input_text", "set_value",
                {"entity_id": INPUT_TEXT_RESPONSE, "value": "Przepraszam, wystąpił błąd"},
                blocking=True,
            )

    async def async_confirm_claude(call: ServiceCall) -> None:
        """Confirm pending action."""
        session_id = hass.states.get(INPUT_TEXT_SESSION).state
        session = async_get_clientsession(hass)

        try:
            async with asyncio.timeout(TIMEOUT):
                async with session.post(
                    f"{SERVER_URL}/ask",
                    json={"query": "wykonaj", "session_id": session_id, "confirm_action": True},
                ) as resp:
                    data = await resp.json()
                    await hass.services.async_call(
                        "input_text", "set_value",
                        {"entity_id": INPUT_TEXT_RESPONSE, "value": data.get("text", "")},
                        blocking=True,
                    )
        except Exception as err:
            _LOGGER.error("Error confirming action: %s", err)
        finally:
            # Clear confirmation state
            await hass.services.async_call(
                "input_boolean", "turn_off",
                {"entity_id": INPUT_BOOLEAN_AWAITING},
                blocking=True,
            )
            await hass.services.async_call(
                "input_text", "set_value",
                {"entity_id": INPUT_TEXT_PENDING_ACTION, "value": ""},
                blocking=True,
            )

    async def async_cancel_claude(call: ServiceCall) -> None:
        """Cancel pending action."""
        session_id = hass.states.get(INPUT_TEXT_SESSION).state
        session = async_get_clientsession(hass)

        try:
            async with asyncio.timeout(TIMEOUT):
                async with session.post(
                    f"{SERVER_URL}/cancel",
                    json={"session_id": session_id},
                ) as resp:
                    data = await resp.json()
                    await hass.services.async_call(
                        "input_text", "set_value",
                        {"entity_id": INPUT_TEXT_RESPONSE, "value": data.get("text", "")},
                        blocking=True,
                    )
        except Exception as err:
            _LOGGER.error("Error canceling action: %s", err)
        finally:
            # Clear confirmation state
            await hass.services.async_call(
                "input_boolean", "turn_off",
                {"entity_id": INPUT_BOOLEAN_AWAITING},
                blocking=True,
            )
            await hass.services.async_call(
                "input_text", "set_value",
                {"entity_id": INPUT_TEXT_PENDING_ACTION, "value": ""},
                blocking=True,
            )

    # Register services
    hass.services.async_register(DOMAIN, SERVICE_ASK, async_ask_claude, schema=ASK_SCHEMA)
    hass.services.async_register(DOMAIN, SERVICE_CONFIRM, async_confirm_claude)
    hass.services.async_register(DOMAIN, SERVICE_CANCEL, async_cancel_claude)

    return True
