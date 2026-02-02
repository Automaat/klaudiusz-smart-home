# Deepgram Speech-to-Text Manual Configuration

## Overview

Deepgram STT integration provides cloud-based speech-to-text using the Deepgram API.

**Current setup uses HACS version** from <https://github.com/Automaat/deepgram-stt>

## Installation

### Prerequisites

- HACS installed in Home Assistant
- Deepgram API key from <https://console.deepgram.com/>
- NixOS: API key in `/run/secrets/deepgram-api-key` (sops-encrypted)

### HACS Installation Steps

1. **Add custom repository:**
   - Go to **HACS** > **Integrations** > **⋮** (top right) > **Custom repositories**
   - Repository: `https://github.com/Automaat/deepgram-stt`
   - Category: **Integration**
   - Click **Add**

2. **Install integration:**
   - Search for "Deepgram Speech-to-Text"
   - Click **Download**
   - Restart Home Assistant

3. **Configure integration:**
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

## Rollback to NixOS Version

If HACS version has issues:

1. Uncomment symlink in `hosts/homelab/home-assistant/default.nix:546`
2. Uncomment deepgram-sdk in `default.nix:355`
3. Rebuild: `nixos-rebuild switch --flake .#homelab`
4. Remove HACS version via HACS UI
5. Restart Home Assistant

NixOS version auto-configures from sops secret (no UI setup needed).

## Troubleshooting

### Integration doesn't appear after HACS install

Check HACS installation:

```bash
ssh homelab "ls -la /var/lib/hass/custom_components/deepgram_stt"
```

Should show HACS-installed files. If missing, reinstall from HACS.

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
