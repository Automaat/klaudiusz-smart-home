# Xiaomi Home Integration Setup

## Why Manual Configuration

Xiaomi Home integration uses OAuth 2.0 authentication which requires interactive login via browser.
Cannot be configured declaratively via NixOS.

## Prerequisites

- Xiaomi Mi Home account
- At least one Xiaomi device registered in Mi Home app
- Home Assistant accessible at `homeassistant.local:8123` or custom domain

## About This Integration

**Official integration by Xiaomi** - maintained by XiaoMi team

- OAuth 2.0 login (no password stored in HA)
- Supports most Xiaomi IoT devices except Bluetooth/infrared/virtual
- Communicates via Xiaomi Cloud (MQTT + HTTP)
- Tokens stored in clear text in config file (secure your HA instance)

**Known Issues (2025):**

- OAuth redirect may hang for some users
- Re-authentication issues reported
- If login fails, see Troubleshooting section

## Setup Steps

### 1. Ensure Integration Installed

After deploying NixOS config, verify custom component exists:

```bash
# On homelab server
ls -la /var/lib/hass/custom_components/xiaomi_home
```

Should show symlink to Nix store. If missing, restart HA:

```bash
sudo systemctl restart home-assistant
```

### 2. Add Integration via UI

**IMPORTANT:** This must be done AFTER deploying NixOS config (custom component symlinked).

1. Go to Settings → Devices & Services
2. Click "+ Add Integration"
3. Search for "Xiaomi Home"
4. Click "Xiaomi Home" integration (NOT "Xiaomi Miio")
5. Click "Click here to login"
6. Browser opens to Xiaomi OAuth page
7. Log in with your Xiaomi Mi Home account credentials
8. Complete any 2FA/CAPTCHA challenges
9. Browser redirects to `homeassistant.local:8123` with auth token
10. Integration completes setup automatically

### 3. Configure Host Resolution (If Needed)

If OAuth redirect fails, ensure `homeassistant.local` resolves:

**On your computer (not server):**

```bash
# Test resolution
ping homeassistant.local

# If fails, add to /etc/hosts
echo "192.168.0.241 homeassistant.local" | sudo tee -a /etc/hosts
```

Replace `192.168.0.241` with your homelab server IP.

### 4. Select Devices

After successful login:

1. Integration shows list of your Xiaomi devices
2. Select devices to add to Home Assistant
3. Click "Submit"
4. Devices appear in Settings → Devices & Services → Xiaomi Home

## Verification

1. Check integration status:
   - Settings → Devices & Services
   - Look for "Xiaomi Home" with green status
   - Verify your devices listed

2. Test device control:
   - Go to device page
   - Try turning on/off or changing settings
   - Check device responds in Mi Home app

3. Check entities:
   - Developer Tools → States
   - Search for your device entities
   - Verify states update correctly

## Troubleshooting

### OAuth Redirect Hangs

**Symptom:** Browser redirect gets stuck, integration not added

**Solutions:**

1. **Pre-authenticate:** Log into <https://account.xiaomi.com> from same network as HA,
   complete CAPTCHA/2FA, then immediately try integration setup

2. **Host resolution:** Ensure `homeassistant.local` resolves to your HA server IP (see step 3 above)

3. **Use IP address:** If mDNS not working, access HA via `http://192.168.0.241:8123` instead

4. **Update HA:** Some users report updating HA core + integration to latest versions fixes issue

### Re-authentication Fails

**Symptom:** Integration asks to re-authenticate, loader spins infinitely

**Solutions:**

1. Remove integration completely (Settings → Devices & Services → Xiaomi Home → Delete)
2. Restart Home Assistant: `sudo systemctl restart home-assistant`
3. Re-add integration from scratch

### No Devices Shown

**Symptom:** Integration adds successfully but no devices listed

**Solutions:**

1. Verify devices in Mi Home app (same account)
2. Check device categories - Bluetooth/infrared/virtual not supported
3. Try removing and re-adding device in Mi Home app

### Integration Not Found

**Symptom:** "Xiaomi Home" doesn't appear in integration search

**Solutions:**

1. Verify custom component installed:

   ```bash
   ls -la /var/lib/hass/custom_components/xiaomi_home
   ```

2. Check HA logs for errors:

   ```bash
   journalctl -u home-assistant | grep -i xiaomi
   ```

3. Restart HA after NixOS deployment:

   ```bash
   sudo systemctl restart home-assistant
   ```

## Migration from Xiaomi Miio

If migrating from `xiaomi_miio` integration:

1. **Before deploying:** Note device entity IDs (e.g., `fan.xiaomi_air_purifier_3h`)
2. **Deploy NixOS config:** Old integration removed, new installed
3. **Add Xiaomi Home integration:** Follow setup steps above
4. **Update automations/scripts:** Entity IDs may change (e.g., `fan.mi_air_purifier_3h`)
5. **Update dashboards:** Replace old entity IDs with new ones

**Entity ID changes:**

- Xiaomi Miio: `fan.xiaomi_air_purifier_3h`
- Xiaomi Home: `fan.mi_air_purifier_3h` (varies by device)

Check Developer Tools → States to find new entity IDs.

## Related Documentation

- [Xiaomi Home Integration (GitHub)](https://github.com/XiaoMi/ha_xiaomi_home)
- [Xiaomi Home Integration (HA Community)](https://community.home-assistant.io/t/xiaomi-home-integration/930629)
- [OAuth Login Issues](https://github.com/XiaoMi/ha_xiaomi_home/issues/1352)
- [CAPTCHA/2FA Problems](https://github.com/home-assistant/core/issues/147122)
