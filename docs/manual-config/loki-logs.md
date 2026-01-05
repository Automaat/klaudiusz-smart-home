# Loki Log Aggregation Manual Configuration

## Overview

Loki + Promtail log aggregation system for viewing Home Assistant and system service logs in Grafana.
Declarative services enabled in NixOS, but dashboard creation and query setup require GUI configuration.

## Why Manual Configuration?

- **Dashboards**: Grafana dashboards created via UI (not provisioned in code)
- **Alert rules**: Log-based alerting configured through Grafana UI
- **Custom queries**: LogQL queries built interactively in Explore view
- **Panel customization**: Log panel settings (colors, filters, formatting) configured in UI

## Prerequisites

- Loki service running: `systemctl status loki`
- Promtail service running: `systemctl status promtail`
- Grafana running with Loki datasource: `http://192.168.0.241:3000`
- Home Assistant generating logs: `/var/lib/hass/home-assistant.log`

## Architecture

```
HA logs (/var/lib/hass/home-assistant.log)
    ↓
Journald (systemd services)
    ↓
Promtail (scraper) → parses logs, adds labels
    ↓
Loki (storage) → indexes by labels, stores 365d
    ↓
Grafana (UI) → query with LogQL, visualize, alert
```

## What's Already Configured

✅ **Loki service** (port 3100):
- 365d retention
- Filesystem storage: `/var/lib/loki/`
- TSDB index format (v13 schema)

✅ **Promtail service** (port 9080):
- Scrapes HA logfile: `/var/lib/hass/home-assistant.log`
- Scrapes journald: HA, Wyoming, Prometheus, Grafana, PostgreSQL, InfluxDB services
- Parses HA log format: extracts timestamp, level, logger, message
- Labels: `job`, `level`, `logger`, `unit`

✅ **Grafana datasource**:
- Loki datasource provisioned
- URL: `http://localhost:3100`
- UID: `loki`

## Creating Log Dashboards

### 1. Access Grafana

```bash
# SSH to homelab (if remote)
ssh homelab
```

Open browser: `http://192.168.0.241:3000`

Login:
- Username: `admin`
- Password: (from sops secrets)

### 2. Explore Logs (Test Queries)

**Before creating dashboards, test queries in Explore:**

1. Navigate to: **Explore** (left sidebar, compass icon)
2. Select datasource: **Loki**
3. Try example queries:

**Basic queries:**

```logql
# All Home Assistant logs
{job="homeassistant"}

# Only errors
{job="homeassistant"} |= "ERROR"

# Specific component
{job="homeassistant"} | logger=~".*intent.*"

# System services
{job="systemd", unit="home-assistant.service"}

# Multiple services
{job="systemd", unit=~"(home-assistant|wyoming-.*)\\.service"}
```

**Advanced queries:**

```logql
# Error count rate (last 5 min)
rate({job="homeassistant"} |= "ERROR" [5m])

# Top 10 loggers by volume
topk(10, count_over_time({job="homeassistant"}[1h]))

# Filter by level and logger
{job="homeassistant", level="ERROR", logger=~".*wyoming.*"}
```

4. Verify logs appear (should see log lines)
5. Adjust time range if needed (top-right)

### 3. Create Real-Time Log Viewer Dashboard

**Purpose:** Live log stream for debugging

1. Navigate to: **Dashboards** (left sidebar)
2. Click **"New" → "New Dashboard"**
3. Click **"Add visualization"**
4. Select datasource: **Loki**

**Panel Configuration:**

- **Query:**
  ```logql
  {job="homeassistant"}
  ```

- **Panel Settings:**
  - Title: `Home Assistant Logs - Live`
  - Visualization: **Logs** (should be default)
  - Display Options:
    - Show time: ✓
    - Show labels: ✓ (level, logger)
    - Wrap lines: ✓
    - Deduplication: None
    - Order: Newest first

- **Transform:**
  - Add transform: **Organize fields**
  - Show: timestamp, level, logger, message
  - Rename fields for clarity (optional)

5. Click **"Apply"** (top-right)
6. Click **"Save dashboard"** (top-right)
   - Name: `Smart Home Logs`
   - Folder: **Services** (or create new)
7. Click **"Save"**

### 4. Create Error Tracking Dashboard

**Purpose:** Error trends, top errors, error rate

**Panel 1: Error Rate Graph**

1. Add new panel
2. Query:
   ```logql
   sum(rate({job="homeassistant"} |= "ERROR" [5m]))
   ```
