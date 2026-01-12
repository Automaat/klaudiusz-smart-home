# Airly Air Quality Integration Setup

## Why Manual Configuration

Airly integration uses config flow (UI-based setup) - cannot be configured via YAML/NixOS.

## Prerequisites

- NixOS deployment with `airly` component enabled (hosts/homelab/home-assistant/default.nix:220)
- Airly API key from [developer.airly.org](https://developer.airly.org/)
- Internet connection (cloud polling service)

## Obtaining API Key

### 1. Register Developer Account

1. Go to [Airly Developer Portal](https://developer.airly.org/)
2. Click "Sign up" or "Login"
3. Create account with email verification
4. Accept Terms of Service

### 2. Generate API Key

1. After login, navigate to API Keys section
2. Click "Generate new API key"
3. Copy API key (long alphanumeric string)
4. Store securely - key provides 1000 requests/day (free tier)

**Rate Limits:**

- Free tier: 1000 requests/day
- Paid tiers available for higher limits
- Integration updates hourly (~24 requests/day per location)

## Setup Steps

### Add Integration via UI

**IMPORTANT:** Must be done AFTER deploying NixOS config (`airly` component enabled).

1. Go to Settings → Devices & Services
2. Click "+ Add Integration"
3. Search for "Airly"
4. Select "Airly" from list
5. Enter:
   - **API Key:** Your Airly API key
   - **Latitude:** Home coordinates (e.g., 50.085196)
   - **Longitude:** Home coordinates (e.g., 19.887609)
   - **Name:** Optional custom name (default: "Airly")
6. Click "Submit"

**Coordinate Tips:**

- Use home coordinates for accurate local readings
- Round to 6 decimals (e.g., 50.085196, not 50.0851957)
- Match coordinates with `homeassistant` config for consistency

**Alternative:** Use My button in [official docs](https://www.home-assistant.io/integrations/airly/)

## Created Entities

Integration creates sensors based on Airly measurements:

### Air Quality Index (CAQI)

- `sensor.airly_caqi` - Common Air Quality Index (scale: 0-500+)
- `sensor.airly_caqi_level` - Textual level (very low → very high)
- `sensor.airly_caqi_description` - Descriptive text

### Particulate Matter

- `sensor.airly_pm1` - PM1 (µg/m³)
- `sensor.airly_pm25` - PM2.5 (µg/m³)
- `sensor.airly_pm10` - PM10 (µg/m³)

### Environmental

- `sensor.airly_humidity` - Relative humidity (%)
- `sensor.airly_pressure` - Atmospheric pressure (hPa)
- `sensor.airly_temperature` - Temperature (°C)

### Advice

- `sensor.airly_advice` - Health advice based on air quality

**Note:** Entity names may vary based on configured name in setup (default prefix: `airly`)

## Verification

1. Check integration status:
   - Settings → Devices & Services
   - Look for "Airly" with green status
   - Device name: configured name or "Airly"

2. Check created sensors:
   - Settings → Devices & Services → Airly → {device}
   - Verify sensors populated with values (update interval: ~1 hour)
   - Developer Tools → States → filter by "airly"

3. Test in automation/dashboard:

   ```nix
   # Example: check PM2.5 level
   condition = [{
     condition = "numeric_state";
     entity_id = "sensor.airly_pm25";
     above = 50; # WHO guideline
   }];
   ```

## Troubleshooting

**Integration won't add:**

- Verify `airly` in extraComponents (default.nix:220)
- Restart HA if just enabled: `sudo systemctl restart home-assistant`
- Check API key validity at [developer.airly.org](https://developer.airly.org/)
- Verify internet connectivity (cloud service)

**Sensors show "unavailable":**

- Wait ~1 hour for first data fetch
- Check API rate limits (1000 req/day free tier)
- Verify coordinates are valid (lat: -90 to 90, lon: -180 to 180)
- Check HA logs: `journalctl -u home-assistant | grep -i airly`

**API rate limit exceeded:**

- Free tier: 1000 requests/day
- Integration updates hourly (~24/day) - should not exceed
- Check for duplicate integrations or other services using same key
- Consider paid tier if needed

**No data updates:**

- Airly updates hourly (not real-time)
- Integration uses cloud polling (requires internet)
- Verify API key active: check [developer portal](https://developer.airly.org/)

**Coordinate errors:**

- Ensure coordinates within Poland (Airly primarily covers Poland)
- Round to 6 decimals maximum
- Use decimal format (not degrees/minutes/seconds)

## Usage in Automations

### Example: High PM2.5 Alert

```nix
{
  id = "airly_high_pm25_alert";
  alias = "Airly - High PM2.5 Alert";
  trigger = [{
    platform = "numeric_state";
    entity_id = "sensor.airly_pm25";
    above = 50; # WHO 24h guideline
    "for" = {
      minutes = 30; # Sustained high level
    };
  }];
  action = [{
    action = "notify.send_message";
    target.entity_id = "notify.telegram";
    data.message = "⚠️ Wysoki poziom PM2.5: {{ states('sensor.airly_pm25') }} µg/m³";
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
          - "jak jest smog"
```

Handler in `intents.nix`:

```nix
AirQualityIntent = {
  speech.text = "Jakość powietrza: {{ states('sensor.airly_caqi_level') }}. PM2.5 wynosi {{ states('sensor.airly_pm25') }} mikrogramów na metr sześcienny. {{ states('sensor.airly_advice') }}";
};
```

### Example: Close Windows Automation

```nix
{
  id = "airly_bad_air_close_windows";
  alias = "Airly - Close Windows on Bad Air Quality";
  trigger = [{
    platform = "numeric_state";
    entity_id = "sensor.airly_caqi";
    above = 75; # High/Very High threshold
  }];
  action = [{
    action = "notify.send_message";
    target.entity_id = "notify.telegram";
    data.message = "⚠️ Zła jakość powietrza (CAQI: {{ states('sensor.airly_caqi') }}). Zamknij okna!";
  }];
}
```

## Related Documentation

- [Airly Integration](https://www.home-assistant.io/integrations/airly/)
- [Airly Developer Portal](https://developer.airly.org/)
- [Airly Official Website](https://airly.org/en/)
- [CAQI Index Explained](https://www.airqualitynow.eu/about_indices_definition.php)
- [WHO Air Quality Guidelines](https://www.who.int/news-room/fact-sheets/detail/ambient-(outdoor)-air-quality-and-health)
