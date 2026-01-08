# Home Assistant Dashboard Configuration

## Overview

This guide covers creating GUI-managed dashboards in Home Assistant for day-to-day controls and quick status views.

**Why GUI-managed:**
- Rapid iteration without rebuilds
- Visual design and layout tweaking
- Responsive sections view (modern HA default)
- No Nix complexity for visual changes

**Philosophy:**
- Progressive disclosure (overview → detailed views)
- Context-aware (show only relevant info)
- Mobile-first (test on actual devices)
- Performance-conscious (20-30 cards per view max)

**For advanced graphing:** Use Grafana (365-day InfluxDB data, better queries, alerting) - see `grafana-dashboards.md`

## Prerequisites

### Custom Cards Installed

All cards available via HACS + Nix configuration:

**Already Installed:**
- **Mushroom Cards** v5.0.9 - Modern minimalist, UI editor
- **Mini Graph Card** v0.13.0 - Simple sensor graphs (quick trends)
- **Button Card** v7.0.1 - Extreme customization
- **Bubble Card** v3.1.0 - Compact controls
- **card-mod** v4.1.0 - CSS styling
- **auto-entities** v1.16.1 - Dynamic filtering
- **Hass Hue Icons** v1.2.53 - Extended icon set
- **History Explorer Card** v1.0.51 - Interactive timeline
- **Layout Card** v2.4.7 - Responsive grids
- **Mini Media Player** v1.16.10 - Compact media controls

### Themes Available

- Catppuccin v2.1.2
- iOS Themes v3.0.1

### Areas Defined

- Living Room
- Bedroom
- Bathroom
- Kitchen
- Hallway
- System

## Dashboard Structure

**Recommended hybrid approach:**

### 1. Overview (Default View)
At-a-glance status and most-used controls

**Sections:**
- Quick Actions (scenes, frequent toggles)
- Climate Status (temperature summary)
- Air Quality (PM2.5, ventilation status)
- System Status (alerts, critical metrics)

### 2. Room-Based Views
Per-area detailed controls

**Pattern:**
- Climate controls (thermostat, temperature trends)
- Lighting (switches, scenes)
- Room-specific devices
- Mini graphs for quick trends (24h max)

**Views:**
- Living Room (climate, purifier, TV, Apple TV)
- Bedroom (climate, ventilation, sleep)
- Bathroom (climate)
- Kitchen (kettle automation, appliances)
- Hallway (presence, adaptive lighting)

### 3. Specialty Views

**Environmental Monitoring:**
- Temperature comparison across rooms
- Air quality trends (outdoor vs indoor)
- Humidity levels (if sensors available)
- Ventilation recommendations
- **Note:** Advanced analysis in Grafana (see `grafana-dashboards.md`)

**Media:**
- TV controls (LG WebOS)
- Apple TV
- Media player grouping
- Now playing

**System Health:**
- Service status indicators
- Critical alerts
- **Note:** Long-term metrics in Grafana

## Step-by-Step Setup

### Creating Dashboards

1. **Settings → Dashboards → Add Dashboard**
2. Choose "Sections" view type (modern, responsive)
3. Name dashboard (e.g., "Home Overview")
4. Click "Edit" → Start adding sections and cards

### Overview Dashboard

**Section: Quick Actions**
- Tile cards for most-used lights
- Scene buttons (Morning, Evening, Night)
- Quick toggles (Air purifier modes)

**Section: Climate Status**
- Mushroom entity cards for each thermostat
- Mini Graph Card: Average home temperature (24h)
- Conditional: heating alerts

**Section: Air Quality**
- Tile: Outdoor PM2.5 with color thresholds
- Tile: Indoor PM2.5
- Conditional: "Safe to ventilate" indicator
- Mini Graph: PM2.5 24h trend

**Section: System Status**
- Auto-entities: Low battery devices
- Auto-entities: Unavailable entities
- Conditional alerts (appears only when needed)

### Living Room View

