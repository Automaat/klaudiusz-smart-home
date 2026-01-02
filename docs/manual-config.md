# Manual Configuration Steps

This document contains instructions for configuration that cannot be done
declaratively through NixOS and must be performed manually through the
Home Assistant UI.

## Zigbee Home Automation (ZHA)

**Why manual?** While ZHA integration is enabled declaratively, the initial
setup wizard and device pairing must be done through the Home Assistant UI.

**When to do this:** After initial installation when Connect ZBT-2 dongle is plugged in.

### Initial Setup

1. Plug Connect ZBT-2 dongle into **USB 2.0 port** on homelab (not USB 3.0 - can cause 2.4GHz interference)
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

## Wyoming Protocol Integration

**Why manual?** Wyoming Protocol integration doesn't auto-discover localhost services.
Each Wyoming service (Whisper/Piper) requires explicit host:port configuration through
the UI.

**When to do this:** After initial installation, before setting up voice assistants.
Required for speech-to-text and text-to-speech functionality.

### Wyoming Setup Steps

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

### Wyoming Verify Integration

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

### Troubleshooting

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

### Wyoming Notes

- Services configured in `hosts/homelab/home-assistant/default.nix`
- Whisper model: `small` (good Polish accuracy, ~500MB)
- Piper voice: `pl_PL-darkman-medium` (~50MB)
- Both services localhost-only for security
- Integration persists across HA restarts

## Voice Assistant Preview Edition

**Why manual?** Voice Preview Edition devices use Bluetooth (Improv via BLE) for initial
WiFi provisioning and require UI-based pipeline assignment. The device cannot be fully
configured declaratively.

**When to do this:** After unboxing the Voice Preview Edition device, with Wyoming
Protocol integration configured (see above).

### Prerequisites

- USB-C cable and power supply (not included with device)
- 2.4 GHz WiFi network password
- Home Assistant updated to latest version
- Wyoming integration configured (Whisper + Piper running)
- Admin user logged in

### Voice Assistant Initial Setup

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

### Voice Assistant Notes

- Device requires continuous power (no battery)
- All voice processing local (Whisper/Piper) - no cloud dependency
- ESPHome OTA updates available via **Settings** → **Devices & Services** → **ESPHome**
- Multiple devices supported - assign different pipelines per room

## LG WebOS TV

**Why manual?** WebOS integration requires network discovery or manual IP entry, and
initial pairing requires accepting the connection on the TV screen.

**When to do this:** After adding TV to network, before voice/automation control.

### WebOS TV Setup

**1. Ensure TV is powered on and connected to network:**

- TV must be on same network as Home Assistant
- Enable "Mobile TV On" in TV settings for wake-on-LAN support:
  - **Settings** → **General** → **Mobile TV On** → **Turn On**

**2. Add integration:**

1. Open Home Assistant UI
2. Navigate to **Settings** → **Devices & Services**
3. WebOS TV should appear under **Discovered** (if auto-discovery works)
4. Click **CONFIGURE**
5. **Accept connection prompt on TV screen** (appears within 30 seconds)
6. Device configured and ready

**If WebOS TV doesn't auto-discover:**

1. Click **+ ADD INTEGRATION**
2. Search for and select **LG webOS Smart TV**
3. Enter TV IP address (check router DHCP leases or TV network settings)
4. Click **SUBMIT**
5. **Accept connection prompt on TV screen**

**3. Configure entity name (optional):**

1. In **Devices & Services**, click **LG webOS Smart TV** card
2. Click device name
3. Rename to Polish format: `Telewizor {location}`
   - Example device name: `Telewizor Salon` (creates `media_player.telewizor_salon`)

### WebOS TV Verification

**Check device status:**

1. **Settings** → **Devices & Services** → **LG webOS Smart TV**
2. Device should show as "Available" when TV is on
3. Entities created:
   - `media_player.telewizor_salon` (or custom Polish name)
   - `media_player.{tv_name}_soundbar` (if soundbar connected)

**Test control:**

```bash
# Test service call
ssh homelab "ha-cli service call media_player.turn_on --arguments \
  entity_id=media_player.telewizor_salon"
```

### Voice Control

After setup, TV can be controlled via voice commands:

- Uses `TurnOnMedia`/`TurnOffMedia` intents from `intents.nix`
- Expose entity: **Settings** → **Voice assistants** → **Expose** tab
- Toggle `media_player.telewizor_salon`
- Test commands: *"Włącz telewizor salon"*, *"Wyłącz telewizor"*

### WebOS TV Notes

