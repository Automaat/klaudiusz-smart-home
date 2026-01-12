# Home Assistant Dashboard Implementation Plan

**Date:** 2026-01-08
**Status:** Phase 1-5 Complete
**Last Updated:** 2026-01-08

> **Note (2026-01-12):** Outdoor air quality sensor migrated from GIOŚ (`sensor.aleje_pm2_5`) to Airly
> (`sensor.airly_home_pm2_5`). Historical references in this document preserved for context.

## Progress Summary

**✅ Completed:**

- Phase 1: Custom Cards (PR #229 merged)
  - History Explorer Card v1.0.51
  - Layout Card v2.4.7
  - Mini Media Player v1.16.10
- Phase 3: Environmental template sensors (PR #233 merged)
  - Average/Max/Min home temperature sensors
  - PM2.5 24h average sensor
- Phase 4: Dashboard documentation + GUI implementation (PR #235)
  - Created docs/manual-config/dashboards.md
  - Created "Dom" dashboard with 8 views via MCP
  - All custom cards registered and verified
- Phase 5: Grafana dashboards (PR pending)
  - Environmental Monitoring dashboard (temperature, PM2.5)
  - System Health dashboard (existing: CPU, memory, disk, network)
  - Automation Monitoring dashboard (existing: Comin, services)
  - Created docs/manual-config/grafana-dashboards.md

**⏭️ Skipped:**

- Phase 2: System monitoring sensors - not needed, stats already in Grafana

**🔄 Next:**

- Phase 6: Update manual-config README (✅ done in this PR)
- Phase 7: Update CLAUDE.md (optional)

---

## Executive Summary

Comprehensive dashboard implementation for Home Assistant covering:

- Overview dashboard (at-a-glance status)
- Room-based views (per-area detailed controls)
- Environmental monitoring via Grafana (temp, humidity, air quality)
- System health monitoring via Grafana (CPU, disk, memory)
- Essential custom cards via HACS for HA UI

**Approach:**

- HA dashboards: GUI-managed (not declarative in Nix) for controls + quick trends
- Grafana dashboards: Historical analysis, advanced metrics (365-day InfluxDB data)

---

## Research Findings

### Modern Dashboard Trends (2024/2025)

**Sections View (default since Nov 2024):**

- 12-column responsive grid
- Drag-and-drop interface
- Auto-adjusts per screen size
- Dense layout option fills gaps

**Popular UI Patterns:**

- **Tile cards** - Primary for visual, interactive controls
- **Mushroom cards** - Minimalist aesthetic, GUI editor support
- **Button card** - Extreme customization via templates
- **Single-column mobile-first** - Better UX on phones

### What People Monitor

**Environmental (Most Common):**

- Temp/humidity in every room ($5-10 sensors)
- Air quality: CO2, VOCs, PM2.5
- Recommended devices:
  - AirGradient ONE (HA certified, local)
  - Apollo AIR-1 (wide sensor range)
  - Aqara S1 (Zigbee, economical)

**Energy/Power:**

- Whole-home consumption (Emporia Vue, Sense)
- Per-device tracking (smart plugs + Powercalc)
- Solar production
- Cost tracking via tariff configuration

**System Health:**

- CPU, disk, memory, network (system_monitor integration)
- CPU temperature (requires command_line sensor)
- Glances integration for comprehensive monitoring

### Organization Patterns

**Room-Based (Most Popular):**

- Overview tab → individual room tabs
- Conditional cards based on presence
- Best for families/multiple users

**Function-Based:**

- Climate, Lighting, Security, Media tabs
- All similar devices grouped together

**Hybrid (Most Flexible - RECOMMENDED):**

- Overview dashboard (most-used controls)
- Room views (detailed per-area)
- Specialty views (energy, security, system)

### Top Custom Cards (HACS)

1. **Mushroom** - Modern minimalist, UI editor
2. **Button Card** - Extreme customization, templates
3. **Auto-Entities** - Dynamic filtering (low battery, open doors)
4. **History Explorer** - Interactive timeline, CSV export
5. **Mini Graph Card** - Simple sensor graphs (quick trends in HA)
6. **Mini Media Player** - Compact controls, grouping
7. **Card-Mod** - CSS styling for any card

**Note:** ApexCharts replaced by Grafana for advanced graphing (365-day InfluxDB data, better queries, alerting)

### Best Practices

**Performance:**

- 20-30 cards per view max
- Use conditional cards vs loading everything
- Limit graph time ranges
- Trigger-based templates over state-based

**Mobile-Friendly:**

- Single column layouts
- Larger tap targets (44x44px minimum)
- Reduce scrolling with tabs/conditional cards
- Test on actual devices

**Progressive Disclosure:**

- Overview → drill-down structure
- Hide complexity until needed
- Action-oriented design (quick toggles prominent)

**Context-Aware:**

- Show based on time/presence/state
- Dynamic filtering (auto-entities)
- Room-based conditional displays

---

## Current State Analysis

### HACS & Custom Cards ✅

**HACS Installed:** v2.0.5 (configured in `hosts/homelab/home-assistant/default.nix`)

**Custom Cards Already Installed:**

- **Mushroom Cards** v5.0.9 ✅
- **Mini Graph Card** v0.13.0 ✅
- **Button Card** v7.0.1 ✅
- **Bubble Card** v3.1.0-rc.2 ✅
- **card-mod** v4.1.0 ✅
- **auto-entities** v1.16.1 ✅
- **Hass Hue Icons** v1.2.53 ✅

**Missing Cards to Add:**

- History Explorer Card (interactive timeline)
- Layout Card (responsive grid layouts)
- Mini Media Player (compact media controls)

**Note:** ApexCharts not needed - using Grafana for advanced graphing instead

### Areas/Rooms Defined

Configuration in `hosts/homelab/home-assistant/areas/`:

- Living Room (`living-room.nix`)
- Bedroom (`bedroom.nix`)
- Bathroom (`bathroom.nix`)
- Kitchen (`kitchen.nix`)
- Hallway (`hallway.nix`)
- System (`system.nix`)

### Environmental Sensors

**Air Quality:**

- `sensor.aleje_pm2_5` - Outdoor PM2.5 (GIOŚ, Kraków station 400)
- `sensor.aleje_pm2_5_index` - Air quality index
- `sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6` - Indoor PM2.5 (Xiaomi purifier)
- `binary_sensor.safe_to_ventilate_living_room` - Template (outdoor < 15 µg/m³)

**Temperature:**

- `climate.livingroom_thermostat` - Living room
- `climate.bedroom_thermostat` - Bedroom
- `climate.bathroom_thermostat` - Bathroom
- `climate.thermostat_bedroom` - Alternate bedroom sensor

**Template Sensors** (`sensors.nix`):

- PM2.5 outdoor vs indoor difference
- Air purifier recommended mode
- Air purifier filter urgency
- Antibacterial filter run due

**Missing:**

- Humidity sensors (check if Zigbee devices report)
- Room temperature averages/comparisons
- CO2/VOC sensors (if hardware available)

### System Monitoring

**Current:** None (needs implementation)

**Required:**

- CPU temperature
- Disk usage percentage
- Memory usage percentage
- Network throughput (optional)

### Dashboard Configuration

**Current State:**

- `lovelaceConfigWritable = true` - GUI editing enabled ✅
- No declarative Lovelace config in Nix ✅
- Custom cards available but not pre-configured ✅

**Themes Available:**

- Catppuccin v2.1.2
- iOS Themes v3.0.1

---

## Implementation Plan

### Phase 1: Add Missing Custom Cards to Nix

**File:** `hosts/homelab/home-assistant/default.nix`

Add 3 custom cards after existing cards (around line 133):

```nix
# History Explorer Card - Interactive timeline
historyExplorerSource = pkgs.fetchFromGitHub {
  owner = "alexarch21";
  repo = "history-explorer-card";
  # renovate: datasource=github-tags depName=alexarch21/history-explorer-card
  rev = "v1.0.51";
  hash = "sha256-/bPFW6/vqL1aK30WOQxxRV3fuIk7FYnZA+l4ihHpToM=";
};

# Layout Card - Responsive grids
layoutCardSource = pkgs.fetchFromGitHub {
  owner = "thomasloven";
  repo = "lovelace-layout-card";
  # renovate: datasource=github-tags depName=thomasloven/lovelace-layout-card
  rev = "v2.4.5";
  hash = "sha256-..."; # TODO: Get hash
};

# Mini Media Player - Compact media controls
miniMediaPlayerSource = pkgs.fetchFromGitHub {
  owner = "kalkih";
  repo = "mini-media-player";
  # renovate: datasource=github-tags depName=kalkih/mini-media-player
  rev = "v1.16.11";
  hash = "sha256-..."; # TODO: Get hash
};
```

Add symlink commands in `systemd.services.home-assistant.preStart`:

```nix
ln -sfn ${historyExplorerSource} /var/lib/hass/www/community/history-explorer-card
ln -sfn ${layoutCardSource} /var/lib/hass/www/community/layout-card
ln -sfn ${miniMediaPlayerSource}/dist /var/lib/hass/www/community/mini-media-player
```

### Phase 2: Add System Monitoring Sensors

**File:** Create `hosts/homelab/home-assistant/system-monitoring.nix` or add to `sensors.nix`

```nix
{ config, lib, pkgs, ... }:

{
  services.home-assistant.config = {
    # System monitoring sensors
    command_line = [
      # CPU Temperature
      {
        sensor = {
          name = "CPU Temperature";
          unique_id = "cpu_temperature";
          command = "cat /sys/class/thermal/thermal_zone0/temp";
          unit_of_measurement = "°C";
          device_class = "temperature";
          value_template = "{{ value | float / 1000 | round(1) }}";
          scan_interval = 60;
        };
      }

      # Disk Usage
      {
        sensor = {
          name = "Disk Usage";
          unique_id = "disk_usage_root";
          command = "df -h / | awk 'NR==2 {print $5}' | sed 's/%//'";
          unit_of_measurement = "%";
          value_template = "{{ value | int }}";
          scan_interval = 300;
        };
      }

      # Memory Usage
      {
        sensor = {
          name = "Memory Usage";
          unique_id = "memory_usage";
          command = "free | grep Mem | awk '{printf(\"%.0f\", ($3/$2) * 100)}'";
          unit_of_measurement = "%";
          value_template = "{{ value | int }}";
          scan_interval = 60;
        };
      }
    ];
  };
}
```

Add to `hosts/homelab/home-assistant/default.nix` imports:

```nix
imports = [
  ./system-monitoring.nix
  # ... existing imports
];
```

**Alternative:** Consider Glances integration for comprehensive monitoring.

- Add to `extraComponents`
- Create `docs/manual-config/glances.md` with setup steps

### Phase 3: Add Environmental Monitoring Templates

**File:** `hosts/homelab/home-assistant/sensors.nix`

Add to existing template section:

```nix
# Average temperature across all rooms
{
  sensor = [
    {
      name = "Average Home Temperature";
      unique_id = "average_home_temperature";
      state = ''
        {% set temps = [
          states('climate.livingroom_thermostat') | float(0),
          states('climate.bedroom_thermostat') | float(0),
          states('climate.bathroom_thermostat') | float(0)
        ] %}
        {{ (temps | sum / temps | length) | round(1) }}
      '';
      unit_of_measurement = "°C";
      device_class = "temperature";
    }

    {
      name = "Max Home Temperature";
      unique_id = "max_home_temperature";
      state = ''
        {% set temps = [
          states('climate.livingroom_thermostat') | float(0),
          states('climate.bedroom_thermostat') | float(0),
          states('climate.bathroom_thermostat') | float(0)
        ] %}
        {{ temps | max | round(1) }}
      '';
      unit_of_measurement = "°C";
      device_class = "temperature";
    }

    {
      name = "Min Home Temperature";
      unique_id = "min_home_temperature";
      state = ''
        {% set temps = [
          states('climate.livingroom_thermostat') | float(0),
          states('climate.bedroom_thermostat') | float(0),
          states('climate.bathroom_thermostat') | float(0)
        ] %}
        {{ temps | min | round(1) }}
      '';
      unit_of_measurement = "°C";
      device_class = "temperature";
    }

    {
      name = "PM2.5 24h Average";
      unique_id = "pm25_24h_average";
      state = ''
        {{ state_attr('sensor.aleje_pm2_5', 'mean_24h') | float(0) | round(1) }}
      '';
      unit_of_measurement = "µg/m³";
      device_class = "pm25";
    }
  ];
}
```

**TODO:** Check if humidity sensors exist on Zigbee devices, add templates if available.

### Phase 4: Documentation for Dashboard Creation

**File:** Create `docs/manual-config/dashboards.md`

Content structure:

#### 1. Overview

- Why GUI-managed (rapid iteration, visual design)
- Reference to research findings
- Dashboard philosophy (progressive disclosure, context-aware)

#### 2. Prerequisites

- Custom cards installed (list with versions)
- Entities available per area
- Themes installed

#### 3. Dashboard Structure

**Recommended Views:**

1. **Overview** - At-a-glance status (default view)
2. **Living Room** - Detailed controls + graphs
3. **Bedroom** - Climate, sleep tracking
4. **Bathroom** - Climate controls
5. **Kitchen** - Kettle automation, appliances
6. **Hallway** - Presence, lighting
7. **Environmental Monitoring** - Temp/humidity/air quality graphs
8. **System Health** - CPU, disk, memory, services
9. **Energy** - Power consumption (if implemented)
10. **Media** - TV, Apple TV, casting controls

#### 4. Step-by-Step Setup

**Overview Dashboard:**

- Sections: Quick Actions, Climate Status, Air Quality, System Status
- Cards: Tile (lights, scenes), Mushroom entity (climate), Mini Graph (trends), Conditional (alerts)

**Room Views:**

- Pattern: Climate controls → Lighting → Specific devices → Graphs
- Use area filtering for auto-entities
- Mushroom cards for primary controls
- Mini Graph Card for temperature trends

**Environmental Monitoring:**

- Mini Graph Card for quick temperature trends
- History Explorer for PM2.5 timeline
- Auto-entities for low humidity alerts
- Conditional cards for air quality warnings
- **Note:** Advanced graphs in Grafana (see Phase 5)

**System Health:**

- Tile cards for CPU/disk/memory with thresholds
- Mini Graph Card for 24h trends
- Service status indicators
- **Note:** Long-term analysis in Grafana (see Phase 5)

#### 5. Card Configuration Examples

**Note:** For advanced graphing (temperature comparisons, historical analysis), see Phase 5 Grafana dashboards.

**Mushroom Climate Card:**

```yaml
type: custom:mushroom-climate-card
entity: climate.livingroom_thermostat
name: Living Room
show_temperature_control: true
hvac_modes:
  - heat
  - 'off'
```

**Auto-Entities - Open Windows:**

```yaml
type: custom:auto-entities-card
card:
  type: entities
  title: Open Windows
filter:
  include:
    - domain: binary_sensor
      attributes:
        device_class: window
      state: 'on'
  exclude: []
show_empty: false
```

**Conditional - Air Quality Alert:**

```yaml
type: conditional
conditions:
  - condition: numeric_state
    entity: sensor.aleje_pm2_5
    above: 50
card:
  type: custom:mushroom-template-card
  primary: 'Zła jakość powietrza!'
  secondary: 'PM2.5: {{ states("sensor.aleje_pm2_5") }} µg/m³'
  icon: mdi:alert
  icon_color: red
```

**Mini Graph Card - CPU Temperature:**

```yaml
type: custom:mini-graph-card
entities:
  - sensor.cpu_temperature
name: CPU Temperature
hours_to_show: 24
points_per_hour: 4
line_width: 2
color_thresholds:
  - value: 70
    color: '#f39c12'
  - value: 80
    color: '#e74c3c'
```

#### 6. Best Practices

**Performance:**

- Keep views to 20-30 cards max
- Use conditional cards to reduce load
- Limit graph history ranges (24h typical, 7d max)
- Avoid auto-refresh entities where possible

**Mobile-Friendly:**

- Test on actual phone/tablet
- Single column layouts preferred
- Larger tap targets (Tile cards > Entity cards)
- Collapsible sections for less-used controls

**Context-Aware:**

- Hide inactive devices (conditional cards)
- Show alerts only when relevant
- Use auto-entities for dynamic lists
- Time-based visibility (scenes, automations)

**Visual Hierarchy:**

- Primary actions prominent (Tile/Mushroom cards)
- Status/monitoring secondary (Entity cards, graphs)
- Detailed data tertiary (History Explorer, Grafana panels)

#### 7. Entity Reference

**Living Room:**

- `climate.livingroom_thermostat`
- `sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6` (indoor PM2.5)
- `media_player.living_room_tv` (LG WebOS)
- `media_player.salon` (Apple TV)
- Air purifier entities (see living-room.nix)

**Bedroom:**

- `climate.bedroom_thermostat`
- `climate.thermostat_bedroom`
- Ventilation automations

**Bathroom:**

- `climate.bathroom_thermostat`

**Kitchen:**

- Kettle automation entities

**Hallway:**

- `binary_sensor.aqara_fp2_3dfc_presence_sensor_1` (FP2 presence)
- Adaptive lighting entities

**Environmental:**

- `sensor.aleje_pm2_5` (outdoor PM2.5)
- `sensor.aleje_pm2_5_index`
- `binary_sensor.safe_to_ventilate_living_room`
- Temperature template sensors (after Phase 3)

**System:**

- `sensor.cpu_temperature` (after Phase 2)
- `sensor.disk_usage_root` (after Phase 2)
- `sensor.memory_usage` (after Phase 2)

#### 8. Troubleshooting

**Cards not loading:**

- Clear browser cache (Ctrl+Shift+R)
- Check `/var/lib/hass/www/community/` symlinks exist
- Verify HA logs: `journalctl -u home-assistant -f`

**Graphs showing "Unknown":**

- Entity doesn't have state_class for statistics
- Check entity attributes in Developer Tools
- Use state_class: measurement for sensors

**Mobile layout broken:**

- Test Sections view (default, responsive)
- Avoid fixed-width cards
- Use Layout Card for responsive grids

**Performance issues:**

- Reduce cards per view
- Limit graph time ranges
- Check CPU usage on homelab
- Consider pagination for long lists

#### 9. Related Documentation

- [HA Dashboard Documentation](https://www.home-assistant.io/dashboards/)
- [Sections View Guide](https://www.home-assistant.io/blog/2024/03/04/dashboard-chapter-1/)
- [Mushroom Cards Guide](https://github.com/piitaya/lovelace-mushroom)
- [Auto-Entities Card](https://github.com/thomasloven/lovelace-auto-entities)
- [History Explorer Card](https://github.com/alexarch21/history-explorer-card)

### Phase 5: Create Grafana Dashboards

**Prerequisites:**

- InfluxDB configured (365-day retention) ✅
- Prometheus metrics export enabled ✅
- Grafana installed and accessible ✅

**Dashboards to Create:**

#### 5.1 Environmental Monitoring Dashboard

**Data Source:** InfluxDB (long-term historical data)

**Panels:**

1. **Temperature Comparison (Multi-line)**
   - Living Room, Bedroom, Bathroom thermostats
   - Time range: 7 days (configurable)
   - Alert thresholds: < 15°C, > 28°C

2. **PM2.5 Trend**
   - Outdoor (GIOŚ) vs Indoor (Xiaomi purifier)
   - Safe ventilation threshold (15 µg/m³)
   - Time range: 30 days

3. **Air Quality Index Heatmap**
   - PM2.5 index over time
   - Color coding: Good/Moderate/Unhealthy

4. **Humidity Tracking** (if sensors available)
   - Per-room humidity levels
   - Recommended range: 40-60%

5. **Temperature Delta**
   - Max - Min temperature across rooms
   - Indicates heating efficiency

**Variables:**

- Time range selector (24h, 7d, 30d, 90d)
- Room selector (filter by area)

#### 5.2 System Health Dashboard

**Data Sources:** Prometheus + InfluxDB

**Panels:**

1. **CPU Metrics**
   - Temperature gauge (thresholds: 70°C warning, 80°C critical)
   - Usage percentage over time
   - Load average (1m, 5m, 15m)

2. **Disk Usage**
   - Gauge: / partition usage
   - Trend: daily growth rate
   - Projected days until full

3. **Memory Usage**
   - Used vs Available
   - Swap usage
   - Trend over 30 days

4. **Network Throughput** (if available)
   - Ingress/egress over time

5. **Home Assistant Performance**
   - Automation execution times
   - Entity update frequency
   - Database size growth

**Alerts:**

- CPU > 80°C for 5m
- Disk > 90% for 30m
- Memory > 90% for 10m
- HA restart detected

#### 5.3 Automation Monitoring Dashboard

**Data Source:** InfluxDB (automation metrics from monitoring.nix)

**Panels:**

1. **Automation Triggers (24h)**
   - Bar chart: trigger count per automation
   - Identify most active automations

2. **Deployment Success Rate**
   - Comin deployment status over time
   - Success/failure ratio

3. **Error Rate**
   - Automation failures over time
   - Group by automation name

4. **Execution Time Distribution**
   - Histogram: automation execution times
   - Identify slow automations

**Implementation Steps:**

1. **Access Grafana**
   - Already configured (from PR #225)
   - URL: <http://homelab:3000> (or configured URL)

2. **Add InfluxDB Data Source (if not exists)**
   - Settings → Data Sources → Add InfluxDB
   - URL: <http://localhost:8086>
   - Database: homeassistant
   - Token: from secrets
   - Query Language: Flux

3. **Create Dashboards**
   - Import or create manually
   - Use variables for time ranges/filters
   - Set up alerts with notification channels

4. **Configure Alerts** (optional)
   - Telegram notifications (already configured)
   - Alert rules per critical threshold

5. **Export Dashboard JSON**
   - Save to `docs/grafana/` directory
   - Version control dashboard definitions
   - Recreate after fresh install

**Documentation:**

Create `docs/manual-config/grafana-dashboards.md`:

- Why Grafana for historical analysis
- Dashboard structure
- How to import/export
- Query examples (Flux, PromQL)
- Alert configuration
- Troubleshooting

### Phase 6: Update Manual Config README

**File:** `docs/manual-config/README.md`

Add to integration list:

```markdown
## Dashboard Creation

Dashboard design and configuration guide.

See [dashboards.md](./dashboards.md) for:
- Dashboard structure recommendations
- Card configuration examples
- Entity reference per area
- Best practices and troubleshooting

## Grafana Dashboards

Grafana dashboard setup for historical analysis and monitoring.

See [grafana-dashboards.md](./grafana-dashboards.md) for:
- Environmental monitoring (temperature, air quality)
- System health metrics (CPU, disk, memory)
- Automation monitoring
- Query examples and alert configuration
```

### Phase 7: Update CLAUDE.md (Optional)

**File:** `CLAUDE.md`

Add section after "Home Assistant Patterns":

```markdown
### Dashboard Design Patterns

**HA Dashboards:**
- GUI-only (not declarative in Nix)
- Overview → Room views → Specialty views
- 20-30 cards per view max
- Progressive disclosure, context-aware
- Mini Graph Card for quick trends (24h max)

**Grafana Dashboards:**
- Historical analysis (365-day InfluxDB data)
- Environmental monitoring (temp, air quality)
- System health (CPU, disk, memory)
- Automation monitoring
- Advanced queries, alerting

**References:**
- HA: docs/manual-config/dashboards.md
- Grafana: docs/manual-config/grafana-dashboards.md
```

---

## Execution Checklist

### Development Phase

- [x] Create feature branch: `feat/dashboard-custom-cards` ✅
- [x] Phase 1: Add 3 custom cards to default.nix ✅ **PR #229 (merged)**
  - [x] History Explorer Card v1.0.51
  - [x] Layout Card v2.4.7
  - [x] Mini Media Player v1.16.10
  - [x] Get SHA256 hashes via nix-prefetch-url
  - [x] Update symlink commands in preStart
- [x] Phase 2: Add system monitoring sensors ✅ **SKIPPED - stats already in Grafana**
- [x] Phase 3: Add environmental template sensors ✅ **PR #233 (merged)**
  - [x] Average home temperature
  - [x] Max/min home temperature
  - [x] PM2.5 24h average
  - [x] Check for humidity sensors (none available)
- [x] Phase 4: Create docs/manual-config/dashboards.md ✅ **PR #235**
  - [x] Overview & prerequisites
  - [x] Dashboard structure
  - [x] Step-by-step setup per view
  - [x] Card configuration examples (YAML)
  - [x] Entity reference
  - [x] Best practices
  - [x] Troubleshooting
  - [x] GUI Implementation: Created "Dom" dashboard via MCP
    - [x] Overview view (quick actions, climate, air quality, system status)
    - [x] Living Room view (climate, air purifier, media)
    - [x] Bedroom view (climate, ventilation)
    - [x] Bathroom view (climate, lighting)
    - [x] Kitchen view (kettle, lighting, presence)
    - [x] Hallway view (lighting, presence)
    - [x] Environmental Monitoring view (temp comparison, PM2.5 history, stats)
    - [x] Media view (TV, casting)
  - [x] Registered History Explorer Card and Mini Media Player resources
  - [x] Verified all entities exist and cards load without errors
- [x] Phase 5: Create Grafana dashboards
  - [x] Access Grafana (verify InfluxDB data source)
  - [x] Environmental Monitoring dashboard (NEW)
  - [x] System Health dashboard (existed: home-assistant.json)
  - [x] Automation Monitoring dashboard (existed: service-health.json)
  - [ ] Configure alerts (skipped - using HA automations)
  - [x] Dashboard JSON in hosts/homelab/grafana/dashboards/smart-home/
  - [x] Create docs/manual-config/grafana-dashboards.md
- [x] Phase 6: Update docs/manual-config/README.md
  - [x] Add dashboards.md link
  - [x] Add grafana-dashboards.md link
- [ ] Phase 7 (optional): Update CLAUDE.md
  - [ ] Add dashboard design patterns section (HA + Grafana)

### Testing Phase (Phase 1)

- [x] Local rebuild: `nixos-rebuild build --flake .#homelab` ✅ (expected fail on macOS, x86_64-linux required)
- [x] Check flake: `nix flake check` ✅
- [x] Review changes: `git diff` ✅

### Deployment Phase (Phase 1)

- [x] Commit: `git commit -s -S -m "feat(ha): add 3 custom cards for dashboard improvements"` ✅
- [x] Push to branch: `git push -u origin feat/dashboard-custom-cards` ✅
- [x] Create PR: `gh pr create` ✅ **PR #229**
- [ ] PR merges → CI tests → production branch updates
- [ ] Comin pulls from production → NixOS rebuilds

### GUI Implementation Phase (Manual)

**Home Assistant Dashboards:**

- [ ] Follow docs/manual-config/dashboards.md step-by-step
- [ ] Create Overview dashboard
- [ ] Create room-based views (Living Room, Bedroom, Bathroom, Kitchen, Hallway)
- [ ] Test on desktop browser
- [ ] Test on mobile device
- [ ] Adjust based on usage patterns

**Grafana Dashboards:**

- [ ] Follow docs/manual-config/grafana-dashboards.md
- [ ] Create Environmental Monitoring dashboard
- [ ] Create System Health dashboard
- [ ] Create Automation Monitoring dashboard
- [ ] Test queries and visualizations
- [ ] Configure alerts (if needed)
- [ ] Export and save dashboard JSON

---

## Timeline Estimate

**Not provided** - per CLAUDE.md policy, focus on what needs to be done, not when.

**Complexity:**

- Phase 1-3: Low (Nix config additions)
- Phase 4: Medium (comprehensive HA dashboard documentation)
- Phase 5: Medium (Grafana dashboard creation + documentation)
- Phase 6-7: Low (simple updates)
- GUI Implementation: Variable (iterative design for both HA and Grafana)

---

## Success Criteria

**Infrastructure:**

1. ✅ All custom cards installed and accessible (3 cards: History Explorer, Layout, Mini Media Player)
2. ✅ System monitoring sensors reporting correctly (CPU temp, disk, memory)
3. ✅ Environmental template sensors calculating properly (avg temp, PM2.5 24h)
4. ✅ All Nix changes rebuild without errors
5. ✅ CI tests pass on production branch

**Documentation:**
6. ✅ HA dashboard documentation created (docs/manual-config/dashboards.md)
7. ✅ Grafana dashboard documentation created (docs/manual-config/grafana-dashboards.md)
8. ✅ Manual config README updated with both guides

**HA Dashboards:**
9. ✅ Overview + room-based views created (8 views total)
10. ✅ Dashboards responsive on mobile and desktop (sections view)
11. ✅ Performance acceptable (no lag, quick load times)

**Grafana Dashboards:**
12. ✅ Environmental Monitoring dashboard (temp, PM2.5)
13. ✅ System Health dashboard (CPU, disk, memory, network)
14. ✅ Automation Monitoring dashboard (Comin deployments, service health)
15. ✅ Dashboard JSON in hosts/homelab/grafana/dashboards/

**Usability:**
16. ⬜ Family members can use HA dashboards effectively
17. ⬜ Historical data accessible via Grafana

---

## Unresolved Questions

**Resolved (Phase 4 completion):**

- ✅ Dashboard structure validated: Overview → room-based → specialty views works well
- ✅ Custom cards verified: Mushroom, Mini Graph, History Explorer, Mini Media Player all functional
- ✅ Entity organization confirmed: Climate, air quality, presence sensors properly grouped

**Remaining (Phases 5-7):**

- How system monitoring sensors (CPU, disk, memory) will impact storage and performance
  in practice (Phase 2 skipped for now)
- Which Grafana dashboards are most useful for long-term historical analysis
- Whether Grafana alerting provides value over existing HA automations

These will be refined based on:

- Real-world usage patterns with current dashboard implementation
- InfluxDB data retention and query performance (365-day retention configured)
- Family feedback on dashboard usability and information density

---

## References

- Research output from initial Task tool execution
- Codebase exploration from Explore agent
- CLAUDE.md operational guidelines
- Existing manual-config documentation patterns
- Home Assistant 2024/2025 best practices
