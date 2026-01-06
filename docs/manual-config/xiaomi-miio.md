# Xiaomi Miio Integration

**Why manual?** Xiaomi devices require a device token that must be extracted from
Mi Home app or via network sniffing. Cannot be configured declaratively.

**When to do this:** After adding device to Mi Home app and connecting to WiFi.

## Prerequisites

1. Device paired with Mi Home app
2. Device connected to same network as Home Assistant
3. Device token extracted (see below)

## Getting Device Token

### Method 1: Mi Home App (iOS)

1. Open Mi Home app → Select device
2. Tap "⋮" (three dots) → **Device Info**
3. Rapidly tap blank area below device name 10 times
4. Token appears on screen (32-character hex string)
5. Copy token immediately

### Method 2: Mi Home App (Android)

1. Open Mi Home app
2. Settings → About → Tap version 5 times (enables dev mode)
3. Return to device → Tap "⋮" → **Network Info**
4. Find "token" field

### Method 3: Network Sniffing (if above fails)

```bash
# Install miio cli tool
npm install -g miio

# Discover device on network
miio discover

# Output shows token for each device
```

## Adding Device to Home Assistant

1. Navigate to **Settings** → **Devices & Services**
2. Click **+ ADD INTEGRATION**
3. Search for **Xiaomi Miio**
4. Enter device details:
   - **Host**: Device IP address (find in router DHCP leases or Mi Home app)
   - **Token**: 32-character token from above
   - **Model**: Auto-detected (or select manually)
5. Click **Submit**

### Supported Devices

- Air Purifiers (2, 2S, 3H, Pro, Pro H)
- Humidifiers
- Fans
- Vacuum cleaners
- Light bulbs
- Smart plugs

## Verify Integration

**Check entity created:**

1. **Settings** → **Devices & Services** → **Xiaomi Miio**
2. Click device card
3. Verify entities created (fan, air_quality, sensor.*)

**Test control:**

```bash
# Turn on air purifier
ha_call_service("fan", "turn_on", entity_id="fan.air_purifier_3h")

# Set fan speed
ha_call_service("fan", "set_percentage", entity_id="fan.air_purifier_3h", data={"percentage": 50})
```

## Troubleshooting

**"Unable to discover device":**

- Verify device and HA on same network/VLAN
- Check firewall rules (mDNS port 5353, UDP)
- Restart device

**"Invalid token":**

- Token changes if device reset or re-paired in Mi Home
- Extract token again

**Device offline:**

- Check router DHCP lease still valid
- Reserve static IP for device
- Power cycle device

## Device Configuration

**Mi Air Purifier 3H entities:**

- `fan.air_purifier_3h` - Main control (on/off, speed)
- `sensor.air_purifier_3h_temperature` - Temperature
- `sensor.air_purifier_3h_humidity` - Humidity
- `sensor.air_purifier_3h_pm25` - PM2.5 air quality
- `sensor.air_purifier_3h_filter_life` - Filter remaining %
- `binary_sensor.air_purifier_3h_filter_life` - Filter needs replacement

**Rename device (Polish format):**

1. Click device in Devices & Services
2. Settings icon → Rename
3. Format: `{area} - {function}`
4. Example: `Salon - Oczyszczacz powietrza`

## Voice Commands

**Add to intents.nix after setup:**

```nix
# Turn on/off
TurnOnAirPurifier = {
  speech.text = "Włączam oczyszczacz powietrza w {{ area }}";
  action = [{
    service = "fan.turn_on";
    target.entity_id = "fan.{{ area | lower | replace(' ', '_') }}_air_purifier";
  }];
};

# Check air quality
CheckAirQuality = {
  speech.text = "PM2.5 wynosi {{ states('sensor.air_purifier_3h_pm25') }} mikrogramów na metr sześcienny";
};
```

## Related Documentation

- [Xiaomi Miio Integration](https://www.home-assistant.io/integrations/xiaomi_miio/)
- [python-miio Library](https://python-miio.readthedocs.io/)
- [Supported Devices List](https://www.home-assistant.io/integrations/xiaomi_miio/#supported-devices)
