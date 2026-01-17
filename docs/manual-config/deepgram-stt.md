# Deepgram STT Integration

**Why manual?** STT integration no longer supports YAML configuration. Custom STT
components must be configured through the UI.

**When to do this:** After initial installation, when setting up cloud-based speech
recognition. Alternative to local Whisper for faster Polish transcription.

## Prerequisites

- Deepgram API key stored in `secrets/secrets.yaml` as `deepgram_api_key`
- Custom component deployed to `/var/lib/hass/custom_components/deepgram_stt/`
- Home Assistant restarted after deployment

## Setup Steps

**1. Add Deepgram STT Integration:**

1. Open Home Assistant UI
2. Navigate to **Settings** → **Devices & Services**
3. Click **+ ADD INTEGRATION** (bottom-right)
4. Search for and select **Deepgram STT**
5. Integration should auto-configure (no config flow UI)
6. Click **SUBMIT**

**Note:** The integration uses hardcoded settings:

- Model: `nova-3` (best Polish accuracy)
- Language: `pl`
- API key: loaded from secrets via HA

## Verify Integration

**Check integration added:**

1. Go to **Settings** → **Devices & Services**
2. Find **Deepgram STT** card
3. Status should show connected

**Test in Voice Assistant settings:**

1. Go to **Settings** → **Voice assistants**
2. Create or edit a pipeline
3. Verify **Speech-to-text** dropdown includes: `Deepgram STT`
4. Select Deepgram STT as STT engine

**If not available**: Integration not loaded - check custom component and restart HA.

## Troubleshooting

**Integration not found:**

```bash
# Verify custom component exists
ssh homelab "ls -la /var/lib/hass/custom_components/deepgram_stt/"
```

Expected: `__init__.py`, `manifest.json`, `stt.py`, `const.py`

**Integration fails to load:**

```bash
# Check Home Assistant logs for errors
ssh homelab "journalctl -u home-assistant -f | grep deepgram"
```

Look for import errors or API key issues.

**API key not found:**

```bash
# Verify secret exists
ssh homelab "sudo cat /var/lib/hass/secrets.yaml | grep deepgram_api_key"
```

Should show: `deepgram_api_key: dg_xxxxx`

**Service not starting:**

```bash
ssh homelab "sudo systemctl restart home-assistant"
```

## Performance Notes

- Cloud-based: requires internet, ~100-200ms latency
- Faster than local Whisper on Celeron N5095
- Nova-3 model: best Polish accuracy as of 2026
- Streaming WebSocket for real-time transcription
- Fallback: use Whisper for offline operation

## Notes

- Custom component source: `custom_components/deepgram_stt/`
- Deployed via symlink in HA pre-start script
- API key encrypted via sops-nix
- No config flow UI (prototype implementation)
- Integration persists across HA restarts

## Related Documentation

- [Deepgram Nova-3 Docs](https://developers.deepgram.com/docs/nova-3)
- [HA STT Integration](https://www.home-assistant.io/integrations/stt/)
- [Custom Components Guide](https://developers.home-assistant.io/docs/creating_component_index/)
