# Aqara FP2 Presence Sensor

**Why manual?** FP2 requires zone configuration in Aqara app and HomeKit pairing through UI.
Zone detection settings cannot be configured declaratively.

**When to do this:** After configuring zones in Aqara app, before using presence detection
in automations.

## Prerequisites

- Aqara FP2 powered and connected to WiFi
- Zones configured in Aqara app
- Device added to Apple Home (automatic via Aqara app)
- HomeKit Controller integration enabled in HA config

## Setup Steps

### 1. Configure zones in Aqara app (FIRST)

1. Download **Aqara Home** app (iOS/Android)
2. Add FP2 to app following manufacturer instructions
3. Configure detection zones:
   - **Settings** → **Detection Zones**
   - Define room areas for presence tracking
   - Adjust sensitivity and interference reduction
4. Settings sync to HomeKit automatically

### 2. Remove from Apple Home

1. Open **Apple Home** app
2. Long-press FP2 device
3. Scroll down → **Remove Accessory**
4. Confirm removal

**Note:** Aqara app forces FP2 to join HomeKit. Must remove before HA pairing.

### 3. Add to Home Assistant

1. Open Home Assistant UI
2. Navigate to **Settings** → **Devices & Services**
3. FP2 should appear under **Discovered**
4. Click **CONFIGURE**
5. Enter **HomeKit pairing code** (on device label or in Aqara app)
6. Click **SUBMIT**
7. Device configured with all zones from Aqara app

**If FP2 doesn't auto-discover:**

1. Click **+ ADD INTEGRATION**
2. Search for and select **HomeKit Controller**
3. Click **SUBMIT**
4. Put FP2 in pairing mode (hold reset button ~5 seconds)
5. Enter pairing code when prompted

## Verify Integration

### Check device entities

1. **Settings** → **Devices & Services** → **HomeKit Controller**
2. Click FP2 device
3. Entities created per zone:
   - `binary_sensor.fp2_{zone}_occupancy` (presence detected)
   - `sensor.fp2_{zone}_motion` (motion activity)
   - Additional zones appear as separate entities

### Test presence detection

1. Walk into configured zone
2. Check entity state updates in real-time
3. Verify zone boundaries match Aqara app config

## Editing Zones Later

**To modify zones after HA integration:**

1. Re-install Aqara Home app
2. Device still accessible in app (doesn't need re-pairing)
3. Edit zones in **Detection Zones** settings
4. Changes sync to HA automatically (may take 1-2 minutes)
5. No need to re-pair with HA

## Notes

- WiFi-based (2.4 GHz required)
- No hub required
- Local control via HomeKit protocol
- Zones persist across HA restarts
- Can remove Aqara app after initial setup (re-install only to edit zones)
- Multiple FP2 sensors: repeat workflow for each device

## Troubleshooting

### FP2 not discovered

```bash
# Check HomeKit Controller integration enabled
ssh homelab "journalctl -u home-assistant | grep -i homekit"
```

### Zones not appearing

- Verify zones configured in Aqara app before pairing
- Remove and re-pair FP2 to sync latest zone config

### Presence detection delayed

- Adjust sensitivity in Aqara app
- Check WiFi signal strength (Settings in Aqara app)

## Related Documentation

- [HomeKit Controller Integration](https://www.home-assistant.io/integrations/homekit_controller/)
- [Aqara FP2 Product Page](https://www.aqara.com/us/product/presence-sensor-fp2/)
- [Derek Seaman's FP2 Setup Guide](https://www.derekseaman.com/2023/04/home-assistant-setting-up-the-aqara-fp2-presence-sensor.html)
