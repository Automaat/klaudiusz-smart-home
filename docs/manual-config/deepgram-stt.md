# Deepgram Speech-to-Text Manual Configuration

## Overview

Deepgram STT integration provides cloud-based speech-to-text using the Deepgram API.

**Installed declaratively** from <https://github.com/Automaat/deepgram-stt> (v0.1.0)

## Installation

### Auto-Installation (Default)

Integration auto-installed via NixOS symlink to custom_components. No HACS needed.

### Prerequisites

- Deepgram API key from <https://console.deepgram.com/>
- NixOS: API key in `/run/secrets/deepgram-api-key` (sops-encrypted)

### Configuration Steps

1. **Configure integration:**
   - **Settings** > **Devices & Services** > **Add Integration**
   - Search "Deepgram Speech-to-Text"
   - Enter API key (get via SSH: `cat /run/secrets/deepgram-api-key`)
   - Model: `nova-3` (default)
   - Language: `pl` (default)

### Manual Reconfiguration Steps

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

## Switching Between STT Providers

**To use Deepgram STT:**

1. **Settings** > **Voice assistants** > Select assistant
2. **Speech-to-text**: Choose "Deepgram STT"
3. **Save**

**To use Wyoming Faster Whisper:**

1. **Settings** > **Voice assistants** > Select assistant
2. **Speech-to-text**: Choose "faster-whisper" (default)
3. **Save**

Both providers can coexist - switch anytime via voice assistant config.

## Troubleshooting

### Integration doesn't appear in UI

Verify symlink created:

```bash
ssh homelab "ls -la /var/lib/hass/custom_components/deepgram_stt"
```

Should show symlink to Nix store. If missing, rebuild NixOS.

### Integration loads but doesn't configure

Check logs:

```bash
ssh homelab "journalctl -u home-assistant | grep -i deepgram"
```

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