3. Visualization: **Time series**
4. Title: `Home Assistant Error Rate (5min)`
5. Legend: Hide
6. Y-axis unit: `errors/sec`
7. Apply

**Panel 2: Error Count by Level**

1. Add new panel
2. Query:
   ```logql
   sum by (level) (count_over_time({job="homeassistant"}[1h]))
   ```
3. Visualization: **Bar chart**
4. Title: `Log Levels (Last Hour)`
5. Apply

**Panel 3: Top Errors Table**

1. Add new panel
2. Query:
   ```logql
   {job="homeassistant"} |= "ERROR"
   ```
3. Visualization: **Table**
4. Title: `Recent Errors`
5. Transform:
   - **Organize fields**: Show timestamp, level, logger, message
   - **Limit**: 50 rows
6. Table settings:
   - Column width: Auto
   - Cell display mode: Color background (by level)
7. Apply

**Panel 4: Service Status (Systemd)**

1. Add new panel
2. Query:
   ```logql
   {job="systemd", unit=~"(home-assistant|wyoming-.*|prometheus|grafana)\\.service"}
   ```
3. Visualization: **Logs**
4. Title: `System Service Logs`
5. Apply

**Save Dashboard:**

- Name: `Smart Home Error Tracking`
- Folder: **Services**

### 5. Create Alerting Rules (Optional)

**Purpose:** Send Telegram alerts for log patterns

1. Navigate to: **Alerting → Alert rules** (left sidebar)
2. Click **"New alert rule"**

**Example: Error Spike Alert**

- **Rule name:** `Home Assistant Error Spike`
- **Query:**
  - Datasource: **Loki**
  - Query:
    ```logql
    sum(rate({job="homeassistant"} |= "ERROR" [5m]))
    ```
  - Condition: `WHEN last() OF query IS ABOVE 0.1`
  - (More than 6 errors/min for 5 min = spike)

- **Evaluation:**
  - Folder: **Services**
  - Group: `log_alerts`
  - For: `5m` (alert after 5 min sustained errors)

- **Annotations:**
  - Summary: `Home Assistant error rate is elevated`
  - Description: `Error rate: {{ $values.B.Value }} errors/sec`

- **Notification:**
  - Contact point: **Home Assistant Telegram** (existing)

3. Click **"Save rule and exit"**

**Example: Component Failure Alert**

- Query:
  ```logql
  {job="homeassistant"} |= "Setup failed" or "Integration failed"
  ```
- Condition: `WHEN count() OF query IS ABOVE 0`
- For: `2m`

## LogQL Query Reference

### Basic Selectors

```logql
# By job
{job="homeassistant"}
{job="systemd"}

# By unit (systemd services)
{unit="home-assistant.service"}

# By level (HA logs only)
{level="ERROR"}
{level=~"ERROR|WARNING"}

# By logger (HA component)
{logger="homeassistant.components.intent_script"}
```

### Filtering

```logql
# Contains text
{job="homeassistant"} |= "voice"

# Does not contain
{job="homeassistant"} != "debug"

# Regex match
{job="homeassistant"} |~ "error|fail"

# Regex exclude
{job="homeassistant"} !~ "heartbeat|ping"
```

### Aggregations

```logql
# Count logs
count_over_time({job="homeassistant"}[1h])

# Rate (logs per second)
rate({job="homeassistant"}[5m])

# Top N loggers
topk(10, sum by (logger) (count_over_time({job="homeassistant"}[1h])))

# Group by level
sum by (level) (count_over_time({job="homeassistant"}[1h]))
```

### Time Ranges

```logql
# Last 5 minutes
[5m]

# Last 1 hour
[1h]

# Last 24 hours
[24h]

# Last 7 days
[7d]
```

## Verification

### Check Services

```bash
# Loki status
systemctl status loki
journalctl -u loki -f

# Promtail status
systemctl status promtail
journalctl -u promtail -f

# Check Loki API
curl http://localhost:3100/ready
# Should return: ready

# Check Promtail metrics
curl http://localhost:9080/metrics | grep promtail_targets
```

### Check Log Flow

**Verify Promtail is reading logs:**

```bash
# Check Promtail positions (what it's read)
sudo cat /var/lib/promtail/positions.yaml

# Should show:
# /var/lib/hass/home-assistant.log: <byte-offset>
```

**Verify Loki has data:**

