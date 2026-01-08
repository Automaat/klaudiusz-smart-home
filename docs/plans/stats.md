# Home Analytics Implementation Plan

## Overview

Build comprehensive smart home analytics using InfluxDB 2 and Grafana to track:
- Room utilization and occupancy patterns
- Lighting efficiency and waste detection
- Climate optimization opportunities
- Air quality effectiveness
- Behavioral insights for automation tuning

**Timeline:** 6-8 weeks
**Data sources:** Aqara FP2 presence sensors, lights, thermostats, air quality sensors
**Tech stack:** InfluxDB 2.7.12 (Flux queries), Grafana dashboards, Home Assistant automations

---

## Phase 1: Foundation (Week 1-2)

**Goal:** Establish baseline metrics and data quality validation

### Tasks

#### 1.1 Data Audit (2-3 hours)
- [ ] Query InfluxDB for all presence sensor entities
- [ ] Verify continuous data collection (check gaps >10min)
- [ ] Document entity mapping: sensors → rooms
- [ ] Test query performance with 30-day ranges

**Queries to validate:**
```flux
// List all presence sensors
from(bucket: "home-assistant")
  |> range(start: -24h)
  |> filter(fn: (r) => r["domain"] == "binary_sensor")
  |> filter(fn: (r) => r["entity_id"] =~ /presence/)
  |> distinct(column: "entity_id")

// Check data continuity (gaps)
from(bucket: "home-assistant")
  |> range(start: -7d)
  |> filter(fn: (r) => r["entity_id"] == "binary_sensor.presence_livingroom")
  |> filter(fn: (r) => r["_field"] == "state")
  |> elapsed()
  |> filter(fn: (r) => r.elapsed > 600000000000)  // >10min gaps
```

#### 1.2 Build Occupancy Duration Queries (3-4 hours)
- [ ] Daily occupancy hours per room
- [ ] Hourly occupancy rate (for heatmaps)
- [ ] Weekly aggregates for trend analysis
- [ ] Handle timezone conversion (UTC → Europe/Warsaw)

**Core query pattern:**
```flux
// Daily occupancy hours per room
from(bucket: "home-assistant")
  |> range(start: -30d)
  |> filter(fn: (r) => r["domain"] == "binary_sensor")
  |> filter(fn: (r) => r["entity_id"] =~ /presence/)
  |> filter(fn: (r) => r["_field"] == "state")
  |> stateDuration(fn: (r) => r._value == "on", unit: 1h)
  |> aggregateWindow(every: 1d, fn: sum, createEmpty: false)
  |> group(columns: ["entity_id"])
  |> yield(name: "daily_occupancy_hours")

// Hourly occupancy rate (% time occupied per hour)
from(bucket: "home-assistant")
  |> range(start: -7d)
  |> filter(fn: (r) => r["entity_id"] =~ /presence/)
  |> filter(fn: (r) => r["_field"] == "state")
  |> map(fn: (r) => ({r with occupied: if r._value == "on" then 1.0 else 0.0}))
  |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
  |> group(columns: ["entity_id"])
```

#### 1.3 Create Basic Room Utilization Dashboard (4-5 hours)
- [ ] **Panel 1:** Daily occupancy bar chart (stacked by room)
- [ ] **Panel 2:** Room ranking (total hours past 30 days)
- [ ] **Panel 3:** Occupancy heatmap (24h × 7 days)
- [ ] **Panel 4:** Current status (stat panels: occupied/vacant)
- [ ] Add dashboard to `hosts/homelab/grafana/dashboards/smart-home/`

**Dashboard structure:**
```json
{
  "title": "Room Utilization Analytics",
  "panels": [
    {
      "title": "Daily Occupancy Hours",
      "type": "timeseries",
      "targets": [/* daily_occupancy_hours query */]
    },
    {
      "title": "Room Ranking (30 Days)",
      "type": "bargauge",
      "targets": [/* total occupancy by room */]
    },
    {
      "title": "Occupancy Heatmap",
      "type": "heatmap",
      "targets": [/* hourly occupancy rate */]
    }
  ]
}
```

