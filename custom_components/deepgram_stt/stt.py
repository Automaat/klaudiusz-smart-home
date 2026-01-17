"""Deepgram Speech-to-Text platform."""

from __future__ import annotations

import asyncio
import logging
from typing import Any

from deepgram import DeepgramClient, DeepgramClientOptions, LiveOptions, LiveTranscriptionEvents
from homeassistant.components.stt import (
    AudioBitRates,
    AudioChannels,
    AudioCodecs,
    AudioFormats,
    AudioSampleRates,
    SpeechMetadata,
    SpeechResult,
    SpeechResultState,
    SpeechToTextEntity,
)
from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity_platform import AddEntitiesCallback

from .const import (
    CONF_API_KEY,
    CONF_LANGUAGE,
    CONF_MODEL,
    DEFAULT_LANGUAGE,
    DEFAULT_MODEL,
    DOMAIN,
)

_LOGGER = logging.getLogger(__name__)


async def async_setup_entry(
    hass: HomeAssistant,
    config_entry: ConfigEntry,
    async_add_entities: AddEntitiesCallback,
) -> None:
    """Set up Deepgram STT from config entry."""
    async_add_entities([DeepgramSTTEntity(config_entry)])


async def async_setup_platform(
    hass: HomeAssistant,
    config: dict[str, Any],
    async_add_entities: AddEntitiesCallback,
    discovery_info: dict[str, Any] | None = None,
) -> None:
    """Set up Deepgram STT platform from YAML configuration."""
    api_key = hass.data["secrets"].get("deepgram_api_key")
    if not api_key:
        _LOGGER.error("Deepgram API key not found in secrets.yaml")
        return

    entity = DeepgramSTTEntity(None)
    entity._api_key = api_key
    entity._model = config.get(CONF_MODEL, DEFAULT_MODEL)
    entity._language = config.get(CONF_LANGUAGE, DEFAULT_LANGUAGE)
    async_add_entities([entity])


class DeepgramSTTEntity(SpeechToTextEntity):
    """Deepgram Speech-to-Text entity."""

    def __init__(self, config_entry: ConfigEntry | None) -> None:
        """Initialize Deepgram STT."""
        self._attr_name = "Deepgram STT"
        self._attr_unique_id = "deepgram_stt"

        if config_entry:
            self._api_key = config_entry.data.get(CONF_API_KEY)
            self._model = config_entry.data.get(CONF_MODEL, DEFAULT_MODEL)
            self._language = config_entry.data.get(CONF_LANGUAGE, DEFAULT_LANGUAGE)
        else:
            self._api_key = None
            self._model = DEFAULT_MODEL
            self._language = DEFAULT_LANGUAGE

    @property
    def supported_languages(self) -> list[str]:
        """Return supported languages."""
        return ["pl", "en", "de", "es", "fr", "it", "nl", "pt"]

    @property
    def supported_formats(self) -> list[AudioFormats]:
        """Return supported audio formats."""
        return [AudioFormats.WAV]

    @property
    def supported_codecs(self) -> list[AudioCodecs]:
        """Return supported audio codecs."""
        return [AudioCodecs.PCM]

    @property
    def supported_bit_rates(self) -> list[AudioBitRates]:
        """Return supported bit rates."""
        return [AudioBitRates.BITRATE_16]

    @property
    def supported_sample_rates(self) -> list[AudioSampleRates]:
        """Return supported sample rates."""
        return [AudioSampleRates.SAMPLERATE_16000]

    @property
    def supported_channels(self) -> list[AudioChannels]:
        """Return supported audio channels."""
        return [AudioChannels.CHANNEL_MONO]

    async def async_process_audio_stream(
        self, metadata: SpeechMetadata, stream: asyncio.StreamReader
    ) -> SpeechResult:
        """Process audio stream with Deepgram."""
        if not self._api_key:
            _LOGGER.error("Deepgram API key not configured")
            return SpeechResult("", SpeechResultState.ERROR)

        try:
            # Configure Deepgram client
            config = DeepgramClientOptions(
                api_key=self._api_key,
            )
            client = DeepgramClient(self._api_key, config)
            dg_connection = client.listen.websocket.v("1")

            # Storage for transcript
            transcript_parts = []
            final_transcript = ""
            is_final = False
            error_occurred = False

            # Event handlers
            async def on_message(self, result, **kwargs):
                nonlocal transcript_parts, final_transcript, is_final
                sentence = result.channel.alternatives[0].transcript

                if len(sentence) > 0:
                    if result.is_final:
                        final_transcript = sentence
                        is_final = True
                        _LOGGER.debug("Final transcript: %s", sentence)
                    else:
                        transcript_parts.append(sentence)
                        _LOGGER.debug("Interim transcript: %s", sentence)

            async def on_error(self, error, **kwargs):
                nonlocal error_occurred
                _LOGGER.error("Deepgram error: %s", error)
                error_occurred = True

            # Register event handlers
            dg_connection.on(LiveTranscriptionEvents.Transcript, on_message)
            dg_connection.on(LiveTranscriptionEvents.Error, on_error)

            # Configure transcription options
            options = LiveOptions(
                model=self._model,
                language=self._language,
                encoding="linear16",
                sample_rate=16000,
                channels=1,
                interim_results=True,
            )

            # Start connection
            if not await dg_connection.start(options):
                _LOGGER.error("Failed to start Deepgram connection")
                return SpeechResult("", SpeechResultState.ERROR)

            _LOGGER.debug("Deepgram connection started")

            # Stream audio data
            chunk_size = 8192
            try:
                while True:
                    chunk = await stream.read(chunk_size)
                    if not chunk:
                        break

                    dg_connection.send(chunk)
                    await asyncio.sleep(0.01)  # Small delay to prevent overwhelming

                # Signal end of audio
                await dg_connection.finish()

                # Wait for final transcript (with timeout)
                timeout = 5
                start_time = asyncio.get_event_loop().time()
                while not is_final and not error_occurred:
                    if asyncio.get_event_loop().time() - start_time > timeout:
                        _LOGGER.warning("Timeout waiting for final transcript")
                        break
                    await asyncio.sleep(0.1)

            except Exception as e:
                _LOGGER.error("Error streaming audio: %s", e)
                return SpeechResult("", SpeechResultState.ERROR)

            # Return result
            if error_occurred:
                return SpeechResult("", SpeechResultState.ERROR)

            result_text = final_transcript if final_transcript else " ".join(transcript_parts)

            if not result_text:
                _LOGGER.warning("No transcript received")
                return SpeechResult("", SpeechResultState.ERROR)

            _LOGGER.info("Transcription result: %s", result_text)
            return SpeechResult(result_text, SpeechResultState.SUCCESS)

        except Exception as e:
            _LOGGER.error("Deepgram transcription failed: %s", e)
            return SpeechResult("", SpeechResultState.ERROR)
