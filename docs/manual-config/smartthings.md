# Samsung SmartThings

**Why manual?** SmartThings integration uses OAuth2 authentication, requiring login
through Samsung account. Cannot be configured declaratively.

**When to do this:** After setting up SmartThings devices in the SmartThings mobile app.

## Prerequisites

- SmartThings mobile app installed (iOS/Android)
- Samsung account created and logged in
- SmartThings devices added and responding in the app
- SmartThings hub configured (if using Zigbee/Z-Wave devices)
- Remote access configured:
  - **Option 1**: Home Assistant Cloud (Nabu Casa subscription) - OAuth handled via cloud
  - **Option 2**: Self-hosted with public HTTPS URL and external URL configured in HA

## Setup Steps

**1. Configure devices in SmartThings app:**

- Ensure all devices are added to SmartThings app
- Verify devices respond to controls in the app
- Note the "Location" name (usually "Home" or custom location)
- Test device controls before proceeding

**2. Add integration in Home Assistant:**

1. Open Home Assistant UI
2. Navigate to **Settings** → **Devices & Services**
3. Click **+ ADD INTEGRATION**
4. Search for and select **SmartThings**
5. Click **SUBMIT**

**3. OAuth authentication:**

1. Browser redirects to Samsung account login
2. Enter Samsung account credentials (same as SmartThings app)
3. Authorize Home Assistant to access SmartThings:
   - Read device status
   - Send commands to devices
   - Receive device events
4. Click **Allow** or **Authorize**
5. Browser redirects back to Home Assistant

**4. Select location:**

1. Choose SmartThings location from dropdown (e.g., "Home")
2. Click **SUBMIT**
3. Integration begins importing devices

**5. Verify devices:**

1. In **Settings** → **Devices & Services** → **SmartThings**
2. Check devices imported correctly
3. Entities created with format: `{domain}.{device_name}`
   - Example: `light.salon`, `switch.sypialnia`

## Configuration

**Rename entities (optional):**

1. Click device in **SmartThings** integration card
2. Click the entity
3. Set the **Friendly name** to a Polish label for voice control (what you will say)
4. Open the **entity settings** (gear icon) and manually set the **Entity ID** to lowercase with underscores
   - Example: Friendly name: `Światło salon`, Entity ID: `light.salon`
   - Example: Friendly name: `Gniazdko sypialnia`, Entity ID: `switch.sypialnia`
   - Voice commands use the Polish friendly name; automations and CLI use the entity_id

**Expose to voice assistant:**

1. Go to **Settings** → **Voice assistants** → **Expose** tab
2. Toggle SmartThings entities for voice control
3. Polish names work automatically with voice commands

## Verification

**Check integration status:**

```bash
ssh homelab "journalctl -u home-assistant | grep -i smartthings"
```

**Test device control:**

```bash
# Test light control
ssh homelab "ha-cli service call light.turn_on --arguments \
  entity_id=light.salon"

# Test switch control
ssh homelab "ha-cli service call switch.turn_on --arguments \
  entity_id=switch.sypialnia"
```

## Troubleshooting

**Integration setup fails:**

- Verify Home Assistant accessible remotely (OAuth requires callback)
- Check Samsung account credentials
- Ensure devices visible in SmartThings app

**Devices not importing:**

1. Click **CONFIGURE** on SmartThings integration
2. Click **Re-sync devices**
3. Wait 30-60 seconds for import

**Device states not updating:**

- Check SmartThings hub online (if applicable)
- Verify device battery level (for battery-powered devices)
- Check device connectivity in SmartThings app

**OAuth callback fails:**

- Ensure `cloud:` component enabled (already in `default.nix`)
- If using Home Assistant Cloud (Nabu Casa): verify subscription is active
- If self-hosting: check firewall rules allow inbound HTTPS and external URL is configured

## Notes

- OAuth token refreshes automatically
- Integration supports most SmartThings device types (lights, switches, sensors, locks, thermostats)
- SmartThings hub required for Zigbee/Z-Wave devices (WiFi devices work without hub)
- Cloud-dependent - requires internet connection to SmartThings cloud
- State updates near real-time via webhooks

## Related Documentation

- [SmartThings Integration](https://www.home-assistant.io/integrations/smartthings/)
