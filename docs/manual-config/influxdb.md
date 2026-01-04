# InfluxDB Manual Configuration

## Overview

InfluxDB time-series database for Home Assistant metrics with 365-day retention. Declarative service enabled in NixOS, but initial setup and HA integration require GUI configuration.

## Why Manual Configuration?

- **Initial setup**: InfluxDB 2.x onboarding (org, bucket, user creation) requires interactive setup
- **HA integration**: Home Assistant InfluxDB integration configured via Settings UI
- **Token management**: API tokens generated through InfluxDB UI
- **Retention policies**: Bucket retention configured via InfluxDB UI

## Prerequisites

- InfluxDB service running: `systemctl status influxdb2`
- Service accessible on: `http://localhost:8086`
- Home Assistant running and accessible

## Initial InfluxDB Setup

### 1. Access InfluxDB UI

SSH to homelab and create port forward:

```bash
ssh -L 8086:localhost:8086 homelab
```

Open browser: `http://localhost:8086`

### 2. Complete Onboarding Wizard

**First-time setup:**

1. Click "Get Started"
2. **Initial User Setup:**
   - Username: `admin`
   - Password: (generate strong password, save to password manager)
   - Organization Name: `homelab`
   - Bucket Name: `homeassistant`
3. Click "Continue"
4. Click "Configure Later" (skip quick start)

### 3. Configure Retention Policy

**Set 365-day retention for homeassistant bucket:**

1. Navigate to: **Data (left sidebar) → Buckets**
2. Find `homeassistant` bucket, click **⚙️ (Settings)**
3. **Edit Retention:**
   - Delete After: **365 days**
4. Click "Save Changes"

### 4. Generate API Tokens

**Create token for Grafana:**

1. Navigate to: **Data (left sidebar) → API Tokens**
2. Click **"Generate API Token" → "Read/Write Token"**
3. **Token Configuration:**
   - Description: `Grafana Read-Only`
   - Read Buckets: ✓ `homeassistant`
   - Write Buckets: (none)
4. Click "Generate"
5. **Copy token** (shown only once!)
6. Add to secrets:

```bash
# On homelab server
sops secrets/secrets.yaml
# Add: influxdb-token: <paste-token-here>
```

**Create token for Home Assistant:**

1. Navigate to: **Data (left sidebar) → API Tokens**
2. Click **"Generate API Token" → "Read/Write Token"**
3. **Token Configuration:**
   - Description: `Home Assistant Writer`
   - Read Buckets: (none)
   - Write Buckets: ✓ `homeassistant`
4. Click "Generate"
5. **Copy token** (save for next step)

## Home Assistant Integration

### 1. Add InfluxDB Integration

1. Navigate to: **Settings → Devices & Services**
2. Click **"+ Add Integration"**
3. Search: `influxdb`
4. Select **"InfluxDB"**

### 2. Configure Connection

**InfluxDB 2.x Configuration:**

- **Host**: `localhost`
- **Port**: `8086`
- **Use SSL**: ❌ (local connection)
- **Verify SSL**: ❌
- **Version**: `2.x`
- **Organization**: `homelab`
- **Bucket**: `homeassistant`
- **Token**: (paste Home Assistant token from previous step)

Click **"Submit"**

### 3. Configure Entities to Export

**Entity Configuration:**

1. Click **"Configure"** on the InfluxDB integration card
2. **Include/Exclude Options:**
   - **Default**: Export all entities
   - **Recommended**: Exclude high-frequency entities (timestamps, trackers)
   - **Custom**: Select specific domains

**Suggested exclusions:**

- Domains: `persistent_notification`, `update`, `scene`
- Entity patterns: `*_last_*`, `*_timestamp`

3. Click **"Submit"**

### 4. Verify Data Flow

**Check InfluxDB for incoming data:**

1. Access InfluxDB UI: `http://localhost:8086` (via SSH tunnel)
2. Navigate to: **Data Explorer**
3. **Query Builder:**
   - FROM: `homeassistant`
   - Filter: Select any entity (e.g., `sensor.cpu_percent`)
   - Submit
4. Verify data points appear in graph

**Expected behavior:**

- Data starts flowing immediately after integration setup
- Update interval: ~30 seconds (HA default)
- Metrics: state changes + attributes

## Verification

### Check InfluxDB Service

```bash
# Service status
systemctl status influxdb2

# Check logs
journalctl -u influxdb2 -f

# Verify listening port
ss -tlnp | grep 8086
```

### Check HA Integration

```bash
# Home Assistant logs
journalctl -u home-assistant -f | grep -i influx
```

**Expected log entries:**

```text
INFO (MainThread) [homeassistant.components.influxdb] InfluxDB database is ready
```

### Query Metrics

**Via InfluxDB UI:**

1. Data Explorer → Query Builder
2. FROM: `homeassistant`
3. Select measurement (entity)
4. Apply (should show data points)

**Via Grafana:**

1. Access Grafana: `http://192.168.0.241:3000`
2. Create new dashboard
3. Add panel
4. Data source: **InfluxDB**
5. Query: Flux query for any entity
6. Verify data renders

## Troubleshooting

### InfluxDB Service Not Starting

**Check logs:**

```bash
journalctl -u influxdb2 -n 50
```

**Common issues:**

- Port 8086 already in use: `ss -tlnp | grep 8086`
- Permissions on data directory: `/var/lib/influxdb2/`
- Disk space: `df -h`

**Resolution:**

```bash
# Restart service
sudo systemctl restart influxdb2

# Check config
influx config ls
```

### No Data in InfluxDB

**Check HA integration status:**

1. Settings → Devices & Services → InfluxDB
2. Verify: "Connected" status
3. Check configuration (host, port, token)

**Check token permissions:**

- Token must have WRITE access to `homeassistant` bucket
- Regenerate token if unsure

**Check HA logs:**

```bash
journalctl -u home-assistant | grep -i influx | tail -20
```

**Common errors:**

- `unauthorized`: Invalid token or expired
- `connection refused`: InfluxDB service not running
- `not found`: Wrong bucket name

### Grafana Can't Query InfluxDB

**Check token:**

- Token must have READ access to `homeassistant` bucket
- Token correctly added to `secrets/secrets.yaml`
- Grafana service restarted after secret change

**Test manually:**

```bash
# Check secret is decrypted
sudo cat /run/secrets/influxdb-token

# Restart Grafana
sudo systemctl restart grafana
```

### High Disk Usage

**Check bucket size:**

```bash
# InfluxDB data directory
du -sh /var/lib/influxdb2/
```

**Adjust retention if needed:**

1. InfluxDB UI → Data → Buckets
2. Edit `homeassistant` retention
3. Reduce from 365d if disk constrained

**Expected storage:**

- 365d retention: ~10-20 GB (varies by entity count)
- Configurable per deployment needs

## Security Notes

- InfluxDB binds to `127.0.0.1:8086` only (not exposed to network)
- API tokens stored in sops-nix encrypted secrets
- Tokens have minimal scopes (read-only for Grafana, write-only for HA)
- Access via SSH tunnel for remote administration

## Related Documentation

- [InfluxDB 2.x Documentation](https://docs.influxdata.com/influxdb/v2/)
- [Home Assistant InfluxDB Integration](https://www.home-assistant.io/integrations/influxdb/)
- [Grafana InfluxDB Data Source](https://grafana.com/docs/grafana/latest/datasources/influxdb/)
- [Flux Query Language](https://docs.influxdata.com/flux/v0/)