#### 1.4 Establish Baseline Metrics (1 hour)
- [ ] Document current state:
  - Most/least used rooms
  - Peak activity hours
  - Weekday vs weekend differences
- [ ] Save findings to `docs/baseline-metrics.md`

**Expected outputs:**
- Baseline dashboard operational
- 30-day historical occupancy data visualized
- Data quality report (gaps, sensor reliability)
- Understanding of current usage patterns

---

## Phase 2: Efficiency Tracking (Week 3-4)

**Goal:** Identify waste and optimization opportunities

### Tasks

#### 2.1 Light Waste Detection (5-6 hours)
- [ ] Build time-aligned join query (light state + presence state)
- [ ] Calculate waste duration (light on + room vacant)
- [ ] Daily/weekly waste aggregates per room
- [ ] Test query performance (optimize with sampling if needed)

**Challenge:** Time-series alignment for join
```flux
// Approach 1: Window-based join
light_states = from(bucket: "home-assistant")
  |> range(start: -7d)
  |> filter(fn: (r) => r["entity_id"] == "light.kitchen")
  |> filter(fn: (r) => r["_field"] == "state")
  |> aggregateWindow(every: 1m, fn: last, createEmpty: false)
  |> map(fn: (r) => ({r with light_on: r._value == "on"}))

presence_states = from(bucket: "home-assistant")
  |> range(start: -7d)
  |> filter(fn: (r) => r["entity_id"] == "binary_sensor.presence_kitchen")
  |> filter(fn: (r) => r["_field"] == "state")
  |> aggregateWindow(every: 1m, fn: last, createEmpty: false)
  |> map(fn: (r) => ({r with occupied: r._value == "on"}))

// Join on _time (aligned to 1min buckets)
join(tables: {light: light_states, presence: presence_states}, on: ["_time"])
  |> map(fn: (r) => ({
      _time: r._time,
      wasted: r.light_on and not r.occupied,
      entity_id: "kitchen"
  }))
  |> filter(fn: (r) => r.wasted)
  |> stateDuration(fn: (r) => r.wasted, unit: 1h)
  |> aggregateWindow(every: 1d, fn: sum, createEmpty: false)
```

#### 2.2 Create Lighting Efficiency Dashboard (3-4 hours)
- [ ] **Panel 1:** Daily waste stat (hours, with threshold alert)
- [ ] **Panel 2:** Waste by room (pie chart or bar gauge)
- [ ] **Panel 3:** Lights on timeline (state visualization)
- [ ] **Panel 4:** Automation effectiveness % per room
- [ ] **Panel 5:** Weekly trend (improvement tracking)

**Alert configuration:**
```json
{
  "alert": {
    "name": "High lighting waste",
    "conditions": [
      {
        "evaluator": {
          "params": [2],
          "type": "gt"
        },
        "query": {
          "model": "/* daily waste query */",
          "params": ["now-1d", "now"]
        }
      }
    ],
    "message": "Lighting waste exceeded 2h today"
  }
}
```

#### 2.3 Climate Efficiency Analysis (4-5 hours)
- [ ] Temperature when occupied vs vacant (per room)
- [ ] Heating schedule alignment (scheduled hours vs actual occupancy)
- [ ] Setpoint performance (actual vs target delta)
- [ ] Occupancy-weighted comfort score

**Key queries:**
```flux
// Temperature by occupancy state
occupancy = from(bucket: "home-assistant")
  |> range(start: -30d)
  |> filter(fn: (r) => r["entity_id"] == "binary_sensor.presence_bedroom")
  |> aggregateWindow(every: 5m, fn: last)

temperature = from(bucket: "home-assistant")
  |> range(start: -30d)
  |> filter(fn: (r) => r["entity_id"] == "climate.bedroom_thermostat")
  |> filter(fn: (r) => r["_field"] == "current_temperature")
  |> aggregateWindow(every: 5m, fn: last)

join(tables: {occ: occupancy, temp: temperature}, on: ["_time"])
  |> group(columns: ["state"])  // Group by occupied/vacant
  |> mean()

// Heating during vacant hours (waste detection)
vacant_heating = join(tables: {occ: occupancy, temp: temperature}, on: ["_time"])
  |> filter(fn: (r) => r.state == "off")  // Room vacant
  |> filter(fn: (r) => r._value > 20.0)   // Heating active
  |> stateDuration(fn: (r) => r._value > 20.0, unit: 1h)
  |> aggregateWindow(every: 1d, fn: sum)
```

