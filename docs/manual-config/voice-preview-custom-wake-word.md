# Voice Preview Edition - Custom Wake Word Setup

**Why manual?** Adding custom wake word requires ESPHome config modification and OTA firmware
update. The Voice Preview Edition needs to be adopted in ESPHome dashboard to access its
configuration.

**When to do this:** After Voice Preview Edition is working with default wake word (Okay Nabu),
to add custom Polish wake word "Klaudiusz".

## Prerequisites

- Voice Preview Edition connected and working
- Custom wake word model trained (pl_klaudiusz.tflite)
- Model files hosted via HA www directory
- ESPHome service enabled in NixOS config

## Part 1: Access ESPHome Dashboard

**ESPHome runs as NixOS service** (not HA addon - we're on NixOS, not HA OS).

**1. Verify service running:**

```bash
ssh homelab "systemctl status esphome"
```

Should show: `active (running)`

**2. Open dashboard:**

Open in browser: **<http://homelab:6052>** or **<http://192.168.0.241:6052>**

ESPHome dashboard should load showing device management interface.

## Part 2: Adopt Voice Preview Edition

**1. Locate device:**

In ESPHome dashboard, Voice Preview should appear under **"Discovered devices"** section.

**Device name format:** `home-assistant-voice-XXXXXX` (where XXXXXX is MAC address suffix)

**2. Adopt device:**

1. Click **"ADOPT"** on discovered device
2. Enter device name: `voice-preview-klaudiusz`
3. Click **"ADOPT"**
4. Wait for ESPHome to fetch current config (~1 minute)

**If device doesn't appear:**

- Ensure Voice Preview is powered on and connected to WiFi
- Check it appears in **Settings** → **Devices & Services** → **ESPHome**
- Try clicking **"+ NEW DEVICE"** → **"Continue"** → enter IP manually

## Part 3: Add Custom Wake Word

**1. Edit device config:**

1. In ESPHome dashboard, click **"EDIT"** on voice-preview-klaudiusz
2. YAML editor opens with current configuration

**2. Find `micro_wake_word` section:**

Look for existing wake word config (should have default models like okay_nabu).

**3. Add custom model:**

Add to the `models:` list:

```yaml
micro_wake_word:
  models:
    # Existing models (okay_nabu, hey_jarvis, etc.)
    - model: okay_nabu

    # Custom Polish wake word
    - model: http://192.168.0.241:8123/local/wake-words/pl_klaudiusz.json
```

**Full example:**

```yaml
micro_wake_word:
  on_wake_word_detected:
    - voice_assistant.start:

  models:
    - model: okay_nabu
    - model: hey_jarvis
    - model: hey_mycroft
    - model: http://192.168.0.241:8123/local/wake-words/pl_klaudiusz.json
```

**4. Save config:**

Click **"SAVE"** (top-right corner)

## Part 4: Compile and Flash

**1. Validate config:**

1. Click **"VALIDATE"** button
2. Wait for validation (~30 seconds)
3. Check for errors - should show "Configuration is valid!"

**If errors appear:**

- Check URL is correct: `http://192.168.0.241:8123/local/wake-words/pl_klaudiusz.json`
- Verify model files are accessible (test URL in browser)
- Check YAML indentation (use spaces, not tabs)

**2. Install wirelessly (OTA):**

1. Click **"INSTALL"** → **"Wirelessly"**
2. Compilation starts (~5-10 minutes)
   - **Warning:** This is resource-intensive, requires 2GB+ RAM
   - Homelab has 16GB, should handle it fine
3. After compilation, firmware uploads to device (~1 minute)
4. Device restarts automatically

**Progress indicators:**

- **Compiling:** Building firmware with new wake word
- **Uploading:** Sending firmware to device via WiFi
- **SUCCESS:** Device updated and restarted

## Part 5: Configure in Home Assistant

**1. Select custom wake word:**

1. **Settings** → **Devices & Services** → **ESPHome**
2. Click **Voice Preview** device
3. Under **Configuration** → **Słowo aktywacji** (Wake word)
4. Dropdown should now show **"Klaudiusz"** option
5. Select **"Klaudiusz"**
6. **SAVE**

**2. Test wake word:**

1. Stand near Voice Preview Edition
2. Say **"Klaudiusz"** clearly
3. LED ring should light up (listening state)
4. Say voice command: **"Włącz salon"**
5. Should execute command

## Troubleshooting

**Compilation fails with memory error:**

- ESPHome compilation needs 2GB+ RAM
- Homelab has 16GB - should work
- If fails: try compiling on desktop/laptop instead
  - Download ESPHome on Mac: `brew install esphome`
  - Run: `esphome compile voice-preview-klaudiusz.yaml`
  - Upload via ESPHome dashboard

**Model URL not accessible:**

```bash
# Test URL from homelab
curl http://192.168.0.241:8123/local/wake-words/pl_klaudiusz.json

# Should return JSON with model info
# If 404: model files not deployed, rebuild NixOS
```

**Wake word not in dropdown:**

- Wait 1-2 minutes after firmware flash (HA needs to discover)
- Restart Home Assistant: **Settings** → **System** → **Restart**
- Check device page shows firmware updated

**Wake word detection poor:**

- Adjust `probability_cutoff` in pl_klaudiusz.json (lower = more sensitive)
- Current: 0.35, try: 0.25 or 0.20
- Retrain model with more real voice samples (100+ recommended)

**Device offline after flash:**

- Power cycle Voice Preview Edition
- Check WiFi credentials still valid
- Reflash with **"INSTALL"** → **"Plug into this computer"** (USB)

## Verify Success

**Check model loaded:**

```bash
# ESPHome device logs
# In ESPHome dashboard: click device → "LOGS"
# Should show: "Loaded wake word model: klaudiusz"
```

**Test detection:**

1. Say "Klaudiusz" at normal volume
2. LED ring lights up → SUCCESS
3. LED doesn't respond → increase sensitivity or record more samples

## Notes

- First compilation takes 5-10 minutes
- Subsequent updates faster (~3-5 minutes)
- Model updates don't require full reflash - just update JSON manifest
- Voice Preview supports multiple wake words simultaneously
- Can switch between wake words in device settings without reflashing

## Related Documentation

- [ESPHome Micro Wake Word](https://esphome.io/components/micro_wake_word/)
- [Voice Preview Official Guide](https://voice-pe.home-assistant.io/)
- [Custom Wake Word Training](../wake-word-training.md)