```bash
# Query Loki directly
curl -G 'http://localhost:3100/loki/api/v1/query' \
  --data-urlencode 'query={job="homeassistant"}' \
  --data-urlencode 'limit=5'

# Should return JSON with log entries
```

**Check Grafana datasource:**

1. Grafana → Connections → Data sources → Loki
2. Click **"Test"** (bottom)
3. Should show: "Data source is working"

## Troubleshooting

### No Logs in Grafana

**Check datasource:**

1. Grafana → Explore → Loki
2. Query: `{job="homeassistant"}`
3. If "No data": check services

**Check Loki service:**

```bash
systemctl status loki
journalctl -u loki -n 50

# Common issues:
# - Port 3100 in use
# - Permissions on /var/lib/loki/
# - Disk full
```

**Check Promtail service:**

```bash
systemctl status promtail
journalctl -u promtail -n 50 | grep -i error

# Common issues:
# - Can't read HA logfile (permissions)
# - Journal access denied
# - Can't connect to Loki
```

### Promtail Not Reading HA Logs

**Check file permissions:**

```bash
ls -la /var/lib/hass/home-assistant.log
# Should be readable by promtail user

# Fix if needed (shouldn't be necessary)
sudo chmod 644 /var/lib/hass/home-assistant.log
```

**Check Promtail config:**

```bash
# View active config (generated by Nix)
sudo systemctl cat promtail

# Verify __path__ points to /var/lib/hass/home-assistant.log
```

### Logs Not Parsing Correctly

**Check log format matches regex:**

```bash
# View actual HA logs
tail /var/lib/hass/home-assistant.log

# Expected format:
# 2024-01-05 12:00:00.123 ERROR (MainThread) [homeassistant.core] Message
```

**If format changed:**

- Update Promtail regex in `hosts/homelab/default.nix`
- Rebuild: `sudo nixos-rebuild switch --flake /etc/nixos#homelab`
- Restart: `sudo systemctl restart promtail`

### High Disk Usage

**Check Loki storage:**

```bash
du -sh /var/lib/loki/
# Expected: ~7-14 GB for 365d retention
```

**If too large:**

- Reduce retention in `hosts/homelab/default.nix`
- Change `retention_period = "8760h"` to lower value
- Rebuild NixOS config
- Restart Loki service

**Force compaction:**

```bash
# Loki compactor runs automatically every 10 min
# Check compactor logs
journalctl -u loki | grep -i compactor
```

### Grafana Query Slow

**Optimize queries:**

- Add time range: `[5m]`, `[1h]` instead of querying all logs
- Add filters: `|= "ERROR"` to reduce scan
- Use indexed labels: `{job="homeassistant"}` instead of `{} |= "homeassistant"`
- Limit results: Add `| limit 100` to query

**Check Loki performance:**

```bash
# Check Loki metrics
curl http://localhost:3100/metrics | grep loki_ingester

# High values indicate backlog
```

## Storage Estimates

**Expected storage usage:**

- **Home Assistant logs:** ~10-50 MB/day (depends on debug level)
- **Systemd journal:** ~5-20 MB/day (filtered services only)
- **Total:** ~15-70 MB/day compressed
- **365d retention:** ~5-25 GB

**Current setup:**

- Retention: 365 days
- Compression: Enabled (Loki default)
- Compaction: Every 10 minutes
- Location: `/var/lib/loki/`

## JSON Logging (Future Enhancement)

**Current setup:** Standard HA log format (human-readable)

**To enable JSON logging (optional):**

1. Requires custom Python logging handler
2. Benefits: Better searchability, structured fields
3. Implementation: Custom integration or log handler
4. Trade-off: Less human-readable in raw form

**If interested:**

- Research custom logging formatters for HA
- Update Promtail pipeline to parse JSON (change `regex` to `json`)
- Test thoroughly before deployment

## Security Notes

- Loki binds to `127.0.0.1:3100` only (not exposed to network)
- Promtail reads logs as local user (no authentication needed)
- Grafana datasource uses local Loki (no token required)
- Log files contain sensitive info - never expose Grafana publicly without auth

## Related Documentation

- [Grafana Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/send-data/promtail/)
- [LogQL Query Language](https://grafana.com/docs/loki/latest/query/)
- [Grafana Log Panel](https://grafana.com/docs/grafana/latest/panels-visualizations/visualizations/logs/)
- [Home Assistant Logging](https://www.home-assistant.io/integrations/logger/)