#### 2.4 Add Climate Efficiency Dashboard (3-4 hours)
- [ ] **Panel 1:** Efficiency score gauge (% heating during occupancy)
- [ ] **Panel 2:** Temp by occupancy comparison (bar chart)
- [ ] **Panel 3:** Schedule vs actual occupancy (Gantt-style)
- [ ] **Panel 4:** Vacant heating hours (waste metric)
- [ ] **Panel 5:** Room-to-room temperature delta (heatmap)

#### 2.5 Implement Alerting (2-3 hours)
- [ ] Light waste >2h/day → Telegram notification
- [ ] Heating vacant room >1h → Alert
- [ ] Weekly efficiency report (summary stats)
- [ ] Test notification delivery and deduplication

**Notification automation example:**
```yaml
automation:
  - id: lighting_waste_alert
    alias: "Lighting Waste Alert"
    trigger:
      - platform: time
        at: "22:00:00"  # Daily summary
    condition:
      - condition: template
        value_template: >
          {{ states('sensor.daily_light_waste_hours') | float(0) > 2 }}
    action:
      - service: notify.telegram
        data:
          message: >
            ⚠️ High lighting waste today: {{ states('sensor.daily_light_waste_hours') }}h
            Kitchen: {{ state_attr('sensor.light_waste_by_room', 'kitchen') }}h
            Living room: {{ state_attr('sensor.light_waste_by_room', 'livingroom') }}h
```

**Expected outputs:**
- Light waste quantified per room
- Climate efficiency score established
- Active alerting for high-waste patterns
- Actionable insights for automation tuning

---

## Phase 3: Behavioral Analysis (Week 5-6)

**Goal:** Understand routines and patterns for predictive automation

### Tasks

#### 3.1 Routine Detection Queries (4-5 hours)
- [ ] Morning sequence: bedroom → bathroom → kitchen (timing + duration)
- [ ] Evening wind-down: activity decline pattern
- [ ] Room transition flow (Sankey diagram data)
- [ ] Weekday vs weekend comparison

**Morning routine query:**
```flux
// Detect first occupancy time per room per day
bedroom_wake = from(bucket: "home-assistant")
  |> range(start: -30d)
  |> filter(fn: (r) => r["entity_id"] == "binary_sensor.presence_bedroom")
  |> filter(fn: (r) => r["_value"] == "on")
  |> aggregateWindow(every: 1d, fn: first, createEmpty: false)
  |> map(fn: (r) => ({
      r with
      hour: date.hour(t: r._time),
      minute: date.minute(t: r._time),
      room: "bedroom"
  }))

bathroom_entry = // Similar query for bathroom

kitchen_entry = // Similar query for kitchen

// Union and sort to see sequence
union(tables: [bedroom_wake, bathroom_entry, kitchen_entry])
  |> sort(columns: ["_time"])
  |> group(columns: ["_time"])  // Group by day
```

#### 3.2 Build Behavioral Insights Dashboard (5-6 hours)
- [ ] **Panel 1:** Routine timeline (multi-series line: wake/sleep times)
- [ ] **Panel 2:** Weekday vs weekend comparison (grouped bars)
- [ ] **Panel 3:** Room transition flow (Sankey or state timeline)
- [ ] **Panel 4:** Peak activity hours (area chart with overlay)
- [ ] **Panel 5:** Anomaly detector (alert list: unusual patterns)

#### 3.3 Seasonal Trend Analysis (3-4 hours)
- [ ] Month-over-month occupancy pattern changes
- [ ] Correlation with daylight hours (sun integration data)
- [ ] Temperature impact on room usage
- [ ] Long-term trend visualization (12-month view)