- TV must support wake-on-LAN for power-on when off
- Integration persists across HA restarts
- Entity unavailable when TV fully powered off (depends on "Mobile TV On" setting)

## Samsung SmartThings

**Why manual?** SmartThings integration uses OAuth2 authentication, requiring login
through Samsung account. Cannot be configured declaratively.

**When to do this:** After setting up SmartThings devices in the SmartThings mobile app.

### Prerequisites

- SmartThings mobile app installed (iOS/Android)
- Samsung account created and logged in
- SmartThings devices added and responding in the app
- SmartThings hub configured (if using Zigbee/Z-Wave devices)
- Home Assistant accessible remotely (required for OAuth callback)

### SmartThings Setup

**1. Configure devices in SmartThings app:**

- Ensure all devices are added to SmartThings app
- Verify devices respond to controls in the app
- Note the "Location" name (usually "Home" or custom location)
- Test device controls before proceeding

**2. Add integration in Home Assistant:**

1. Open Home Assistant UI
2. Navigate to **Settings** → **Devices & Services**
3. Click **+ ADD INTEGRATION**
4. Search for and select **SmartThings**
5. Click **SUBMIT**

**3. OAuth authentication:**

1. Browser redirects to Samsung account login
2. Enter Samsung account credentials (same as SmartThings app)
3. Authorize Home Assistant to access SmartThings:
   - Read device status
   - Send commands to devices
   - Receive device events
4. Click **Allow** or **Authorize**
5. Browser redirects back to Home Assistant

**4. Select location:**

1. Choose SmartThings location from dropdown (e.g., "Home")
2. Click **SUBMIT**
3. Integration begins importing devices

**5. Verify devices:**

1. In **Settings** → **Devices & Services** → **SmartThings**
2. Check devices imported correctly
3. Entities created with format: `{domain}.{device_name}`
   - Example: `light.salon_bulb`, `switch.bedroom_plug`

### SmartThings Configuration

**Rename entities (optional):**

1. Click device in **SmartThings** integration card
2. Click entity name
3. Rename to Polish format for voice control:
   - Example: `Lampa salon` → `light.lampa_salon`
   - Example: `Gniazdko sypialnia` → `switch.gniazdko_sypialnia`

**Expose to voice assistant:**

1. Go to **Settings** → **Voice assistants** → **Expose** tab
2. Toggle SmartThings entities for voice control
3. Polish names work automatically with voice commands

### SmartThings Verification

**Check integration status:**

```bash
ssh homelab "journalctl -u home-assistant | grep -i smartthings"
```

**Test device control:**

```bash
# Test light control
ssh homelab "ha-cli service call light.turn_on --arguments \
  entity_id=light.lampa_salon"

# Test switch control
ssh homelab "ha-cli service call switch.turn_on --arguments \
  entity_id=switch.gniazdko_sypialnia"
```

### Troubleshooting

**Integration setup fails:**

- Verify Home Assistant accessible remotely (OAuth requires callback)
- Check Samsung account credentials
- Ensure devices visible in SmartThings app

**Devices not importing:**

1. Click **CONFIGURE** on SmartThings integration
2. Click **Re-sync devices**
3. Wait 30-60 seconds for import

**Device states not updating:**

- Check SmartThings hub online (if applicable)
- Verify device battery level (for battery-powered devices)
- Check device connectivity in SmartThings app

**OAuth callback fails:**

- Ensure `cloud:` component enabled (already in `default.nix`)
- Check firewall rules allow inbound HTTPS
- Verify external URL configured in HA if using reverse proxy

### SmartThings Notes

- OAuth token refreshes automatically
- Integration supports most SmartThings device types (lights, switches, sensors, locks, thermostats)
- SmartThings hub required for Zigbee/Z-Wave devices (WiFi devices work without hub)
- Cloud-dependent - requires internet connection to SmartThings cloud
- State updates near real-time via webhooks

## Related Documentation

- [ZHA Integration](https://www.home-assistant.io/integrations/zha/)
- [Connect ZBT-2 Product Page](https://www.home-assistant.io/connect/zbt-2/)
- [System Monitor Integration](https://www.home-assistant.io/integrations/systemmonitor/)
- [Voice Preview Edition Getting Started](https://www.home-assistant.io/voice-pe/)
- [Local Voice Assistant Setup](https://www.home-assistant.io/voice_control/voice_remote_local_assistant/)
- [Assist Pipeline Documentation](https://www.home-assistant.io/integrations/assist_pipeline)
- [LG webOS Smart TV Integration](https://www.home-assistant.io/integrations/webostv/)
- [SmartThings Integration](https://www.home-assistant.io/integrations/smartthings/)
