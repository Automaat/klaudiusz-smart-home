# Aqara FP300 Presence Sensor

## Overview

Aqara FP300 multi-sensor with mmWave presence detection, PIR motion, temperature, humidity, and illuminance sensors. Supports Zigbee (via ZHA custom quirk) and Matter/Thread.

## Why Manual Configuration

- Device must be flashed to Zigbee firmware using Aqara app (ships with Thread/Matter)
- ZHA pairing requires GUI interaction
- Device re-pairing may be needed for full quirk activation
- Firmware updates require Aqara app (Zigbee2MQTT OTA not yet supported)

## Prerequisites

- Aqara app installed on mobile device
- FP300 with battery tab pulled (triggers pairing mode)
- ZHA integration enabled with custom quirks (configured declaratively)

## Setup Process

### 1. Flash to Zigbee Firmware

**Initial state:** Device ships with Thread/Matter firmware

1. Pull battery tab on FP300
2. Open Aqara app
3. App auto-detects FP300
4. Tap device in app
5. Select **Zigbee protocol**
6. Confirm flash operation
7. Wait ~2 minutes for download and flash

**Result:** Device reboots with Zigbee firmware, enters pairing mode

### 2. Pair with ZHA

**Timing:** Device auto-enters pairing mode after flash

1. In Home Assistant: **Settings → Devices & Services → ZHA**
2. Click **Add device** or **Configure → Add devices via this device**
3. Click **Permit join** (enables pairing for 60 seconds)
4. FP300 should appear within seconds
5. Follow on-screen prompts to complete pairing

**Expected entities:**
- Binary sensor: Presence (main occupancy)
- Binary sensor: PIR detection (diagnostic, initially disabled)
- Sensor: Target distance (diagnostic)
- Sensor: Temperature, Humidity, Illuminance
- Number: Absence delay timer, PIR detection interval
- Enum: Motion sensitivity, Presence detection options
- Switch: Detection range segments (0-1m, 1-2m, 2-3m, 3-4m, 4-5m, 5-6m)
- Switch: AI interference self-ID, AI adaptive sensitivity
- Button: Start spatial learning, Restart device, Track target distance

### 3. Verify Quirk Activation

**Check entities count:** 30+ entities expected (vs ~5 without quirk)

**If entities missing:**
1. Remove device from ZHA: **Settings → Devices & Services → ZHA → {Device} → Delete**
2. Factory reset FP300 (hold button 10+ seconds until LED flashes)
3. Re-pair device (repeat Step 2)

**Why re-pairing helps:** Quirks activate during initial device interview

## Configuration

### Detection Range

FP300 detects presence in 6 configurable 1-meter segments (0-6m total):

- Enable/disable each segment via switches
- Reduces false positives by limiting detection area
- Configure via GUI: **Device page → Detection range 0-1 m** (etc.)

### Motion Sensitivity

- **Low:** Fewer false positives, may miss subtle motion
- **Medium:** Balanced (recommended)
- **High:** Maximum sensitivity, more false positives

### Presence Detection Mode

- **Both:** mmWave + PIR (recommended, best accuracy)
- **mmWave only:** Detects stationary presence
- **PIR only:** Motion detection only

### Absence Delay

Time (seconds) after motion stops before marking absent:
- Min: 10s, Max: 300s, Step: 5s
- Higher values reduce state flicker
- Lower values improve responsiveness

## Battery-Powered Device Notes

**Critical:** FP300 sleeps most of the time to conserve battery

**Symptom:** `NWK_NO_ROUTE` errors when changing settings

**Solution:** Press button on FP300 to wake before setting parameters

## Firmware Updates

**Current version:** v5841 (Zigbee, Jan 2026)

**Update method:**
1. Open Aqara app
2. Select device
3. Check for firmware updates
4. Update one by one (no batch OTA)

**Note:** Zigbee2MQTT OTA not yet supported for FP300

## Troubleshooting

### Device Not Appearing in ZHA

- Verify Zigbee firmware (not Thread/Matter)
- Check ZHA permit join is active
- Press FP300 button to re-enter pairing mode
- Check Zigbee coordinator range

### Missing Entities (Only 5 Entities)

- Quirk not applied during pairing
- **Solution:** Remove device, factory reset, re-pair

### Settings Changes Fail

- Device asleep (battery saving)
- **Solution:** Press button to wake, then retry

### Poor Detection Accuracy

- Adjust detection range segments
- Enable AI adaptive sensitivity
- Enable AI interference self-identification
- Use "Both" detection mode (mmWave + PIR)

## Related Documentation

- [ZHA Integration](https://www.home-assistant.io/integrations/zha/)
- [Aqara FP300 ZHA Quirk PR](https://github.com/zigpy/zha-device-handlers/pull/4504)
- [Custom ZHA Quirks Installation](https://meshstack.de/post/home-assistant/zha-custom-quirks/)

## Technical Details

**Model:** `lumi.sensor_occupy.agl8`
**Manufacturer:** Aqara
**Zigbee quirk:** `hosts/homelab/home-assistant/custom_zha_quirks/aqara_fp300.py`
**Device class:** Battery-powered multi-sensor
**Communication:** Zigbee 3.0 (802.15.4)
