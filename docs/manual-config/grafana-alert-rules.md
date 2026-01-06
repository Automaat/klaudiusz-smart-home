# Grafana Alert Rules Configuration

## Why Manual Configuration

Grafana alert rules created via GUI cannot be managed declaratively via NixOS. After adding Prometheus exporters, existing alerts need to be updated to use the correct metrics.

## When to Perform Setup

After deploying Prometheus exporter changes from this repository.

## Service Monitoring Overview

The following services are monitored with Prometheus:

| Service | Metric Source | Alert Query Pattern |
|---------|---------------|-------------------|
| Home Assistant | Native HA exporter | `up{job="homeassistant"}` |
| PostgreSQL | postgres_exporter | `up{job="postgresql"}` |
| Prometheus | Self-scraping | `up{job="prometheus"}` |
| Grafana | Native metrics endpoint | `up{job="grafana"}` |
| InfluxDB | Native metrics endpoint | `up{job="influxdb"}` |
| fail2ban | Textfile collector | `service_up{service="fail2ban"}` |
| Piper | Textfile collector | `service_up{service="wyoming-piper-default"}` |
| Whisper | Textfile collector | `service_up{service="wyoming-faster-whisper-default"}` |
| Tailscale | Textfile collector | `service_up{service="tailscaled"}` |

## Alert Query Updates

### For Services with Native Exporters

These alerts should use the standard `up` metric:

```promql
# Prometheus down alert
up{job="prometheus"} == 0

# Grafana down alert
up{job="grafana"} == 0

# InfluxDB down alert
up{job="influxdb"} == 0

# Home Assistant down alert
up{job="homeassistant"} == 0

# PostgreSQL down alert
up{job="postgresql"} == 0
```

### For Services Using Textfile Collector

These alerts should use the `service_up` metric:

```promql
# fail2ban down alert
service_up{service="fail2ban"} == 0

# Piper down alert
service_up{service="wyoming-piper-default"} == 0

# Whisper down alert
service_up{service="wyoming-faster-whisper-default"} == 0

# Tailscale down alert
service_up{service="tailscaled"} == 0
```

## Step-by-Step: Update Alert Rules

1. **Access Grafana**
   - Navigate to http://homelab:3000
   - Login with admin credentials

2. **Open Alerting Section**
   - Click "Alerting" (bell icon) in left sidebar
   - Select "Alert rules"

3. **Update Each Alert Rule**

   For services with native exporters (prometheus, grafana, influxdb):
   - Find alert rule (e.g., "grafana_down")
   - Click "Edit"
   - Verify query uses `up{job="servicename"}`
   - Should already be correct if alerts exist

   For services using textfile collector (fail2ban, piper, whisper, tailscale):
   - Find alert rule (e.g., "fail2ban_down")
   - Click "Edit"
   - Change query from:
     ```
     up{job="fail2ban"} == 0
     ```
     to:
     ```
     service_up{service="fail2ban"} == 0
     ```
   - Click "Save rule and exit"
   - Repeat for other textfile-based services

4. **Verify Alert Status**
   - Go to "Alerting" → "Alert rules"
   - Check that all alerts show "Normal" state
   - Wait 1-2 minutes for evaluation
   - Alerts should stop firing

## Verification

After updating alerts, verify metrics are being collected:

```bash
# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Check service_up metrics
curl -s http://localhost:9090/api/v1/query?query=service_up | jq '.data.result[] | {service: .metric.service, value: .value[1]}'

# Check up metrics
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result[] | {job: .metric.job, value: .value[1]}'
```

All services should show `"health": "up"` or `"value": "1"`.

## Troubleshooting

**Alert still firing after update:**
- Wait 2-3 minutes for alert evaluation cycle
- Check Prometheus target health: http://localhost:9090/targets
- Verify metric exists in Prometheus: http://localhost:9090/graph

**service_up metric missing:**
- Check textfile exporter timer: `systemctl status prometheus-service-status.timer`
- Check textfile content: `cat /var/lib/prometheus-node-exporter-text/service_status.prom`
- Verify node_exporter is scraping textfile: `journalctl -u prometheus-node-exporter`

**up metric missing for native exporters:**
- Check service is running: `systemctl status servicename`
- Check Prometheus scrape config: http://localhost:9090/config
- Check Prometheus logs: `journalctl -u prometheus`

## Related Documentation

- [Prometheus Alerting](https://prometheus.io/docs/alerting/latest/overview/)
- [Grafana Alerting](https://grafana.com/docs/grafana/latest/alerting/)
- [Node Exporter Textfile Collector](https://github.com/prometheus/node_exporter#textfile-collector)
