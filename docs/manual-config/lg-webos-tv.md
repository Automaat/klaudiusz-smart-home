# LG WebOS TV

**Why manual?** WebOS integration requires network discovery or manual IP entry, and
initial pairing requires accepting the connection on the TV screen.

**When to do this:** After adding TV to network, before voice/automation control.

## Setup Steps

**1. Ensure TV is powered on and connected to network:**

- TV must be on same network as Home Assistant
- Enable "Mobile TV On" in TV settings for wake-on-LAN support:
  - **Settings** → **General** → **Mobile TV On** → **Turn On**

**2. Add integration:**

1. Open Home Assistant UI
2. Navigate to **Settings** → **Devices & Services**
3. WebOS TV should appear under **Discovered** (if auto-discovery works)
4. Click **CONFIGURE**
5. **Accept connection prompt on TV screen** (appears within 30 seconds)
6. Device configured and ready

**If WebOS TV doesn't auto-discover:**

1. Click **+ ADD INTEGRATION**
2. Search for and select **LG webOS Smart TV**
3. Enter TV IP address (check router DHCP leases or TV network settings)
4. Click **SUBMIT**
5. **Accept connection prompt on TV screen**

**3. Configure entity name (optional):**

1. In **Devices & Services**, click **LG webOS Smart TV** card
2. Click device name
3. Rename to Polish format: `Telewizor {location}`
   - Example device name: `Telewizor Salon` (creates `media_player.telewizor_salon`)

## Verification

**Check device status:**

1. **Settings** → **Devices & Services** → **LG webOS Smart TV**
2. Device should show as "Available" when TV is on
3. Entities created:
   - `media_player.telewizor_salon` (or custom Polish name)
   - `media_player.{tv_name}_soundbar` (if soundbar connected)

**Test control:**

```bash
# Test service call
ssh homelab "ha-cli service call media_player.turn_on --arguments \
  entity_id=media_player.telewizor_salon"
```

## Voice Control

After setup, TV can be controlled via voice commands:

- Uses `TurnOnMedia`/`TurnOffMedia` intents from `intents.nix`
- Expose entity: **Settings** → **Voice assistants** → **Expose** tab
- Toggle `media_player.telewizor_salon`
- Test commands: *"Włącz telewizor salon"*, *"Wyłącz telewizor"*

## Notes

- TV must support wake-on-LAN for power-on when off
- Integration persists across HA restarts
- Entity unavailable when TV fully powered off (depends on "Mobile TV On" setting)

## Related Documentation

- [LG webOS Smart TV Integration](https://www.home-assistant.io/integrations/webostv/)
