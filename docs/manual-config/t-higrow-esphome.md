# LilyGO T-Higrow ESP32 + ESPHome Setup

## What It Is

ESP32-based plant monitoring board with built-in sensors:

- Soil moisture (capacitive)
- Soil conductivity/fertilizer sensor
- Temperature & humidity (DHT12/BME280)
- Light sensor (BH1750)
- Battery support with deep sleep
- WiFi connectivity

## Integration Path: ESPHome

**Why ESPHome:**

- Native HA integration (auto-discovery)
- OTA updates
- YAML configuration
- Community support

## Quick Start

### Web Flasher (Recommended)

1. Connect T-Higrow via USB
2. Open Chrome/Edge
3. Go to: <https://bruvv.github.io/LILYGO-T-Higrow-Esphome/>
4. Flash firmware
5. Configure WiFi
6. Auto-discovered in HA

### Custom ESPHome Config

Community configs:

- **Main:** [bruvv/LILYGO-T-Higrow-Esphome](https://github.com/bruvv/LILYGO-T-Higrow-Esphome)
- **Example:** [WoLpH's config](https://gist.github.com/WoLpH/bc284ba9aeb5d1263f72d6294e239c1a)

## Pin Mappings

```yaml
# Soil Sensors
- GPIO32: Soil moisture (ADC, 11db attenuation)
- GPIO34: Soil conductivity (ADC, 11db attenuation)

# I2C Bus (SDA: GPIO25, SCL: GPIO26)
- 0x23: BH1750 light sensor
- 0x5C: DHT12 temp/humidity (or BME280)

# Power
- GPIO4: Must be HIGH on boot (powers sensors)
```

## NixOS Integration

### Add ESPHome Component

```nix
# hosts/homelab/home-assistant/default.nix
services.home-assistant = {
  enable = true;
  extraComponents = [
    "esphome"
    # ... other components
  ];
};
```

### Flash & Discover

1. Flash T-Higrow (web flasher or ESPHome dashboard)
2. Configure WiFi
3. HA auto-discovers device
4. Integration created in GUI
5. Entities appear automatically

## Sensors Created

```text
sensor.plant_name_soil_moisture          # 0-100%
sensor.plant_name_soil_conductivity      # μS/cm
sensor.plant_name_temperature            # °C
sensor.plant_name_humidity               # %
sensor.plant_name_illuminance            # lx
sensor.plant_name_battery_voltage        # V
binary_sensor.plant_name_status          # Online/Offline
```

## Calibration

### Soil Moisture

1. Measure ADC dry (in air): ~2.8V
2. Measure ADC wet (in water): ~1.5V
3. Apply linear filter:

```yaml
sensor:
  - platform: adc
    pin: GPIO32
    name: "Soil Moisture"
    filters:
      - calibrate_linear:
          - 2.8 -> 0.0    # Dry
          - 1.5 -> 100.0  # Wet
    unit_of_measurement: "%"
```

### Soil Conductivity

Similar process (dry ~0V, fertilized ~1.5V)

## Battery Operation

### Enable Deep Sleep

```yaml
deep_sleep:
  run_duration: 30s       # Wake time
  sleep_duration: 30min   # Sleep time
```

**Battery life:** Weeks to months depending on wake interval

**Trade-off:** Longer sleep = longer battery, less frequent updates

## Voice Integration (Polish)

Add to `custom_sentences/pl/plants.yaml`:

```yaml
language: pl
intents:
  CheckPlantStatus:
    data:
      - sentences:
          - "jak się ma {plant_name}"
          - "czy {plant_name} potrzebuje wody"
```

Handler in `intents.nix`:

```nix
CheckPlantStatus = {
  speech.text = "{{ states('sensor.' ~ plant_name ~ '_soil_moisture') }}% wilgotności";
};
```

## Automation Ideas

```yaml
# Low moisture alert
- Alert when moisture < 20%
- Todoist task: "Water {plant_name}"
- TTS notification in Polish

# Optimal conditions tracking
- Track daily light exposure
- Temperature alerts (too hot/cold)
- Fertilizer reminders (conductivity drops)

# Battery monitoring
- Alert when battery < 10%
- Charge reminder automation
```

## Troubleshooting

**Device not discovered:**

- Check WiFi credentials
- Verify ESPHome component in HA
- Check `journalctl -u home-assistant -f`

**Sensors show 0/unavailable:**

- GPIO4 must be HIGH (sensor power)
- Check I2C address (0x23, 0x5C)
- Verify attenuation (11db) on ADC pins

**Battery drains fast:**

- Enable deep sleep
- Reduce wake duration
- Increase sleep interval (1h+)

## Resources

- [bruvv ESPHome Config](https://github.com/bruvv/LILYGO-T-Higrow-Esphome)
- [Web Flasher](https://bruvv.github.io/LILYGO-T-Higrow-Esphome/)
- [HA Community Thread](https://community.home-assistant.io/t/ttgo-higrow-with-esphome/144053)
- [ESPHome Integration](https://www.home-assistant.io/integrations/esphome/)
- [NixOS HA Wiki](https://wiki.nixos.org/wiki/Home_Assistant)
