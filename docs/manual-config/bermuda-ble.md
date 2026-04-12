# Bermuda BLE Trilateration - Manual Configuration

## Why Manual Configuration?

Bermuda BLE requires GUI setup for:

- BLE device discovery (MAC addresses unknown until scanned)
- iOS Private BLE Device configuration (IRK extraction from HA Companion app)
- Device tracker entity linking to person entities
- Bluetooth adapter area assignment (built-in hci0 + any ESP32 proxies)

These settings involve runtime device discovery and user-specific credentials that cannot be declared in NixOS configuration.

---

## When to Perform Setup

**Prerequisites:**

1. NixOS deployment complete (Bermuda custom component symlinked)
2. ESP32 Bluetooth proxies flashed and adopted (if using proxies; see [esphome-bluetooth-proxy.md](esphome-bluetooth-proxy.md))
3. HA Companion app installed on tracked devices (iPhones/Apple Watches)
4. BLE enabled in HA Companion app settings

**Timing:** After Phase 1 (infrastructure) deployment, before enabling auto-mode automations.

---

## Setup Steps

### 1. Add Bermuda Integration

1. Navigate to **Settings → Devices & Services → Add Integration**
2. Search for "Bermuda BLE Trilateration"
3. Click **Add** (no configuration required at this step)
4. Bermuda will auto-discover BLE devices in range

**Verification:**

- Integration appears in **Settings → Devices & Services**
- Bermuda diagnostics page shows detected BLE devices (`sensor.bermuda_*_distance`, `device_tracker.*_area`)

---

### 2. Configure Private BLE Device (iOS)

iOS devices use randomized MAC addresses (Private Bluetooth). To track iPhones/Apple Watches:

1. Navigate to **Settings → Devices & Services → Add Integration**
2. Search for "Private BLE Device"
3. **Extract IRK from HA Companion App:**
   - Open HA Companion app on iPhone
   - Go to **Settings → Companion App → Debugging → BLE Transmitter**
   - Copy the **IRK** (Identity Resolving Key) hex string
4. Paste IRK into Private BLE Device integration
5. Assign a friendly name (e.g., "Marcin iPhone", "Ewa Watch")
6. Repeat for each iOS device

**Verification:**

- `device_tracker.{device}_ble` entity appears
- Entity state updates when device moves between rooms

---

### 3. Create Person Entities

1. Navigate to **Settings → People → Add Person**
2. Create person: **marcin**
   - Select device trackers:
     - `device_tracker.marcin_iphone_ble` (or actual entity name after Bermuda setup)
     - `device_tracker.marcin_watch_ble` (if using Apple Watch)
3. Create person: **ewa**
   - Link: `device_tracker.ewa_iphone_ble`, `device_tracker.ewa_watch_ble`

**Verification:**

- Person entities: `person.marcin`, `person.ewa`
- State shows "home" when BLE in range

---

### 4. Update Nix Configuration with Actual Entity IDs

After Bermuda creates device_tracker entities, update template sensors:

**File:** `hosts/homelab/home-assistant/sensors.nix`

Find the person location sensors (around line 105) and update:

```nix

{
  trigger = [
    { platform = "state"; entity_id = "sensor.bermuda_marcin_iphone_area"; } # Replace with actual entity
    { platform = "state"; entity_id = "binary_sensor.presence_sensor_presence"; }
    { platform = "state"; entity_id = "binary_sensor.presence_sensor_fp2_b63f_presence_sensor_2"; }
  ];
  sensor = [
    {
      name = "Marcin Current Room";
      unique_id = "marcin_current_room";
      state = ''
        {% set bermuda = states('sensor.bermuda_marcin_iphone_area') %} {# Replace entity #}
        {% set bathroom_mmwave = is_state('binary_sensor.presence_sensor_presence', 'on') %}
        {% set kitchen_mmwave = is_state('binary_sensor.presence_sensor_fp2_b63f_presence_sensor_2', 'on') %}
        {% if bathroom_mmwave %}bathroom
        {% elif kitchen_mmwave %}kitchen
        {% elif bermuda not in ['unknown', 'unavailable'] %}{{ bermuda }}
        {% else %}{{ states('sensor.marcin_current_room') }}{% endif %}
      '';
      # ...
    }
    # Repeat for Ewa
  ];
}

```

**Update "Anyone Home" sensors** (around line 145):

```nix

{
  sensor = [
    {
      name = "Anyone Home";
      unique_id = "anyone_home";
      state = "{{ is_state('person.marcin', 'home') or is_state('person.ewa', 'home') }}";
    }
  ];
  binary_sensor = [
    {
      name = "Anyone Home";
      unique_id = "anyone_home_binary";
      state = "{{ is_state('person.marcin', 'home') or is_state('person.ewa', 'home') }}";
    }
  ];
}

```

**Rebuild and deploy:**

```bash

git add hosts/homelab/home-assistant/sensors.nix
git commit -s -S -m "fix: update Bermuda entity IDs for person tracking"
git push

```

CI will test and deploy to production.

---

### 5. Assign Bluetooth Adapters to Areas (Critical)

Bermuda requires ALL Bluetooth adapters to have area assignments for trilateration.

**Built-in Bluetooth Adapter (hci0):**

The homelab server's built-in Bluetooth adapter (Blackview MP60 Bluetooth 4.2) must be assigned to the server's physical location:

1. Navigate to **Settings → Devices & Services → Bluetooth**
2. Click **hci0** device (MAC: 8C:EA:12:99:67:77)
3. Click **Settings** (pencil/gear icon)
4. **Assign to Area:** Select room where homelab server is physically located (e.g., "Biuro", "Salon")