**Seasonal comparison:**
```flux
// Compare occupancy patterns across months
from(bucket: "home-assistant")
  |> range(start: -12mo)
  |> filter(fn: (r) => r["entity_id"] =~ /presence/)
  |> stateDuration(fn: (r) => r._value == "on", unit: 1h)
  |> aggregateWindow(every: 1mo, fn: sum)
  |> group(columns: ["entity_id", "_time"])
  |> pivot(rowKey: ["_time"], columnKey: ["entity_id"], valueColumn: "_value")
```

#### 3.4 Anomaly Detection Logic (4-5 hours)
- [ ] Define "normal" ranges (baseline from Phase 1)
- [ ] Detect deviations: unexpected absence, odd-hour activity
- [ ] Historical anomaly review (past 30 days)
- [ ] Alert configuration for real-time detection

**Anomaly types:**
- **Unexpected absence:** Room typically occupied at time T but vacant
- **Unusual activity:** Room occupied during typical sleep hours
- **Pattern break:** Routine timing shift >1h

```flux
// Expected vs actual occupancy
expected_pattern = // Historical average for day-of-week + hour
actual_occupancy = // Current day's occupancy

join(tables: {expected: expected_pattern, actual: actual_occupancy}, on: ["hour"])
  |> map(fn: (r) => ({
      r with
      deviation: r.actual - r.expected,
      anomaly: math.abs(x: r.deviation) > 0.3  // 30% deviation threshold
  }))
  |> filter(fn: (r) => r.anomaly)
```

**Expected outputs:**
- Morning/evening routine timing quantified
- Weekday vs weekend behavioral differences identified
- Seasonal pattern trends visible
- Anomaly detection operational

---

## Phase 4: Air Quality Intelligence (Week 6-7)

**Goal:** Optimize air quality management and ventilation

### Tasks

#### 4.1 Purifier Effectiveness Analysis (3-4 hours)
- [ ] Outdoor → indoor PM2.5 reduction rate
- [ ] Effectiveness by purifier mode (auto/night/favorite)
- [ ] Filter performance degradation over time
- [ ] Optimal mode selection logic

**Effectiveness calculation:**
```flux
outdoor = from(bucket: "home-assistant")
  |> range(start: -30d)
  |> filter(fn: (r) => r["entity_id"] == "sensor.airly_home_pm2_5")
  |> aggregateWindow(every: 1h, fn: mean)

indoor = from(bucket: "home-assistant")
  |> range(start: -30d)
  |> filter(fn: (r) => r["entity_id"] =~ /zhimi.*pm2_5/)
  |> aggregateWindow(every: 1h, fn: mean)

join(tables: {outdoor: outdoor, indoor: indoor}, on: ["_time"])
  |> map(fn: (r) => ({
      r with
      reduction: r.outdoor - r.indoor,
      reduction_pct: (r.outdoor - r.indoor) / r.outdoor * 100.0
  }))
  |> mean(column: "reduction_pct")
```

#### 4.2 Ventilation Window Detection (2-3 hours)
- [ ] Safe ventilation periods (outdoor PM2.5 <15 µg/m³)
- [ ] Duration and frequency analysis
- [ ] Best times for ventilation (historical patterns)
- [ ] Correlation with weather data (optional)

#### 4.3 Build Air Quality Dashboard (4-5 hours)
- [ ] **Panel 1:** Purifier impact (dual-axis: outdoor + indoor PM2.5)
- [ ] **Panel 2:** Ventilation windows timeline (green/red states)
- [ ] **Panel 3:** Filter performance tracking (scatter plot)
- [ ] **Panel 4:** Sleep environment quality (table: bedroom metrics)
- [ ] **Panel 5:** Health score gauge (WHO guideline compliance)

#### 4.4 Create Ventilation Optimizer Automation (3-4 hours)
- [ ] Notification: "Safe to ventilate now" (good outdoor air + indoor worse)
- [ ] Predicted ventilation windows (based on historical patterns)
- [ ] Bedroom-specific alerts (sleep time optimization)
- [ ] Override logic for manual control

