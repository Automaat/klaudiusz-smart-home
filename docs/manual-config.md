# Manual Configuration Steps

This document contains instructions for configuration that cannot be done
declaratively through NixOS and must be performed manually through the
Home Assistant UI.

## MQTT Broker Configuration

**Why manual?** Since Home Assistant 2022.3, MQTT broker connection
settings can no longer be configured via YAML. The integration must be
set up through the UI.

**When to do this:** After initial installation or if MQTT integration is not configured.

### Steps

1. Open Home Assistant UI
2. Navigate to **Settings** → **Devices & Services**
3. Click **+ ADD INTEGRATION**
4. Search for and select **MQTT**
5. Configure connection:
   - **Broker**: `localhost` (or `127.0.0.1`)
   - **Port**: `1883`
   - **Username**: `homeassistant`
   - **Password**: Retrieve with:
     `ssh homelab "sudo cat /run/secrets/mosquitto-ha-password-plaintext"`

### Verify Configuration

After setup, Zigbee2MQTT devices should appear automatically via MQTT
discovery.

**Check MQTT status:**

```bash
ssh homelab "systemctl status mosquitto zigbee2mqtt"
```

**View MQTT messages (debugging):**

```bash
ssh homelab "mosquitto_sub -h localhost -p 1883 -u homeassistant \
  -P \$(sudo cat /run/secrets/mosquitto-ha-password-plaintext) -t '#'"
```

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

- Previously configured via YAML `sensor.platform: systemmonitor`
- Old YAML config causes errors and should be removed from `configuration.yaml`
- Integration creates entities like `sensor.processor_use`, `sensor.memory_use_percent`

## Related Documentation

- [Home Assistant MQTT Integration](https://www.home-assistant.io/integrations/mqtt/)
- [Zigbee2MQTT Home Assistant Integration](https://www.zigbee2mqtt.io/guide/usage/integrations/home_assistant.html)
- [System Monitor Integration](https://www.home-assistant.io/integrations/systemmonitor/)
