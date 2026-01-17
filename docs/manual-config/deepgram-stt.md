# Deepgram Speech-to-Text Manual Configuration

## Overview

Deepgram STT integration provides cloud-based speech-to-text using the Deepgram API.

## Auto-Configuration (Default)

**The integration auto-configures on first startup** - no manual setup needed.

The integration automatically creates a config entry using the API key from `/run/secrets/deepgram-api-key` (sops-encrypted).

**Verify auto-configuration:**

1. Navigate to **Settings** > **Devices & Services**
2. Look for **Deepgram Speech-to-Text** integration
3. Should show as "Configured"

## Manual Configuration (If Needed)

If auto-configuration fails or you want to reconfigure:

### Prerequisites

- Deepgram API key from <https://console.deepgram.com/>
- In NixOS setup: API key stored in sops secrets

### Setup Steps

1. **Remove existing integration (if any):**
   - Go to **Settings** > **Devices & Services**
   - Find **Deepgram Speech-to-Text**
   - Click three dots > **Delete**

2. **Add integration:**
   - Click **Add Integration**
   - Search for "Deepgram Speech-to-Text"
   - Click on it

3. **Configure:**
   - **API Key**: Enter your Deepgram API key
     - For NixOS setup: `cat /run/secrets/deepgram-api-key` on homelab
   - **Model** (optional): Default is `nova-3`
   - **Language** (optional): Default is `pl` (Polish)

4. **Verify:**
   - Integration should appear in Devices & Services
   - Entity `stt.deepgram_stt` should be available

## Using in Voice Assistant

1. **Navigate to Settings** > **Voice assistants**
2. **Select your assistant** (e.g., "Home Assistant")
3. **Speech-to-text**: Select **Deepgram STT**
4. **Save**

## Troubleshooting

### Integration doesn't appear in UI

Check logs for auto-configuration:

```bash
ssh homelab "journalctl -u home-assistant | grep -i deepgram"
```

Look for:

- "Auto-configuring Deepgram STT from sops secret" (success)
- "Could not auto-configure from sops secret" (failure)

### API key errors

Verify sops secret is readable:

```bash
ssh homelab "cat /run/secrets/deepgram-api-key"
```

Should output valid Deepgram API key (starts with project-specific prefix).

### Integration loads but STT doesn't work

1. Check entity state in **Developer Tools** > **States**
2. Search for `stt.deepgram_stt`
3. Verify "supported_languages" includes `pl`

## Technical Details

- **Integration Type**: Config Flow (UI-based)
- **Platform**: STT (Speech-to-Text)
- **API**: Deepgram Live Transcription WebSocket API
- **Supported Languages**: pl, en, de, es, fr, it, nl, pt
- **Audio Format**: WAV, PCM, 16-bit, 16kHz, mono

## Related Documentation

- [Deepgram API Docs](https://developers.deepgram.com/)
- [HA STT Integration](https://www.home-assistant.io/integrations/stt/)
- [HA Voice Assistants](https://www.home-assistant.io/voice_control/)
