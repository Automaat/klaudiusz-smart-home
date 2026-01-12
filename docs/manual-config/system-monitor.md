# System Monitor Integration

**Why manual?** Since Home Assistant 2022.12, System Monitor moved from YAML
platform configuration to UI-based integration setup. The old
`platform: systemmonitor` YAML syntax is deprecated.

**When to do this:** After initial installation to monitor system resources (CPU, memory, disk).

## Setup Steps

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

## Notes

- Previously configured via YAML `sensor.platform: systemmonitor` in `hosts/homelab/home-assistant/monitoring.nix`
- Old YAML platform config removed in favor of UI-based integration
- Integration creates entities like `sensor.processor_use`, `sensor.memory_use_percent`
- Existing automations in `automations.nix` and `monitoring.nix` will continue working after manual setup

## Related Documentation

- [System Monitor Integration](https://www.home-assistant.io/integrations/systemmonitor/)
