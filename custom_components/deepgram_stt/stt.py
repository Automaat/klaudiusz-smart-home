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
    AUDIO_CHUNK_SIZE,
    CONF_API_KEY,
    CONF_LANGUAGE,
    CONF_MODEL,
    DEFAULT_ENCODING,
    DEFAULT_LANGUAGE,
    DEFAULT_MODEL,
    DEFAULT_SAMPLE_RATE,
    STREAM_DELAY,
    TRANSCRIPT_TIMEOUT,
)

_LOGGER = logging.getLogger(__name__)


async def async_setup_entry(
    hass: HomeAssistant,
    config_entry: ConfigEntry,
    async_add_entities: AddEntitiesCallback,
) -> None:
    """Set up Deepgram STT from config entry."""
    async_add_entities([DeepgramSTTEntity(config_entry)])


class DeepgramSTTEntity(SpeechToTextEntity):
    """Deepgram Speech-to-Text entity."""

    def __init__(self, config_entry: ConfigEntry) -> None:
        """Initialize Deepgram STT."""
        self._attr_name = "Deepgram STT"
        self._attr_unique_id = "deepgram_stt"
        self._api_key = config_entry.data.get(CONF_API_KEY)
        self._model = config_entry.data.get(CONF_MODEL, DEFAULT_MODEL)
        self._language = config_entry.data.get(CONF_LANGUAGE, DEFAULT_LANGUAGE)
        self.config_entry = config_entry
        self._attr_device_info = None  # No physical device for cloud API

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
            state_lock = asyncio.Lock()

            # Event handlers
            async def on_message(result, **kwargs):
                nonlocal transcript_parts, final_transcript, is_final

                if not result.channel.alternatives:
                    return

                sentence = result.channel.alternatives[0].transcript

                if len(sentence) > 0:
                    async with state_lock:
                        if result.is_final:
                            final_transcript = sentence
                            is_final = True
                            _LOGGER.debug("Final transcript: %s", sentence)
                        else:
                            transcript_parts.append(sentence)
                            _LOGGER.debug("Interim transcript: %s", sentence)

            async def on_error(error, **kwargs):
                nonlocal error_occurred
                async with state_lock:
                    _LOGGER.error("Deepgram error: %s", error)
                    error_occurred = True

            # Register event handlers
            dg_connection.on(LiveTranscriptionEvents.Transcript, on_message)
            dg_connection.on(LiveTranscriptionEvents.Error, on_error)

            # Configure transcription options
            options = LiveOptions(
                model=self._model,
                language=self._language,
                encoding=DEFAULT_ENCODING,
                sample_rate=DEFAULT_SAMPLE_RATE,
                channels=1,
                interim_results=True,
            )

            # Start connection
            if not await dg_connection.start(options):
                _LOGGER.error("Failed to start Deepgram connection")
                return SpeechResult("", SpeechResultState.ERROR)

            _LOGGER.debug("Deepgram connection started")

            # Stream audio data
            try:
                while True:
                    chunk = await stream.read(AUDIO_CHUNK_SIZE)
                    if not chunk:
                        break

                    dg_connection.send(chunk)
                    await asyncio.sleep(STREAM_DELAY)

                # Signal end of audio
                await dg_connection.finish()

                # Wait for final transcript (with timeout)
                start_time = asyncio.get_event_loop().time()
                while True:
                    async with state_lock:
                        if is_final or error_occurred:
                            break
                    if asyncio.get_event_loop().time() - start_time > TRANSCRIPT_TIMEOUT:
                        _LOGGER.warning("Timeout waiting for final transcript")
                        break
                    await asyncio.sleep(0.1)

            except Exception as e:
                _LOGGER.error("Error streaming audio: %s", e)
                return SpeechResult("", SpeechResultState.ERROR)
            finally:
                await dg_connection.finish()

            # Return result
            async with state_lock:
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