**Automation example:**
```yaml
automation:
  - id: ventilation_opportunity_alert
    alias: "Ventilation Opportunity Alert"
    trigger:
      - platform: state
        entity_id: binary_sensor.safe_to_ventilate_living_room
        to: "on"
        for: "00:05:00"  # Stable for 5min
    condition:
      - condition: numeric_state
        entity_id: sensor.pm25_outdoor_indoor_diff_living_room
        below: -5  # Indoor worse than outdoor by 5+ µg/m³
      - condition: state
        entity_id: binary_sensor.presence_livingroom
        state: "on"  # Someone home to act on alert
    action:
      - service: notify.telegram
        data:
          message: >
            🌬️ Good time to ventilate!
            Outdoor: {{ states('sensor.airly_home_pm2_5') }} µg/m³
            Indoor: {{ states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') }} µg/m³
```

**Expected outputs:**
- Purifier effectiveness quantified
- Optimal ventilation times identified
- Proactive ventilation suggestions operational
- Filter replacement timing optimized

---

## Phase 5: Automation Optimization (Week 7-8)

**Goal:** Apply analytics insights to improve automations

### Tasks

#### 5.1 Adaptive Lighting Implementation (4-5 hours)
- [ ] Adjust timeouts based on room usage patterns
  - Kitchen: 5min (high turnover)
  - Bedroom: 30min (longer stays)
  - Hallway: 2min (transit only)
- [ ] Predictive pre-warming (lights on 2min before typical entry)
- [ ] Weekend schedule adjustments (based on Phase 3 findings)

**Dynamic timeout example:**
```yaml
automation:
  - id: adaptive_kitchen_lights
    alias: "Adaptive Kitchen Lights"
    trigger:
      - platform: state
        entity_id: binary_sensor.presence_kitchen
        to: "on"
    action:
      - service: light.turn_on
        target:
          entity_id: light.kitchen

  - id: adaptive_kitchen_lights_off
    alias: "Adaptive Kitchen Lights Off"
    trigger:
      - platform: state
        entity_id: binary_sensor.presence_kitchen
        to: "off"
        for:
          minutes: >
            {# Use historical avg stay duration + buffer #}
            {{ state_attr('sensor.kitchen_avg_stay_duration', 'minutes') | float(5) }}
    action:
      - service: light.turn_off
        target:
          entity_id: light.kitchen
```

#### 5.2 Predictive Climate Control (5-6 hours)
- [ ] Learn wake time from bathroom occupancy patterns
- [ ] Pre-heat bedroom 30min before typical wake
- [ ] Weekend schedule auto-adjustment
- [ ] Reduce temp if room vacant >1h (reversible)

**Predictive heating:**
```yaml
# Template sensor: predicted wake time
template:
  - sensor:
      - name: "Predicted Wake Time"
        state: >
          {# Query InfluxDB for avg first bathroom occupancy #}
          {# Use past 7 days, weekday-specific #}
          {{ state_attr('sensor.bathroom_wake_time_avg', 'time') }}

automation:
  - id: predictive_bedroom_heating
    alias: "Predictive Bedroom Heating"
    trigger:
      - platform: template
        value_template: >
          {{ now().strftime('%H:%M') ==
             (as_timestamp(states('sensor.predicted_wake_time')) - 1800) | timestamp_custom('%H:%M') }}
    action:
      - service: climate.set_temperature
        target:
          entity_id: climate.bedroom_thermostat
        data:
          temperature: 21
```

#### 5.3 Smart Air Purifier Scheduling (3-4 hours)
- [ ] Night mode during typical sleep hours (from Phase 3 data)
- [ ] Anticipatory mode boost (pre-spike based on patterns)
- [ ] Auto-antibacterial runs during absence windows
- [ ] Mode override based on real-time indoor PM2.5

