# GIOŚ Air Quality Integration Setup

## Why Manual Configuration

GIOŚ integration uses config flow (UI-based setup) - cannot be configured via YAML/NixOS.

## Prerequisites

- NixOS deployment with `gios` component enabled (hosts/homelab/home-assistant/default.nix:49)
- Internet connection (cloud polling service)

## Setup Steps

### 1. Find Measuring Station

1. Go to [GIOŚ Air Quality Map](http://powietrze.gios.gov.pl/pjp/current)
2. Find closest station to your location (Kraków: 50.083°N, 19.891°E)
3. Click station marker → "More info"
4. Note station ID from URL (e.g., `http://powietrze.gios.gov.pl/pjp/current/station_details/chart/400` → ID: **400**)

**Example stations near Kraków:**

- Kraków, Aleja Krasińskiego (ID: 400)
- Kraków, ul. Bujaka (ID: 401)
- Kraków, ul. Bulwarowa (ID: 402)

### 2. Add Integration via UI

**IMPORTANT:** Must be done AFTER deploying NixOS config (`gios` component enabled).

1. Go to Settings → Devices & Services
2. Click "+ Add Integration"
3. Search for "GIOŚ"
4. Select "GIOŚ" from list
5. Select measuring station from dropdown (or search by name/ID)
6. Click "Submit"

**Alternative:** Use My button in [official docs](https://www.home-assistant.io/integrations/gios/)

## Created Entities

Integration creates sensors based on what your station measures. Common entities:

### Air Quality Index (AQI)

- `sensor.{station}_aqi` - Overall air quality index (scale: very good → very bad)

### Particulate Matter

- `sensor.{station}_pm25` - PM2.5 (µg/m³)
- `sensor.{station}_pm10` - PM10 (µg/m³)

### Gases (if measured by station)

- `sensor.{station}_so2` - Sulfur dioxide (µg/m³)
- `sensor.{station}_no2` - Nitrogen dioxide (µg/m³)
- `sensor.{station}_o3` - Ozone (µg/m³)
- `sensor.{station}_co` - Carbon monoxide (µg/m³)
- `sensor.{station}_c6h6` - Benzene (µg/m³)

### Index Sensors

Each pollutant has corresponding index sensor (very good → very bad):

- `sensor.{station}_pm25_index`
- `sensor.{station}_pm10_index`
- etc.

**Note:** `{station}` replaced with station name (e.g., `krakow_aleja_krasinskiego`)

## Verification

1. Check integration status:
   - Settings → Devices & Services
   - Look for "GIOŚ" with green status
   - Device name: selected station name

2. Check created sensors:
   - Settings → Devices & Services → GIOŚ → {station}
   - Verify sensors populated with values (update interval: ~1 hour)
   - Developer Tools → States → filter by station name

3. Test in automation/dashboard:

   ```nix
   # Example: check PM2.5 level
   condition = [{
     condition = "numeric_state";
     entity_id = "sensor.krakow_aleja_krasinskiego_pm25";
     above = 50; # WHO guideline
   }];
   ```

## Troubleshooting

**Integration won't add:**

- Verify `gios` in extraComponents (default.nix:49)
- Restart HA if just enabled: `sudo systemctl restart home-assistant`
- Check internet connectivity (cloud service)

**Sensors show "unavailable":**

- Wait ~1 hour for first data fetch
- Check station operational: visit [GIOŚ map](http://powietrze.gios.gov.pl/pjp/current)
- Check HA logs: `journalctl -u home-assistant | grep -i gios`

**Fewer sensors than expected:**

- Not all stations measure all parameters
- Check station details on GIOŚ website for available measurements
- Consider selecting different station with more sensors

**No data updates:**

- GIOŚ updates hourly (not real-time)
- Check station status on GIOŚ website
- Integration uses cloud polling (requires internet)

## Usage in Automations

### Example: High PM2.5 Alert

```nix
{
  id = "gios_high_pm25_alert";
  alias = "GIOŚ - High PM2.5 Alert";
  trigger = [{
    platform = "numeric_state";
    entity_id = "sensor.krakow_aleja_krasinskiego_pm25";
    above = 50; # WHO 24h guideline
    "for" = {
      minutes = 30; # Sustained high level
    };
  }];
  action = [{
    action = "notify.send_message";
    target.entity_id = "notify.telegram";
    data.message = "⚠️ Wysoki poziom PM2.5: {{ states('sensor.krakow_aleja_krasinskiego_pm25') }} µg/m³";
  }];
}
```

### Example: Voice Command (Polish)

Add to `custom_sentences/pl/air_quality.yaml`:

```yaml
language: "pl"
intents:
  AirQualityIntent:
    data:
      - sentences:
          - "(jaka|jak) jest jakość powietrza"
          - "sprawdź jakość powietrza"
```

Handler in `intents.nix`:

```nix
AirQualityIntent = {
  speech.text = "Jakość powietrza: {{ states('sensor.krakow_aleja_krasinskiego_aqi') }}. PM2.5 wynosi {{ states('sensor.krakow_aleja_krasinskiego_pm25') }} mikrogramów na metr sześcienny.";
};
```

## Related Documentation

- [GIOŚ Integration](https://www.home-assistant.io/integrations/gios/)
- [GIOŚ Official Website](https://powietrze.gios.gov.pl/pjp/home?lang=en)
- [Air Quality Category Docs](https://www.home-assistant.io/integrations/air_quality/)
- [WHO Air Quality Guidelines](https://www.who.int/news-room/fact-sheets/detail/ambient-(outdoor)-air-quality-and-health)
