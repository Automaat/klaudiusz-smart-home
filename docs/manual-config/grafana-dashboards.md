# Grafana Dashboards

**Purpose:** Historical data analysis and advanced metrics visualization for Klaudiusz smart home.

**Why Grafana?** Home Assistant dashboards excel at quick trends (24h max) and interactive controls, but Grafana provides:

- 365-day data retention via InfluxDB
- Advanced Flux queries for aggregation and analysis
- Alert configuration with thresholds
- Superior multi-metric correlation
- Export/import for version control

## Access

- **URL:** <http://homelab:3000> (local network)
- **Tailscale:** Access via Tailscale IP when remote
- **Credentials:** admin (password in sops secrets)

## Dashboard Organization

Dashboards auto-provisioned from `hosts/homelab/grafana/dashboards/`:

### Smart Home (`smart-home/`)

**1. Home Assistant System Metrics** (`home-assistant.json`)

- CPU usage, load average (1m/5m/15m)
- Memory usage trends
- Disk usage with 90% alert threshold
- Network throughput (in/out)
- Speed test results (download/upload/ping)

**Status:** ✅ Deployed
**Time Range:** 24h default
**Alerts:** Disk >90%, Memory >90%

**2. Environmental Monitoring** (`environmental-monitoring.json`)

- Temperature comparison (living room, bedroom, bathroom)
- Average/max/min home temperature stats
- PM2.5 outdoor vs indoor trends
- Air quality gauges with WHO thresholds
  - Good: 0-15 µg/m³
  - Moderate: 15-35 µg/m³
  - Unhealthy: 35-55 µg/m³
  - Very Unhealthy: 55+ µg/m³

**Status:** ✅ Deployed
**Time Range:** 7d default
**Sensors Required:**

- `sensor.average_home_temperature`
- `sensor.max_home_temperature`
- `sensor.min_home_temperature`
- `sensor.pm25_24h_average`
- `sensor.aleje_pm2_5` (outdoor)
- `sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6` (indoor)

### Services (`services/`)

**3. Service Health & Comin Deployments** (`service-health.json`)

- Service status indicators (Whisper, Piper, Tailscale, PostgreSQL, fail2ban)
- Comin last deployment UUID
- Time since last deployment
- Deployment success/failure tracking

**Status:** ✅ Deployed
**Time Range:** 24h default
**Data Source:** Prometheus (real-time service states)

### Infrastructure (`infrastructure/`)

**4. Node Exporter** (`node-exporter.json`)

- System-level metrics (Prometheus node_exporter)
- Comprehensive CPU/memory/disk/network stats
- Process monitoring

**Status:** ✅ Deployed
**Data Source:** Prometheus

**5. PostgreSQL** (`postgresql.json`)

- Database performance metrics
- Connection pool stats
- Query performance

**Status:** ✅ Deployed
**Data Source:** Prometheus

## Data Sources

### InfluxDB (UID: `influxdb`)

- **URL:** <http://localhost:8086>
- **Database:** home-assistant
- **Query Language:** Flux
- **Retention:** 365 days
- **Use For:** Home Assistant entity history (sensors, climate, binary_sensors)

### Prometheus (UID: `prometheus`)

- **URL:** <http://localhost:9090>
- **Retention:** 15 days
- **Use For:** Real-time service health, system metrics via node_exporter

## Common Flux Query Patterns

### Basic Entity Query

```flux
from(bucket: "home-assistant")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["entity_id"] == "average_home_temperature")
  |> filter(fn: (r) => r["_field"] == "value")
  |> filter(fn: (r) => r["_measurement"] == "°C")
  |> filter(fn: (r) => r["domain"] == "sensor")
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
  |> yield(name: "mean")
```

### Multi-Entity Comparison

Use multiple queries with RefIDs (A, B, C) and override display names:

```flux
// Query A: Living Room
from(bucket: "home-assistant")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["domain"] == "climate")
  |> filter(fn: (r) => r["entity_id"] == "livingroom_thermostat")
  |> filter(fn: (r) => r["_field"] == "current_temperature")
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)

// Query B: Bedroom (similar structure)
```

### Aggregation Functions

- `fn: mean` - Average over window
- `fn: last` - Last value in window
- `fn: max` - Maximum in window
- `fn: min` - Minimum in window
- `fn: sum` - Total (for counters)

## Dashboard Editing

### Export Dashboard (for Version Control)

1. Open dashboard in Grafana
2. Click **Share** icon (top right)
3. Select **Export** tab
4. Toggle **Export for sharing externally** OFF (keeps local UIDs)
5. **Save to file** → save as `.json` in appropriate directory
6. Commit to git

### Import Dashboard

1. **Dashboards** → **Import**
2. Upload JSON or paste content
3. Select data sources (InfluxDB/Prometheus)
4. Click **Import**

**Note:** Auto-provisioned dashboards (from `/hosts/homelab/grafana/dashboards/`)
are read-only in GUI. Edit JSON directly and rebuild NixOS.

## Alert Configuration

**Current:** No alerts configured in Grafana (using HA automations instead).

**Future:** Can add Grafana alerts for:

- CPU temperature >80°C for 5m
- Disk >90% for 30m
- Memory >90% for 10m
- PM2.5 >55 µg/m³ for 2h

**Alert Channels:** Telegram (already configured via HA)

## Troubleshooting

### Dashboard Shows "No Data"

1. Check data source connection: **Configuration** → **Data Sources**
2. Verify InfluxDB token: `systemctl status influxdb2`
3. Check entity exists in HA: **Developer Tools** → **States**
4. Verify InfluxDB recording: `influx query 'from(bucket:"home-assistant") |> range(start:-1h)
   |> filter(fn: (r) => r["entity_id"] == "ENTITY_ID") |> limit(n:10)'`

### Panels Show "Unknown" or N/A

- Entity doesn't have `state_class` attribute (required for statistics)
- Check entity attributes in HA Developer Tools
- Template sensors need `state_class: measurement` for long-term stats

### Queries Time Out

- Reduce time range (default 7d → 24h)
- Use `aggregateWindow` with larger intervals
- Limit number of entities in single panel

### Graphs Show Gaps

- Entity unavailable during that period
- Check HA uptime: **Configuration** → **Logs**
- Verify continuous recording: check InfluxDB bucket size

## Performance Tips

- Use `aggregateWindow` for downsampling (every: v.windowPeriod)
- Limit queries to relevant time ranges
- Avoid `fn: last` on large datasets (use `fn: mean` instead)
- Keep panel count per dashboard <20

## Related Documentation

- [Grafana Official Docs](https://grafana.com/docs/grafana/latest/)
- [Flux Query Language](https://docs.influxdata.com/flux/)
- [HA Dashboard Guide](./dashboards.md) - For interactive controls and quick trends
- [Dashboard Implementation Plan](../plans/dashboard-implementation.md)

## Version Control Workflow

1. Edit dashboard in Grafana GUI (experimentation)
2. Export JSON when satisfied
3. Save to appropriate directory:
   - `smart-home/` - HA entities, environmental data
   - `services/` - Service health, Comin
   - `infrastructure/` - System metrics, databases
4. Commit to git: `git add hosts/homelab/grafana/dashboards/ && git commit -s -S -m "feat(grafana): add/update dashboard"`
5. Push → CI tests → Comin deploys

## Next Steps

- Add Grafana alerting (optional, currently using HA automations)
- Create energy monitoring dashboard (when power sensors available)
- Add humidity tracking (if Zigbee sensors report humidity attributes)
- Historical automation execution time analysis