**Section: Climate**
```yaml
# Mushroom climate card
type: custom:mushroom-climate-card
entity: climate.livingroom_thermostat
name: Temperatura
show_temperature_control: true
hvac_modes:
  - heat
  - 'off'
collapsible_controls: true
```

```yaml
# Mini Graph - Temperature trend
type: custom:mini-graph-card
entities:
  - entity: climate.livingroom_thermostat
    attribute: current_temperature
    name: Salon
name: Temperatura - ostatnie 24h
hours_to_show: 24
points_per_hour: 2
line_width: 2
```

**Section: Air Purifier**
- Tile cards for fan controls
- Filter status indicators
- PM2.5 display (indoor sensor)

**Section: Media**
- Mini Media Player: Living Room TV
- Mini Media Player: Apple TV (Salon)
- Grouping if multiple active

### Bedroom View

**Section: Climate**
- Mushroom climate card: `climate.bedroom_thermostat`
- Mini Graph: bedroom temperature (24h)

**Section: Ventilation**
- Conditional: safe to ventilate indicator
- Manual override buttons

### Environmental Monitoring View

**Multi-Room Temperature Comparison:**
```yaml
type: custom:mini-graph-card
entities:
  - entity: climate.livingroom_thermostat
    attribute: current_temperature
    name: Salon
  - entity: climate.bedroom_thermostat
    attribute: current_temperature
    name: Sypialnia
  - entity: climate.bathroom_thermostat
    attribute: current_temperature
    name: Łazienka
name: Temperatura - porównanie pokoi
hours_to_show: 24
points_per_hour: 2
line_width: 2
aggregate_func: last
group_by: hour
```

**PM2.5 Timeline:**
```yaml
type: custom:history-explorer-card
cardName: PM2.5 History
entities:
  - entity: sensor.aleje_pm2_5
    name: Outdoor
  - entity: sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6
    name: Indoor
defaultTimeRange: 7d
```

**Air Quality Alert (Conditional):**
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

### Auto-Entities Patterns

**Low Battery Devices:**
```yaml
type: custom:auto-entities
card:
  type: entities
  title: Niski poziom baterii
filter:
  include:
    - attributes:
        device_class: battery
      state: '<' 20
  exclude: []
show_empty: false
```

**Open Windows/Doors:**
```yaml
type: custom:auto-entities
card:
  type: entities
  title: Otwarte okna/drzwi
filter:
  include:
    - domain: binary_sensor
      attributes:
        device_class: window
      state: 'on'
    - domain: binary_sensor
      attributes:
        device_class: door
      state: 'on'
  exclude: []
show_empty: false
```

**Unavailable Entities:**
```yaml
type: custom:auto-entities
card:
  type: entities
  title: Niedostępne urządzenia
filter:
  include:
    - state: unavailable
  exclude:
    - entity_id: '*_update'
    - entity_id: 'update.*'
show_empty: false
```

## Card Configuration Examples

### Tile Card (Lights, Switches)

```yaml
type: tile
entity: light.living_room
name: Salon - Główne
show_entity_picture: false
vertical: false
```

### Mushroom Entity Card (Status)

```yaml
type: custom:mushroom-entity-card
entity: binary_sensor.safe_to_ventilate_living_room
name: Wietrzenie bezpieczne
icon_color: green
```

### Button Card (Scenes)

```yaml
type: custom:button-card
entity: scene.morning_routine
name: Poranny
icon: mdi:weather-sunset-up
tap_action:
  action: call-service
  service: scene.turn_on
  target:
    entity_id: scene.morning_routine
```

### Layout Card (Responsive Grid)

```yaml
type: custom:layout-card
layout_type: grid
layout:
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr))
  grid-gap: 8px
cards:
  - type: tile
    entity: light.bedroom
  - type: tile
    entity: light.kitchen
  - type: tile
    entity: light.hallway
```

## Best Practices

### Performance

- **20-30 cards per view max** - Split into multiple tabs if needed
- **Use conditional cards** - Reduce load by hiding inactive content
- **Limit graph time ranges** - 24h typical, 7d maximum for Mini Graph Card
- **Avoid auto-refresh** - Use trigger-based updates where possible
- **Use Grafana for long-term** - Keep HA dashboards for controls and quick views