#### 5.4 Measure Improvement Impact (3-4 hours)
- [ ] A/B test: old vs new automation logic
- [ ] Metrics to track:
  - Light waste reduction (hours saved)
  - Heating efficiency improvement (% occupied heating)
  - Comfort score (temp deviation from target)
  - Air quality improvement (avg indoor PM2.5)
- [ ] Document findings in `docs/optimization-results.md`

**Comparison dashboard:**
```json
{
  "panels": [
    {
      "title": "Light Waste: Before vs After",
      "targets": [
        {
          "query": "/* Waste before optimization (baseline) */",
          "legendFormat": "Before"
        },
        {
          "query": "/* Waste after optimization */",
          "legendFormat": "After"
        }
      ]
    }
  ]
}
```

#### 5.5 Energy Savings Estimation (2-3 hours)
- [ ] Calculate kWh saved (lighting + heating)
- [ ] Cost savings estimate (kWh × electricity rate)
- [ ] ROI on smart home investment
- [ ] Environmental impact (CO2 reduction)

**Energy calculation:**
```flux
// Lighting energy savings
light_waste_before = // Baseline waste hours
light_waste_after = // Post-optimization waste hours

savings_hours = light_waste_before - light_waste_after
savings_kwh = savings_hours * 0.02  // 20W average bulb
savings_pln = savings_kwh * 0.80  // ~0.80 PLN/kWh (Poland 2024)
```

**Expected outputs:**
- Automations tuned to actual behavior patterns
- Measurable efficiency improvements
- Quantified energy/cost savings
- Validated ROI on analytics investment

---

## Phase 6: Continuous Improvement (Ongoing)

**Goal:** Maintain and evolve analytics over time

### Tasks

#### 6.1 Data Quality Monitoring (Weekly)
- [ ] Check for sensor gaps (>10min outages)
- [ ] Validate query performance (execution time)
- [ ] Review alert false positive rate
- [ ] Update entity mappings (new devices)

#### 6.2 Dashboard Maintenance (Monthly)
- [ ] Archive old panels (unused views)
- [ ] Update time ranges (12-month trends → 18-month)
- [ ] Refresh baselines (seasonal adjustments)
- [ ] Add new metrics as needed

#### 6.3 Automation Tuning (Quarterly)
- [ ] Review efficiency scores (targets met?)
- [ ] Adjust thresholds based on seasonal changes
- [ ] Incorporate new sensors/devices
- [ ] Test alternative optimization strategies

#### 6.4 Privacy Review (Semi-annual)
- [ ] Audit data retention policies (raw vs aggregated)
- [ ] Purge old granular data (>7 days raw → daily summaries)
- [ ] Verify access controls (Grafana users)
- [ ] Update documentation (what data is kept, why)

---

## Technical Implementation Notes

### InfluxDB Performance Optimization

**Pre-aggregation Strategy:**
```flux
// Use continuous queries for frequently-accessed aggregates
// Example: Daily occupancy (runs every night)
option task = {name: "daily_occupancy_rollup", every: 1d}

from(bucket: "home-assistant")
  |> range(start: -1d)
  |> filter(fn: (r) => r["entity_id"] =~ /presence/)
  |> stateDuration(fn: (r) => r._value == "on", unit: 1h)
  |> aggregateWindow(every: 1d, fn: sum)
  |> to(bucket: "home-assistant-daily", org: "homeassistant")
```

**Query Optimization Tips:**
- Use `createEmpty: false` in aggregateWindow (avoid null points)
- Filter early (domain/entity_id before calculations)
- Sample large datasets (every: 5m for 30-day ranges)
- Use tasks for expensive recurring queries

### Grafana Best Practices

**Variable Templates:**
```json
{
  "templating": {
    "list": [
      {
        "name": "room",
        "type": "query",
        "query": "from(bucket: \"home-assistant\") |> range(start: -1h) |> filter(fn: (r) => r[\"entity_id\"] =~ /presence/) |> distinct(column: \"entity_id\")",
        "current": {
          "text": "All",
          "value": "$__all"
        },
        "multi": true
      }
    ]
  }
}
```