**ESP32 Bluetooth Proxies (if using):**

If using ESP32 BLE proxies, assign each to its physical location:

1. Navigate to **Settings → Devices & Services → ESPHome**
2. For each ESP32 proxy:
   - Click device → **Settings** (gear icon)
   - **Assign to Area:** Select room (e.g., "Salon", "Sypialnia", "Biuro", "Łazienka")
3. Ensure area names match HA GUI areas (Bermuda uses `area_id()` lookups)

**Verification:**

- Bermuda diagnostics shows area assignments for ALL adapters (hci0 + any proxies)
- `sensor.bermuda_*_area` entities report correct room names
- No warnings about missing area assignments

---

### 6. Enable Auto-Mode Automations (Optional)

After person tracking works:

**File:** `hosts/homelab/home-assistant/areas/system.nix`

Uncomment auto away mode automations (around line 287):

```nix

{
  id = "away_mode_auto_enable";
  alias = "System - Enable away mode when both leave";
  trigger = [{
    platform = "state";
    entity_id = "binary_sensor.anyone_home";
    to = "off";
    for = "00:15:00";
  }];
  action = [
    { service = "input_boolean.turn_on"; target.entity_id = "input_boolean.away_mode"; }
    { service = "light.turn_off"; target.entity_id = "all"; }
  ];
}
# ... also uncomment away_mode_auto_disable

```

**File:** `hosts/homelab/home-assistant/areas/bedroom.nix`

Uncomment auto sleep mode automations (around line 95):

```nix

{
  id = "sleep_mode_auto_enable";
  alias = "Bedroom - Enable sleep mode when both in bed";
  # ... (see bedroom.nix for full config)
}
# ... also uncomment sleep_mode_auto_disable

```

**Rebuild and deploy after uncommenting.**

---

## Verification Steps

### Test Person Tracking

1. **Walk between rooms with iPhone:**
   - Move from bathroom → kitchen → bedroom
2. **Check sensor updates:**
   - Developer Tools → States → `sensor.marcin_current_room`
   - State should change to current room within 10-30 seconds
3. **Verify mmWave priority:**
   - Enter bathroom (mmWave present)
   - `sensor.marcin_current_room` should be "bathroom" (source: mmwave, confidence: high)
   - BLE may report different room (lower confidence) → mmWave wins

### Test Voice Commands

1. Trigger voice assistant (say "hey, asystent")
2. Ask: **"Gdzie jest Marcin?"**
3. Expected response:
   - High confidence: "Marcin jest w bathroom"
   - Low confidence: "Ostatnio widziałem Marcina w kitchen"

### Test Auto-Modes (if enabled)

**Away mode:**

1. Both persons leave home (BLE out of range)
2. Wait 15 minutes
3. Verify: `input_boolean.away_mode` turns on automatically

**Sleep mode:**

1. Both persons in bedroom after 21:00
2. Wait 5 minutes
3. Verify: `input_boolean.sleep_mode` turns on automatically

---

## Troubleshooting

### BLE Devices Not Detected

**Symptoms:** Bermuda diagnostics empty, no `device_tracker.*_ble` entities

**Fixes:**

1. Check HA Companion app BLE Transmitter enabled (Settings → Debugging)
2. Verify BLE range (max ~10m, walls reduce signal)
3. Check Bluetooth adapter status: `bluetoothctl power on`
4. Restart HA: `sudo systemctl restart home-assistant`

### iOS Private Address Issues

**Symptoms:** device_tracker entity shows "unavailable" despite phone nearby

**Fixes:**

1. Re-extract IRK from HA Companion app (may change after iOS updates)
2. Delete old Private BLE Device integration, re-add with new IRK
3. Verify iPhone Bluetooth Privacy settings (Settings → Bluetooth → device → Forget/Re-pair if needed)

### Poor Trilateration Accuracy

**Symptoms:** `sensor.bermuda_*_area` reports wrong room frequently

**Fixes:**

1. Add more ESP32 Bluetooth proxies (aim for 1 per room)
2. Place proxies at different heights (desk, ceiling, floor variations improve accuracy)
3. Check for BLE interference (2.4GHz WiFi, microwaves, USB3 devices)
4. Increase Bermuda `rssi_tolerance` setting (Bermuda integration config)

### Person Entity Not Updating

**Symptoms:** `person.marcin` stuck at "home" despite leaving

**Fixes:**

1. Check device_tracker entity state (should be "not_home")
2. Verify person entity linked to correct device_tracker (Settings → People)
3. Check Bermuda `away_timeout` setting (default 180s)
4. Test with Developer Tools → Services → `device_tracker.see` to manually update

---

## Related Documentation

- [ESPHome Bluetooth Proxy Setup](esphome-bluetooth-proxy.md) - ESP32 proxy configuration
- [Bermuda GitHub](https://github.com/agittins/bermuda) - Integration source and diagnostics
- [HA Private BLE Device](https://www.home-assistant.io/integrations/private_ble_device/) - iOS IRK extraction guide
- [HA Person Integration](https://www.home-assistant.io/integrations/person/) - Person entity management

---

## Notes

- **Manual override:** away_mode/sleep_mode toggles still work via GUI/button (auto-mode doesn't prevent manual control)
- **Guest mode:** Auto brightness preferences disabled when `input_boolean.guest_mode` on (uses default)
- **BLE range:** ~10m ideal, degrades through walls (concrete/metal worse than drywall)
- **Battery impact:** iOS BLE transmitter negligible battery drain (<1% per day)