### Mobile-Friendly

- **Test on actual devices** - Desktop looks different than phone
- **Single column preferred** - Sections view auto-adjusts, but verify
- **Larger tap targets** - Tile cards > Entity cards for touch
- **Collapsible controls** - Use `collapsible_controls: true` on Mushroom cards
- **Minimize scrolling** - Use tabs and conditional cards

### Context-Aware

**Hide inactive devices:**
```yaml
type: conditional
conditions:
  - condition: state
    entity: media_player.living_room_tv
    state: 'on'
card:
  # Media player controls
```

**Show alerts only when relevant:**
```yaml
type: conditional
conditions:
  - condition: numeric_state
    entity: sensor.aleje_pm2_5
    above: 50
card:
  # Air quality warning
```

**Time-based visibility:**
```yaml
type: conditional
conditions:
  - condition: time
    after: '22:00'
    before: '06:00'
card:
  # Night mode controls
```

### Visual Hierarchy

**Primary actions prominent:**
- Use Tile cards or large Mushroom cards
- Top of sections
- Frequently accessed controls

**Status/monitoring secondary:**
- Entity cards
- Mini graphs below controls
- Auto-entities lists

**Detailed data tertiary:**
- History Explorer for deep dives
- Links to Grafana dashboards
- Collapsible sections

## Entity Reference

### Living Room
- `climate.livingroom_thermostat` - Thermostat
- `sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6` - Indoor PM2.5
- `media_player.living_room_tv` - LG WebOS TV
- `media_player.salon` - Apple TV
- Air purifier entities (see `hosts/homelab/home-assistant/areas/living-room.nix`)

### Bedroom
- `climate.bedroom_thermostat` - Thermostat
- `climate.thermostat_bedroom` - Alternate thermostat
- Ventilation automation entities

### Bathroom
- `climate.bathroom_thermostat` - Thermostat

### Kitchen
- Kettle automation entities (see `hosts/homelab/home-assistant/areas/kitchen.nix`)

### Hallway
- `binary_sensor.aqara_fp2_3dfc_presence_sensor_1` - FP2 presence
- Adaptive lighting entities

### Environmental
- `sensor.aleje_pm2_5` - Outdoor PM2.5 (GIOŚ, Kraków station 400)
- `sensor.aleje_pm2_5_index` - Air quality index
- `binary_sensor.safe_to_ventilate_living_room` - Ventilation safety indicator
- `sensor.average_home_temperature` - Average across all rooms (template)
- `sensor.max_home_temperature` - Highest room temperature (template)
- `sensor.min_home_temperature` - Lowest room temperature (template)
- `sensor.pm25_24h_average` - 24-hour PM2.5 average (template)

### System
- Service status indicators (configured separately)
- System monitoring sensors (if Phase 2 implemented)

## Troubleshooting

### Cards Not Loading

**Symptom:** Custom card shows as "Custom element doesn't exist"

**Solutions:**
1. Clear browser cache: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
2. Check symlinks exist on server:
   ```bash
   ls -la /var/lib/hass/www/community/
   ```
3. Verify HA logs:
   ```bash
   journalctl -u home-assistant -f | grep -i "custom card"
   ```
4. Check card installed in HACS (Settings → HACS → Frontend)
5. Restart Home Assistant: `systemctl restart home-assistant`

### Graphs Showing "Unknown"

**Symptom:** Mini Graph Card shows no data or "Unknown"

**Causes:**
- Entity doesn't have `state_class` for statistics
- Entity attribute doesn't exist
- Time range has no data

**Solutions:**
1. Check entity attributes in Developer Tools → States
2. Verify entity has `state_class: measurement` or `state_class: total_increasing`
3. For climate temperature, use `attribute: current_temperature`
4. Reduce time range (try 24h instead of 7d)

### Mobile Layout Broken

