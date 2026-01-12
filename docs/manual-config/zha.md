# Zigbee Home Automation (ZHA)

**Why manual?** While ZHA integration is enabled declaratively, the initial
setup wizard and device pairing must be done through the Home Assistant UI.

**When to do this:** After initial installation when Connect ZBT-2 dongle is plugged in.

## Initial Setup

1. Plug Connect ZBT-2 dongle into **USB 2.0 port** on homelab (not USB 3.0 - can cause 2.4GHz interference)
2. Verify device detected: `ssh homelab "ls -la /dev/zigbee"`
3. Open Home Assistant UI
4. Navigate to **Settings** → **Devices & Services**
5. ZHA should appear under **Discovered** (if auto-discovery works)
6. Click **CONFIGURE** and follow setup wizard:
   - **Radio Type**: Auto-detected (EZSP = Silicon Labs)
   - **Serial Device Path**: `/dev/zigbee`
   - **Port Speed**: 115200 (default)
   - Click **Submit**

**If ZHA doesn't auto-discover:**

1. Click **+ ADD INTEGRATION**
2. Search for and select **Zigbee Home Automation**
3. Select `/dev/zigbee` from dropdown
4. Click **Submit**

## Pairing Devices

1. In Home Assistant, go to **Settings** → **Devices & Services**
2. Click **Zigbee Home Automation** card
3. Click **ADD DEVICE** (bottom-right)
4. Enable pairing mode on your Zigbee device:
   - **Bulbs**: Turn on/off 5-6 times rapidly
   - **Sensors**: Press and hold reset button (~5 seconds)
   - **Switches**: Check device manual for pairing mode
5. Wait for device to appear (usually 10-30 seconds)
6. Rename device with Polish format: `{area} - {function}`
   - Example: `Salon - Główne światło`
   - Example: `Sypialnia - Czujnik ruchu`

## Verify Integration

**Check ZHA status:**

```bash
ssh homelab "journalctl -u home-assistant | grep -i zha"
```

**Check device connectivity:**

1. In Home Assistant: **Settings** → **Devices & Services** → **ZHA**
2. Click device → Check **Last Seen** timestamp
3. Healthy devices update within 1-2 minutes

## Related Documentation

- [ZHA Integration](https://www.home-assistant.io/integrations/zha/)
- [Connect ZBT-2 Product Page](https://www.home-assistant.io/connect/zbt-2/)
