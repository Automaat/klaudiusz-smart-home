# Manual Configuration Steps

This document contains instructions for configuration that cannot be done
declaratively through NixOS and must be performed manually through the
Home Assistant UI.

## Zigbee Home Automation (ZHA)

**Why manual?** While ZHA integration is enabled declaratively, the initial
setup wizard and device pairing must be done through the Home Assistant UI.

**When to do this:** After initial installation when Connect ZBT-2 dongle is plugged in.

### Initial Setup

1. Plug Connect ZBT-2 dongle into USB port on homelab
2. Verify device detected: `ssh homelab "ls -la /dev/zigbee"`
3. Open Home Assistant UI
4. Navigate to **Settings** → **Devices & Services**
5. ZHA should appear under **Discovered** (if auto-discovery works)
6. Click **CONFIGURE** and follow setup wizard:
   - **Radio Type**: Auto-detected (EZSP = Silicon Labs)
   - **Serial Device Path**: `/dev/zigbee`
   - **Port Speed**: 115200 (default)
   - Click **Submit**

**If ZHA doesn't auto-discover:**

1. Click **+ ADD INTEGRATION**
2. Search for and select **Zigbee Home Automation**
3. Select `/dev/zigbee` from dropdown
4. Click **Submit**

### Pairing Devices

1. In Home Assistant, go to **Settings** → **Devices & Services**
2. Click **Zigbee Home Automation** card
3. Click **ADD DEVICE** (bottom-right)
4. Enable pairing mode on your Zigbee device:
   - **Bulbs**: Turn on/off 5-6 times rapidly
   - **Sensors**: Press and hold reset button (~5 seconds)
   - **Switches**: Check device manual for pairing mode
5. Wait for device to appear (usually 10-30 seconds)
6. Rename device with Polish format: `{area} - {function}`
   - Example: `Salon - Główne światło`
   - Example: `Sypialnia - Czujnik ruchu`

### Verify Integration

**Check ZHA status:**

```bash
ssh homelab "journalctl -u home-assistant | grep -i zha"
```

**Check device connectivity:**

1. In Home Assistant: **Settings** → **Devices & Services** → **ZHA**
2. Click device → Check **Last Seen** timestamp
3. Healthy devices update within 1-2 minutes

## System Monitor Integration

**Why manual?** Since Home Assistant 2022.12, System Monitor moved from YAML
platform configuration to UI-based integration setup. The old
`platform: systemmonitor` YAML syntax is deprecated.

**When to do this:** After initial installation to monitor system resources (CPU, memory, disk).

### Setup Steps

1. Open Home Assistant UI
2. Navigate to **Settings** → **Devices & Services**
3. Click **+ ADD INTEGRATION**
4. Search for and select **System Monitor**
5. Select resources to monitor:
   - Processor use
   - Memory use percentage
   - Disk use percentage
   - Processor temperature
   - Load (1m, 5m, 15m)

### Notes

- Previously configured via YAML `sensor.platform: systemmonitor` in `hosts/homelab/home-assistant/monitoring.nix`
- Old YAML platform config removed in favor of UI-based integration
- Integration creates entities like `sensor.processor_use`, `sensor.memory_use_percent`
- Existing automations in `automations.nix` and `monitoring.nix` will continue working after manual setup

## Voice Assistant Preview Edition

**Why manual?** Voice Preview Edition devices use Bluetooth (Improv via BLE) for initial WiFi provisioning and require UI-based pipeline assignment. The device cannot be fully configured declaratively.

**When to do this:** After unboxing the Voice Preview Edition device, with Wyoming services (Whisper/Piper) already running.

### Prerequisites

- USB-C cable and power supply (not included with device)
- 2.4 GHz WiFi network password
- Home Assistant updated to latest version
- Wyoming integration configured (Whisper + Piper running)
- Admin user logged in

### Initial Setup

**1. Power on device:**

```bash
# Connect USB-C power supply to Voice Preview Edition
# Device boots and enters pairing mode (LED indicator active)
```

**2. Bluetooth pairing:**

1. In Home Assistant: **Settings** → **Devices & Services**
2. Under **Discovered**, locate `home-assistant-xx Improv via BLE`
3. Click **CONFIGURE**
4. Click **SUBMIT**

**Alternative: Mobile app setup (recommended):**

1. Open Home Assistant Companion app (iOS/Android)
2. Device should auto-discover via Bluetooth
3. Follow in-app wizard for WiFi provisioning

**3. WiFi configuration:**

1. Select your 2.4 GHz WiFi network from list
2. Enter WiFi password
3. Click **SUBMIT**
4. Wait for device to connect (~30 seconds)
5. Device will appear in **Settings** → **Devices & Services** → **ESPHome**

**4. Assign Assist pipeline:**

1. Go to **Settings** → **Voice assistants**
2. Verify pipeline exists with:
   - **Speech-to-text**: Whisper (faster-whisper)
   - **Text-to-speech**: Piper (pl_PL)
   - **Conversation agent**: Home Assistant
3. Click on Voice Preview Edition device settings
4. Select **Assist pipeline**: Choose your Polish pipeline
5. Click **SAVE**

**5. Expose entities to Assist:**

1. Go to **Settings** → **Voice assistants** → **Expose** tab
2. Toggle entities you want voice-controllable
3. Common choices:
   - Lights (all Zigbee bulbs)
   - Switches
   - Scenes
   - Climate controls
4. Entities named in Polish auto-work with voice commands

### Verify Operation

**Test wake word:**

1. Say *"OK Nabu"* near device (default wake word)
2. LED should indicate listening state
3. Say command: *"Włącz salon"*
4. Check response and entity state change

**Check device logs:**

```bash
ssh homelab "journalctl -u home-assistant | grep -i 'voice_assistant\|wyoming'"
```

**Troubleshooting:**

- **Device not discovered**: Ensure Bluetooth enabled on HA host, check `bluetoothctl scan on`
- **WiFi connection fails**: Verify 2.4 GHz network (5 GHz not supported), check signal strength
- **Pipeline not working**: Confirm Wyoming services running: `systemctl status wyoming-*`
- **Commands not recognized**: Check entity exposure, verify Polish pipeline selected

### Advanced Configuration

**Custom wake word (optional):**

1. Install **openWakeWord** add-on from Add-on Store
2. Configure in **Settings** → **Voice assistants** → Pipeline settings
3. Train custom wake word or use pre-trained models

**Audio tuning (via ESPHome):**

- Noise suppression: adjust in device ESPHome config
- Volume multiplier: increase if responses too quiet
- Auto gain: tune for room acoustics

### Notes

- Device requires continuous power (no battery)
- All voice processing local (Whisper/Piper) - no cloud dependency
- ESPHome OTA updates available via **Settings** → **Devices & Services** → **ESPHome**
- Multiple devices supported - assign different pipelines per room

## Related Documentation

- [ZHA Integration](https://www.home-assistant.io/integrations/zha/)
- [Connect ZBT-2 Product Page](https://www.home-assistant.io/connect/zbt-2/)
- [System Monitor Integration](https://www.home-assistant.io/integrations/systemmonitor/)
- [Voice Preview Edition Getting Started](https://www.home-assistant.io/voice-pe/)
- [Local Voice Assistant Setup](https://www.home-assistant.io/voice_control/voice_remote_local_assistant/)
- [Assist Pipeline Documentation](https://www.home-assistant.io/integrations/assist_pipeline)