**Symptom:** Dashboard looks good on desktop, broken on mobile

**Solutions:**
1. Use Sections view (default, responsive)
2. Avoid fixed-width cards or custom CSS with px units
3. Test with HA Companion app and mobile browser
4. Use Layout Card with `auto-fit` for grids:
   ```yaml
   grid-template-columns: repeat(auto-fit, minmax(150px, 1fr))
   ```
5. Enable "Dense mode" in dashboard settings for smaller screens

### Performance Issues

**Symptom:** Dashboard slow to load, lag when scrolling

**Solutions:**
1. Reduce cards per view (aim for 20-30 max)
2. Limit Mini Graph Card time ranges (24h recommended)
3. Use conditional cards to hide non-essential content
4. Check CPU usage: `htop` on homelab server
5. Consider pagination for long auto-entities lists:
   ```yaml
   type: custom:auto-entities
   card:
     type: entities
   filter:
     # ... filters
   sort:
     method: state
   card_param: entities
   show_empty: false
   # Limit results
   max: 10
   ```
6. Move historical analysis to Grafana

### Conditional Cards Not Showing

**Symptom:** Conditional card never appears despite meeting conditions

**Solutions:**
1. Verify entity_id is correct (check in Developer Tools)
2. Check condition syntax (numeric_state needs numbers, not strings)
3. Test condition in Developer Tools → Template:
   ```jinja2
   {{ states('sensor.example') | float > 50 }}
   ```
4. Check entity state: `unavailable` doesn't match any condition
5. Add multiple cards with different thresholds to debug:
   ```yaml
   # Debug card - always show
   type: markdown
   content: |
     Sensor value: {{ states('sensor.aleje_pm2_5') }}
     Condition met: {{ states('sensor.aleje_pm2_5') | float(0) > 50 }}
   ```

### Auto-Entities Empty

**Symptom:** Auto-entities card says "No entities found"

**Solutions:**
1. Verify filter matches existing entities (check domain, attributes)
2. Test in Developer Tools → States (filter manually)
3. Check `show_empty: false` setting
4. Add exclusions carefully - might be filtering too much
5. Example working filter:
   ```yaml
   filter:
     include:
       - domain: light
         state: 'on'
     exclude:
       - entity_id: '*_update'
   ```

### Theme Not Applied

**Symptom:** Dashboard shows default HA theme

**Solutions:**
1. Select theme: Profile (bottom left) → Theme dropdown
2. Verify theme installed via HACS
3. Clear browser cache
4. Restart Home Assistant
5. Check theme compatibility with HA version

## Related Documentation

### Official Home Assistant
- [Dashboard Documentation](https://www.home-assistant.io/dashboards/)
- [Sections View Guide](https://www.home-assistant.io/blog/2024/03/04/dashboard-chapter-1/)
- [Card Types Reference](https://www.home-assistant.io/dashboards/cards/)
- [Conditional Card](https://www.home-assistant.io/dashboards/conditional/)

### Custom Cards
- [Mushroom Cards](https://github.com/piitaya/lovelace-mushroom)
- [Mini Graph Card](https://github.com/kalkih/mini-graph-card)
- [Button Card](https://github.com/custom-cards/button-card)
- [Auto-Entities Card](https://github.com/thomasloven/lovelace-auto-entities)
- [History Explorer Card](https://github.com/alexarch21/history-explorer-card)
- [Layout Card](https://github.com/thomasloven/lovelace-layout-card)
- [Mini Media Player](https://github.com/kalkih/mini-media-player)
- [card-mod](https://github.com/thomasloven/lovelace-card-mod)

### Advanced Monitoring
- [Grafana Dashboards](./grafana-dashboards.md) - For long-term trends and advanced analysis
- [InfluxDB Integration](https://www.home-assistant.io/integrations/influxdb/)

### Community Resources
- [r/homeassistant Dashboard Examples](https://www.reddit.com/r/homeassistant/)
- [Home Assistant Community Forum - Dashboards](https://community.home-assistant.io/c/projects/dashboards/)
