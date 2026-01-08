# Home Analytics Baseline Metrics

**Date:** 2025-01-08
**Phase:** 1.1 - Data Audit

## Presence Sensors Inventory

### Available Sensors

| Entity ID | Friendly Name | Location | Device Type |
|-----------|---------------|----------|-------------|
| `binary_sensor.presence_kitchen` | Presence Kitchen | Kitchen | FP2 (aggregated) |
| `binary_sensor.presence_sensor_fp2_b63f_presence_sensor_2` | FP2-B63F Zone 2 | Kitchen | Aqara FP2 |
| `binary_sensor.presence_livingroom` | Presence Living room | Living Room | FP2 (aggregated) |
| `binary_sensor.presence_sensor_fp2_fac2_presence_sensor_1` | FP2-FAC2 Zone 1 | Living Room | Aqara FP2 |
| `binary_sensor.presence_sensor_fp2_fac2_presence_sensor_2` | FP2-FAC2 Zone 2 | Living Room | Aqara FP2 |
| `binary_sensor.presence_sensor_fp2_fac2_presence_sensor_3` | FP2-FAC2 Zone 3 | Living Room | Aqara FP2 |

**Total:** 6 presence sensors across 2 rooms (Kitchen, Living Room)

### Sensor Mapping

**Kitchen:**
- Main: `binary_sensor.presence_kitchen`
- Zone 2: `binary_sensor.presence_sensor_fp2_b63f_presence_sensor_2`

**Living Room:**
- Main: `binary_sensor.presence_livingroom`
- Zone 1: `binary_sensor.presence_sensor_fp2_fac2_presence_sensor_1`
- Zone 2: `binary_sensor.presence_sensor_fp2_fac2_presence_sensor_2`
- Zone 3: `binary_sensor.presence_sensor_fp2_fac2_presence_sensor_3`

### Missing Coverage

**Rooms without presence sensors:**
- Bedroom (has `climate.bedroom_thermostat` but no occupancy detection)
- Bathroom (has `climate.bathroom_thermostat` but no occupancy detection)
- Hallway (has lights but no dedicated presence sensor)

**Note:** Hallway has light automations suggesting presence detection exists, but no `presence_hallway` entity found. May use FP2 zones or other method.

## Data Quality Check

### Test Queries

**Query 1: Check data continuity (7-day scan)**
```flux
from(bucket: "home-assistant")
  |> range(start: -7d)
  |> filter(fn: (r) => r["domain"] == "binary_sensor")
  |> filter(fn: (r) => r["entity_id"] == "binary_sensor.presence_kitchen")
  |> filter(fn: (r) => r["_field"] == "state")
  |> elapsed()
  |> filter(fn: (r) => r.elapsed > 600000000000)  // >10min gaps
  |> count()
```

**Query 2: Validate state transitions**
```flux
from(bucket: "home-assistant")
  |> range(start: -24h)
  |> filter(fn: (r) => r["entity_id"] =~ /presence/)
  |> filter(fn: (r) => r["_field"] == "state")
  |> aggregateWindow(every: 1h, fn: count)
```

**Query 3: Entity data availability**
```flux
from(bucket: "home-assistant")
  |> range(start: -30d)
  |> filter(fn: (r) => r["entity_id"] =~ /presence/)
  |> group(columns: ["entity_id"])
  |> count()
  |> yield(name: "total_events_per_sensor")
```

### Findings (To be populated after running queries)

- [ ] Data continuity check completed
- [ ] State transition validation completed
- [ ] Entity availability verified
- [ ] Gap analysis documented
- [ ] Sensor reliability scored

## Light Inventory

### Tracked Lights (from InfluxDB)

**Hallway:**
- `light.hallway` (group)
- `light.hue_essential_spot_1`, `light.hue_essential_spot_1_2`
- `light.hue_essential_spot_2`, `light.hue_essential_spot_2_2`
- `light.hue_essential_spot_3`, `light.hue_essential_spot_3_2`
- `light.hue_essential_spot_4`, `light.hue_essential_spot_4_2`
- `light.hue_essential_spot_5`