**Drill-down Links:**
- Room utilization → detailed room dashboard
- Waste alert → specific light timeline
- Anomaly → historical pattern comparison

### Home Assistant Sensor Integration

**Template sensors for Grafana:**
```yaml
# hosts/homelab/home-assistant/sensors.nix
template:
  - sensor:
      - name: "Daily Light Waste Hours"
        unique_id: "daily_light_waste_hours"
        state: >
          {# Query InfluxDB via REST API #}
          {{ state_attr('sensor.influxdb_query', 'light_waste_today') | float(0) }}
        unit_of_measurement: "h"

      - name: "Kitchen Average Stay Duration"
        unique_id: "kitchen_avg_stay_duration"
        state: >
          {# Historical average from InfluxDB #}
          {{ state_attr('sensor.influxdb_query', 'kitchen_stay_avg') | float(5) }}
        unit_of_measurement: "min"
```

### Privacy & Data Retention

**Retention policy:**
- Raw data: 7 days (second-level precision)
- Hourly aggregates: 90 days
- Daily summaries: 2 years
- Monthly rollups: Indefinite

**InfluxDB retention config:**
```nix
# hosts/homelab/influxdb.nix (future enhancement)
services.influxdb2.settings = {
  retention-autocreate = true;
  retention-check-interval = "30m";
};

# Retention policies
# retention.create(bucket: "home-assistant", every: 7d, shardDuration: 1d)
```

---

## Success Metrics

### Phase 1-2 (Foundation + Efficiency)
- [ ] Occupancy tracked for all rooms (>95% uptime)
- [ ] Light waste quantified (baseline established)
- [ ] Climate efficiency score calculated
- [ ] 3+ dashboards operational

### Phase 3-4 (Behavioral + Air Quality)
- [ ] Morning/evening routines detected
- [ ] Weekday vs weekend patterns identified
- [ ] Purifier effectiveness measured
- [ ] Ventilation optimizer operational

### Phase 5-6 (Optimization + Maintenance)
- [ ] Light waste reduced 50%+ from baseline
- [ ] Heating efficiency improved 20%+
- [ ] Automation satisfaction score >8/10 (subjective)
- [ ] Energy savings >100 PLN/year

---

## Resources & References

### Documentation
- [InfluxDB Flux Language](https://docs.influxdata.com/flux/v0/)
- [stateDuration() function](https://docs.influxdata.com/flux/v0/stdlib/universe/stateduration/)
- [Grafana Dashboard JSON Schema](https://grafana.com/docs/grafana/latest/dashboards/json-model/)
- [Home Assistant InfluxDB Integration](https://www.home-assistant.io/integrations/influxdb/)

### Community Examples
- [Home Assistant + Grafana Guide](https://vdbrink.github.io/homeassistant/homeassistant_dashboard_grafana.html)
- [Smart Home Analytics Patterns](https://thesmarthomejourney.com/2021/05/02/grafana-influxdb-home-assistant/)
- [Occupancy Detection Best Practices](https://github.com/Hankanman/Area-Occupancy-Detection)

### Tools
- [Flux Query Tester](https://docs.influxdata.com/influxdb/v2/tools/flux-vscode/)
- [Grafana Dashboard Exporter](https://grafana.com/docs/grafana/latest/dashboards/share-dashboards-panels/)
- [InfluxDB Data Explorer](http://homelab:8086) (local instance)

---

## Next Steps

**Immediate actions:**
1. Review plan and adjust timeline based on availability
2. Start Phase 1.1: Data audit (validate sensor data quality)
3. Set up project tracking (optional: GitHub project or similar)

**Questions to answer:**
- Which rooms are priority for analytics? (Focus on high-traffic areas first)
- What's the comfort/efficiency trade-off? (How much automation vs manual control?)
- Privacy preferences? (Retention policies, data access)

**Potential blockers:**
- Sensor reliability issues (FP2 firmware, connectivity)
- Query performance with large datasets (may need sampling)
- Dashboard complexity (balance detail vs usability)

---

**Plan created:** 2025-01-08
**Last updated:** 2025-01-08
**Status:** Ready to start
