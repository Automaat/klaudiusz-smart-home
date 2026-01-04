# Better Thermostat

**Why manual?** Better Thermostat is installed declaratively via Nix, but the
configuration must be done through the Home Assistant UI. Each thermostat
requires mapping to its external temperature sensor through the GUI setup
wizard.

**When to do this:** When a thermostat has an inaccurate built-in temperature
sensor and you want to use a separate, more accurate temperature sensor to
control heating.

## Prerequisites

- A physical thermostat entity (e.g., `climate.thermostat_livingroom`)
- An external temperature sensor in the same area
  (e.g., `sensor.livingroom_temperature`)
- Better Thermostat installed declaratively (already configured in Nix)

## Configuration

### 1. Add Better Thermostat Integration

1. Navigate to **Settings** → **Devices & Services**
2. Click **+ ADD INTEGRATION** (bottom-right)
3. Search for **"Better Thermostat"**
4. Click to start configuration wizard

### 2. Configure Integration

**Basic Configuration:**

- **Name**: Descriptive name (e.g., "Thermostat Livingroom")
  - This creates entity: `climate.better_thermostat_livingroom`
- **Real Thermostat**: Select your physical thermostat (e.g., `climate.thermostat_livingroom`)
- **External Temperature Sensor**: Select accurate sensor (e.g., `sensor.livingroom_temperature`)
- **Temperature Calibration**: Start with `0` (adjust later if needed)

**Advanced Options:**

- **Mode**: Advanced (recommended for fine-tuning)
- **Heating System**: Select appropriate type (e.g., "TRV" for radiator valves)
- **Off Temperature**: Temperature to set when turned off (default: 5°C)
- **Enable Window Detection**: Optional, detects open windows to save energy

Click **Submit** to create the virtual thermostat.

## Post-Configuration Steps

### 1. Hide Original Thermostat

To avoid confusion, disable the original thermostat from voice control:

1. Navigate to **Settings** → **Devices & Services** → **Entities**
2. Find original thermostat (e.g., `climate.thermostat_livingroom`)
3. Click entity → Click **⚙️** icon
4. Toggle **Enabled** → **OFF**
5. Confirm the action

**Note:** The entity still functions but is hidden from voice assistants and UI.

### 2. Test Better Thermostat

The Better Thermostat entity will:

- Read temperature from external sensor
- Control the physical thermostat based on that reading
- Maintain target temperature more accurately

You can test by manually adjusting the target temperature through the UI.

## Verify Integration

**Check Better Thermostat is using external sensor:**

1. **Settings** → **Devices & Services** → Find Better Thermostat device
2. Click device → Check **Current Temperature** matches external sensor
3. Change target temperature and verify physical thermostat responds

**Check logs for errors:**

```bash
ssh homelab "journalctl -u home-assistant | grep -i 'better_thermostat'"
```

Look for successful initialization and no errors.

## Troubleshooting

**Better Thermostat not controlling physical thermostat:**

- Verify physical thermostat is on and responsive
- Check Better Thermostat mode is set correctly for your heating type
- Review Better Thermostat logs: **Settings** → **System** → **Logs** →
  Filter "better_thermostat"

**Temperature not accurate:**

- Verify external sensor is reporting valid temperature
- Adjust **Temperature Calibration** offset if needed
- Check sensor update frequency (should update every 1-2 minutes)

**Integration not available after Nix rebuild:**

- Better Thermostat is installed declaratively via symlink
- Check symlink exists: `ssh homelab "ls -la /var/lib/hass/custom_components/better_thermostat"`
- Verify HA recognized the component:
  `ssh homelab "journalctl -u home-assistant | grep better_thermostat"`
- Restart Home Assistant: `ssh homelab "sudo systemctl restart home-assistant"`

## Related Documentation

- [Better Thermostat GitHub](https://github.com/KartoffelToby/better_thermostat)
- [Better Thermostat Documentation](https://better-thermostat.org/)
- [Home Assistant Climate Integration](https://www.home-assistant.io/integrations/climate/)