**Kitchen:**
- `light.kitchen` (group)
- `light.k_m_1`, `light.k_m_2`, `light.k_m_3`, `light.k_m_4`

**Bathroom:**
- `light.bathroom`

**Other:**
- `light.home_assistant_voice_0a5def_led_ring` (voice assistant indicator)

### Light-to-Room Mapping

| Room | Light Entity | Presence Entity | Waste Detection Possible |
|------|--------------|-----------------|--------------------------|
| Kitchen | `light.kitchen` | `binary_sensor.presence_kitchen` | ✅ Yes |
| Living Room | (TBD) | `binary_sensor.presence_livingroom` | ⚠️ Need to identify lights |
| Hallway | `light.hallway` | ⚠️ No direct sensor | ⚠️ Partial (via automation triggers) |
| Bathroom | `light.bathroom` | ❌ No sensor | ❌ No |

## Climate Inventory

### Thermostats

| Entity ID | Location | Current Temp Available | Schedule Exists |
|-----------|----------|------------------------|-----------------|
| `climate.livingroom_thermostat` | Living Room | ✅ Yes | ✅ Yes (6am/9am/10pm) |
| `climate.bedroom_thermostat` | Bedroom | ✅ Yes | ✅ Yes (6am/9am/10pm) |
| `climate.bathroom_thermostat` | Bathroom | ✅ Yes | ✅ Yes (6am/9am/10pm) |

**Schedule details:**
- 6am: Heat to target temp (wake time)
- 9am: Reduce temp (assumed away)
- 10pm: Night mode (sleep time)

**Efficiency opportunity:** Fixed schedule vs actual occupancy patterns

## Air Quality Inventory

### Sensors

**Outdoor:**
- `sensor.airly_home_pm2_5` (Airly integration, includes 24h avg attribute)

**Indoor:**
- `sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6` (Mi Air Purifier 3H)

**Derived:**
- `sensor.pm25_24h_average` (template sensor)
- `sensor.pm25_outdoor_indoor_diff_living_room` (template sensor)
- `binary_sensor.safe_to_ventilate_living_room` (template sensor)

### Air Purifier

**Entity:** Mi Air Purifier 3H
- PM2.5 sensor integrated
- Mode control available (auto/night/favorite)
- Filter life tracking

## Baseline Metrics (To Be Calculated)

### Occupancy Patterns

**Kitchen:**
- [ ] Average daily occupancy hours
- [ ] Peak usage times (most occupied hours)
- [ ] Typical visit duration
- [ ] Weekday vs weekend differences

**Living Room:**
- [ ] Average daily occupancy hours (total across zones)
- [ ] Peak usage times
- [ ] Evening activity patterns
- [ ] Weekday vs weekend differences

### Lighting Usage

**Kitchen:**
- [ ] Average daily light-on hours
- [ ] Lights on with room vacant (waste hours)
- [ ] Automation effectiveness (% time lights match occupancy)

### Climate Efficiency

**All Thermostats:**
- [ ] Average temperature when occupied vs vacant
- [ ] Schedule alignment (heating during occupied hours %)
- [ ] Temperature setpoint performance (actual vs target)

### Air Quality Performance

**Purifier Effectiveness:**
- [ ] Outdoor → indoor PM2.5 reduction rate
- [ ] Average indoor PM2.5 (last 30 days)
- [ ] Ventilation window frequency (outdoor <15 µg/m³)

## Next Steps

1. **Complete data audit queries** (run on homelab InfluxDB)
2. **Document gaps and issues** (sensor downtime, data quality problems)
3. **Build first dashboard** (room utilization with available sensors)
4. **Calculate baseline metrics** (30-day historical averages)
5. **Update this document** with actual numbers

---

**Status:** In Progress (Phase 1.1)
**Last Updated:** 2025-01-08
