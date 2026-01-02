# Wyoming Protocol Integration

**Why manual?** Wyoming Protocol integration doesn't auto-discover localhost services.
Each Wyoming service (Whisper/Piper) requires explicit host:port configuration through
the UI.

**When to do this:** After initial installation, before setting up voice assistants.
Required for speech-to-text and text-to-speech functionality.

## Setup Steps

**1. Add Whisper (Speech-to-Text):**

1. Open Home Assistant UI
2. Navigate to **Settings** → **Devices & Services**
3. Click **+ ADD INTEGRATION** (bottom-right)
4. Search for and select **Wyoming Protocol**
5. Configure connection:
   - **Host**: `127.0.0.1`
   - **Port**: `10300`
6. Click **SUBMIT**
7. Integration should discover: **"faster-whisper (pl)"**

**2. Add Piper (Text-to-Speech):**

1. Click **+ ADD INTEGRATION** again
2. Search for and select **Wyoming Protocol**
3. Configure connection:
   - **Host**: `127.0.0.1`
   - **Port**: `10200`
4. Click **SUBMIT**
5. Integration should discover: **"piper (pl_PL-darkman-medium)"**

## Verify Integration

**Check services discovered:**

```bash
ssh homelab "systemctl status wyoming-faster-whisper-default wyoming-piper-default"
```

Both services should show `active (running)`.

**Test in Voice Assistant settings:**

1. Go to **Settings** → **Voice assistants**
2. Create or edit a pipeline
3. Verify dropdowns populated:
   - **Speech-to-text**: `faster-whisper (pl)` available
   - **Text-to-speech**: `piper (pl_PL-darkman-medium)` available

**If dropdowns show "none"**: Wyoming integrations not added - repeat setup steps above.

## Troubleshooting

**Integration setup fails:**

```bash
# Verify services listening on correct ports
ssh homelab "ss -tlnp | grep -E '10200|10300'"
```

Expected output:

```text
tcp   LISTEN  0  5  127.0.0.1:10200  *:*  users:(("wyoming-piper"))
tcp   LISTEN  0  5  127.0.0.1:10300  *:*  users:(("wyoming-faster"))
```

**Service not running:**

```bash
ssh homelab "sudo systemctl restart wyoming-faster-whisper-default wyoming-piper-default"
```

## Notes

- Services configured in `hosts/homelab/home-assistant/default.nix`
- Whisper model: `small` (good Polish accuracy, ~500MB)
- Piper voice: `pl_PL-darkman-medium` (~50MB)
- Both services localhost-only for security
- Integration persists across HA restarts

## Related Documentation

- [Local Voice Assistant Setup](https://www.home-assistant.io/voice_control/voice_remote_local_assistant/)
- [Assist Pipeline Documentation](https://www.home-assistant.io/integrations/assist_pipeline)
