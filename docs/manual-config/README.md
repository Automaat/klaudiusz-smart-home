# Manual Configuration Steps

This directory contains instructions for configuration that cannot be done
declaratively through NixOS and must be performed manually through web UIs
(Home Assistant or service-specific interfaces).

## Integrations

- **[Zigbee Home Automation (ZHA)](zha.md)** - Zigbee device pairing and setup
- **[Aqara FP300 Presence Sensor](aqara-fp300.md)** - mmWave presence sensor with ZHA custom quirk
- **[Bermuda BLE Trilateration](bermuda-ble.md)** - Room-level person tracking via Bluetooth
- **[ESPHome Bluetooth Proxy](esphome-bluetooth-proxy.md)** - ESP32 BLE proxy setup for extended range
- **[Cloudflare Tunnel](cloudflared.md)** - Secure external access via ha.mskalski.dev
- **[Better Thermostat](better-thermostat.md)** - Use external temperature sensors for thermostat control
- **[Custom Conversation](custom-conversation.md)** - Fallback conversation agent (local intents → LLM)
- **[Airly Air Quality](airly.md)** - Polish air quality sensor with PM2.5, PM10, and CAQI
- **[InfluxDB](influxdb.md)** - Time-series database for metrics (365d retention)
- **[Xiaomi Home](xiaomi-home.md)** - Xiaomi Mi devices via official OAuth (replaces `xiaomi-miio.md`)
- **[Loki Log Aggregation](loki-logs.md)** - View HA and system logs in Grafana (365d retention)
- **[Grafana Loki Explore App](grafana-loki-explore.md)** - Configure default datasource for log drilldown features
- **[Grafana Alert Rules](grafana-alert-rules.md)** - Update alert queries after Prometheus exporter changes
- **[Grafana Dashboards](grafana-dashboards.md)** - Historical analysis dashboards for environmental and system metrics
- **[Dashboard Configuration](dashboards.md)** - Home Assistant GUI dashboard setup guide
- **[System Monitor](system-monitor.md)** - System resource monitoring
- **[Wyoming Protocol](wyoming-protocol.md)** - Speech-to-text and text-to-speech services
- **[Voice Assistant Preview Edition](voice-assistant-preview.md)** - Voice hardware setup
- **[Voice Preview Custom Wake Word](voice-preview-custom-wake-word.md)** - Add Polish "Klaudiusz" wake word via ESPHome
- **[LG WebOS TV](lg-webos-tv.md)** - Smart TV integration
- **[Samsung SmartThings](smartthings.md)** - SmartThings OAuth integration
- **[MCP Server (Claude Code)](mcp-server.md)** - AI assistant API access
- **[Todoist](todoist.md)** - Todo list integration with OAuth setup
- **[T-Higrow ESPHome](t-higrow-esphome.md)** - LilyGO T-Higrow plant sensor setup
- **[OpenPlantbook](openplantbook.md)** - Plant species database with API credentials
- **[Roborock](roborock.md)** - Roborock vacuum with OAuth authentication

## When to Add New Documentation

When a Home Assistant feature requires manual GUI configuration:

1. Create new file in `docs/manual-config/{integration-name}.md`
2. Use existing files as template
3. Include:
   - Why manual configuration is needed
   - When to perform setup
   - Step-by-step instructions
   - Verification steps
   - Troubleshooting (if applicable)
   - Related documentation links
4. Update this README with link to new file
