# Roborock Integration Setup

## Why Manual Configuration

OAuth2 authentication via Roborock app account requires interactive browser login.
Cannot be configured declaratively via NixOS.

## Prerequisites

- Roborock app account (NOT Mi Home app)
- Q series vacuum registered in Roborock app
- Home Assistant Cloud enabled OR external URL configured (for OAuth callback)
- Static IP recommended for vacuum (router DHCP reservation)

## About This Integration

**Native Home Assistant integration:**

- Local control with cloud discovery (ports 58867 TCP, 58866 UDP)
- ~15 entities: vacuum control, battery, consumables, error sensors
- Rate limiting protection built-in
- Hybrid: cloud API for discovery → local API for control

## Setup Steps

### 1. Add Integration via UI

1. Go to Settings → Devices & Services
2. Click "+ Add Integration"
3. Search for "Roborock"
4. Click "Roborock" integration
5. Click "Authorize" to start OAuth flow
6. Browser opens to Roborock login page
7. Log in with Roborock app credentials
8. Complete any 2FA/CAPTCHA challenges
9. Browser redirects to Home Assistant with auth token
10. Select vacuum from device list
11. Click "Submit"

### 2. Verify Setup

**Check integration status:**

```bash
# On homelab server
journalctl -u home-assistant | grep -i roborock
```

**Check entities created:**

1. Developer Tools → States
2. Filter: `vacuum.`
3. Verify entity appears (e.g., `vacuum.roborock_q7_max`)

**Test control:**

1. Go to vacuum entity page
2. Click "Start" - vacuum should begin cleaning
3. Click "Return to base" - vacuum should dock

## Troubleshooting

### OAuth Redirect Hangs

**Symptom:** Browser redirect stuck, integration not added

**Solutions:**

1. Ensure HA Cloud enabled (Settings → Home Assistant Cloud) OR external URL configured
2. Check browser console for errors
3. Try incognito mode (clear cookies)
4. Pre-authenticate at <https://roborock.com> before starting setup

### No Devices Shown

**Symptom:** OAuth succeeds but no vacuum listed

**Solutions:**

1. Verify vacuum in Roborock app (same account)
2. Check vacuum online (not in sleep mode)
3. Try removing and re-adding vacuum in Roborock app
4. Restart Home Assistant: `sudo systemctl restart home-assistant`

### Local API Not Working

**Symptom:** Integration uses cloud API (slower responses)

**Solutions:**

1. Verify ports 58867 (TCP) and 58866 (UDP) accessible
2. Check vacuum has static IP
3. Test network connectivity: `ping <vacuum_ip>`
4. Check firewall rules (if custom firewall configured)

### Integration Not Found

**Symptom:** "Roborock" doesn't appear in integration search

**Solutions:**

1. Check NixOS config deployed: `systemctl status comin`
2. Verify extraComponents includes "roborock"
3. Restart HA after deployment: `sudo systemctl restart home-assistant`
4. Check HA logs: `journalctl -u home-assistant | tail -50`

## Related Documentation

- [Roborock Integration (Official)](https://www.home-assistant.io/integrations/roborock/)
- [Roborock App Download](https://global.roborock.com/pages/roborock-app)
- [HA Community Discussion](https://community.home-assistant.io/t/which-roborock-integration-is-better/688380)
