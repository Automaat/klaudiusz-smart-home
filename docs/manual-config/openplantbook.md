# OpenPlantbook

**Why manual?** OpenPlantbook is installed declaratively via Nix, but requires
API credentials (client_id + secret) that must be configured through the Home
Assistant UI.

**When to do this:** After adding plant sensors to your system. OpenPlantbook
provides automatic plant species data and optimal growing conditions for the
Plant component.

## Prerequisites

- OpenPlantbook account (free registration at https://open.plantbook.io)
- OpenPlantbook integration installed declaratively (already configured in Nix)
- Plant component installed (recommended for automatic data)

## Configuration

### 1. Get API Credentials

1. Navigate to https://open.plantbook.io/apikey/show/
2. Sign in or create free account
3. Copy your **client_id** and **secret** (keep these secure)

### 2. Add OpenPlantbook Integration

1. Navigate to **Settings** → **Devices & Services**
2. Click **+ ADD INTEGRATION** (bottom-right)
3. Search for **"OpenPlantbook"**
4. Click to start configuration wizard

### 3. Configure Integration

**Required fields:**

- **Client ID**: Paste your client_id from OpenPlantbook
- **Secret**: Paste your secret from OpenPlantbook

Click **Submit** to complete setup.

## Usage with Plant Component

OpenPlantbook integrates with the Plant component to:

- Search plant species database via `openplantbook.search` service
- Fetch optimal conditions (temperature, humidity, light, moisture) via `openplantbook.get`
- Auto-populate thresholds when creating new plants

**Example service call:**

```yaml
service: openplantbook.search
data:
  alias: "Monstera Deliciosa"
```

Returns plant data including min/max thresholds for sensors.

## Verify Integration

**Check integration is active:**

1. **Settings** → **Devices & Services**
2. Find **OpenPlantbook** integration
3. Verify status shows "Configured"

**Check logs for errors:**

```bash
ssh homelab "journalctl -u home-assistant | grep -i 'openplantbook'"
```

Look for successful authentication and no API errors.

## Troubleshooting

**"Invalid credentials" error:**

- Verify client_id and secret are correct (no extra spaces)
- Check OpenPlantbook API status: https://open.plantbook.io
- Regenerate API credentials if needed

**Plant data not loading:**

- Verify plant species name is correct (use Latin names)
- Check internet connectivity from homelab
- Review logs: **Settings** → **System** → **Logs** → Filter "openplantbook"

**Integration not available after Nix rebuild:**

- OpenPlantbook is installed declaratively via symlink
- Check symlink exists: `ssh homelab "ls -la /var/lib/hass/custom_components/openplantbook"`
- Verify HA recognized the component:
  `ssh homelab "journalctl -u home-assistant | grep openplantbook"`
- Restart Home Assistant: `ssh homelab "sudo systemctl restart home-assistant"`

## Related Documentation

- [OpenPlantbook Website](https://open.plantbook.io)
- [OpenPlantbook API Docs](https://open.plantbook.io/docs/)
- [OpenPlantbook GitHub](https://github.com/Olen/home-assistant-openplantbook)
- [Plant Component GitHub](https://github.com/Olen/homeassistant-plant)
