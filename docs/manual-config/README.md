# Manual Configuration Steps

This directory contains instructions for configuration that cannot be done
declaratively through NixOS and must be performed manually through the
Home Assistant UI.

## Integrations

- **[Zigbee Home Automation (ZHA)](zha.md)** - Zigbee device pairing and setup
- **[Better Thermostat](better-thermostat.md)** - Use external temperature sensors for thermostat control
- **[Custom Conversation](custom-conversation.md)** - Fallback conversation agent (local intents → LLM)
- **[GIOŚ Air Quality](gios.md)** - Polish air quality monitoring
- **[InfluxDB](influxdb.md)** - Time-series database for metrics (365d retention)
- **[Xiaomi Home](xiaomi-home.md)** - Xiaomi Mi devices via official OAuth (replaces `xiaomi-miio.md`)
- **[Loki Log Aggregation](loki-logs.md)** - View HA and system logs in Grafana (365d retention)
- **[Grafana Loki Explore App](grafana-loki-explore.md)** - Configure default datasource for log drilldown features
- **[Grafana Alert Rules](grafana-alert-rules.md)** - Update alert queries after Prometheus exporter changes
- **[System Monitor](system-monitor.md)** - System resource monitoring
- **[Wyoming Protocol](wyoming-protocol.md)** - Speech-to-text and text-to-speech services
- **[Voice Assistant Preview Edition](voice-assistant-preview.md)** - Voice hardware setup
- **[LG WebOS TV](lg-webos-tv.md)** - Smart TV integration
- **[MCP Server (Claude Code)](mcp-server.md)** - AI assistant API access
- **[Todoist](todoist.md)** - Todo list integration with OAuth setup

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
