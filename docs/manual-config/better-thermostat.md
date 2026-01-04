# Better Thermostat

**Why manual?** Better Thermostat is a HACS custom integration that creates a virtual thermostat using external temperature sensors. The installation and configuration must be done through the Home Assistant UI as it's not a core HA component and cannot be configured declaratively.

**When to do this:** When a thermostat has an inaccurate built-in temperature sensor and you want to use a separate, more accurate temperature sensor to control heating.

## Prerequisites

- HACS (Home Assistant Community Store) installed
- A physical thermostat entity (e.g., `climate.thermostat_livingroom`)
- An external temperature sensor in the same area (e.g., `sensor.livingroom_temperature`)

## Installation

### 1. Install from HACS

1. Open Home Assistant UI
2. Navigate to **HACS** → **Integrations**
3. Search for **"Better Thermostat"**
4. Click **DOWNLOAD**
5. Restart Home Assistant when prompted

### 2. Add Better Thermostat Integration

1. Navigate to **Settings** → **Devices & Services**
2. Click **+ ADD INTEGRATION** (bottom-right)
3. Search for **"Better Thermostat"**
4. Click to start configuration wizard

### 3. Configure Integration

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

## Post-Installation Steps

### 1. Hide Original Thermostat

To avoid confusion, disable the original thermostat from voice control:

1. Navigate to **Settings** → **Devices & Services** → **Entities**
2. Find original thermostat (e.g., `climate.thermostat_livingroom`)
3. Click entity → Click **⚙️** icon
4. Toggle **Enabled** → **OFF**
5. Confirm the action

**Note:** The entity still functions but is hidden from voice assistants and UI.

### 2. Test Voice Commands

With climate intents enabled, test voice commands:

- **Polish**: "Ustaw temperaturę w salonie na 22 stopnie"
- **Polish**: "Jaka temperatura w salonie?"

The Better Thermostat entity will:
- Read temperature from external sensor
- Control the physical thermostat based on that reading
- Maintain target temperature more accurately

## Verify Integration

**Check Better Thermostat is using external sensor:**

1. **Settings** → **Devices & Services** → Find Better Thermostat device
2. Click device → Check **Current Temperature** matches external sensor
3. Change target temperature and verify physical thermostat responds

**Check scheduled automations work:**

```bash
ssh homelab "journalctl -u home-assistant | grep -i 'livingroom_thermostat'"
```

Look for automation triggers at 06:00 (21°C) and 22:00 (18°C).

## Troubleshooting

**Better Thermostat not controlling physical thermostat:**
- Verify physical thermostat is on and responsive
- Check Better Thermostat mode is set correctly for your heating type
- Review Better Thermostat logs: **Settings** → **System** → **Logs** → Filter "better_thermostat"

**Temperature not accurate:**
- Verify external sensor is reporting valid temperature
- Adjust **Temperature Calibration** offset if needed
- Check sensor update frequency (should update every 1-2 minutes)

**Voice commands not working:**
- Verify area name in HA matches voice command (e.g., "salon" or "livingroom")
- Check climate intents are uncommented in configuration
- Restart Home Assistant after changes: `ssh homelab "sudo systemctl restart home-assistant"`

## Related Documentation

- [Better Thermostat GitHub](https://github.com/KartoffelToby/better_thermostat)
- [Better Thermostat Documentation](https://better-thermostat.org/)
- [Home Assistant Climate Integration](https://www.home-assistant.io/integrations/climate/)
