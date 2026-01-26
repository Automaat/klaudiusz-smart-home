# Paperless-ngx Manual Configuration

## Overview

Document management system with OCR, indexing, archiving. NixOS service configured
declaratively, initial setup via browser wizard.

## Why Manual Configuration?

- Initial admin account creation (web wizard)
- UI preferences and dashboard setup
- Mobile app connection configuration

## Prerequisites

- Services running: `systemctl status paperless-web`
- Tailscale connected: `tailscale status`

## Initial Setup

### 1. Access Paperless UI

**Via Tailscale:**

- URL: `http://homelab:28981`
- Works from any Tailscale device

**Via SSH tunnel (fallback):**

```bash
ssh -L 28981:localhost:28981 homelab
# URL: http://localhost:28981
```

### 2. Complete Setup Wizard

1. Navigate to `http://homelab:28981`
2. Create admin account (auto-created by NixOS: username `admin`, password from secrets)
3. Set UI preferences, language (Polish/English)
4. Configure OCR settings (defaults: pol+eng)

### 3. Mobile App Setup

**App:** Paperless Mobile (iOS/Android)

1. Install from App Store / Play Store
2. Server: `http://homelab:28981`
3. Username: `admin` (NixOS module default)
4. Password: (from sops secrets)
5. Test upload

## Verification

```bash
# Check services
systemctl status paperless-scheduler
systemctl status paperless-consumer
systemctl status paperless-web

# Check logs
journalctl -u paperless-web -n 50

# Check database
sudo -u postgres psql -c "\l" | grep paperless

# Test API
curl -I http://localhost:28981/
```

## Troubleshooting

**Service won't start:**

```bash
journalctl -u paperless-web -n 100
systemctl status paperless-web
```

**OCR not working:**

- Check language packs: `ls /nix/store/*-tesseract*/share/tessdata/`
- Should see `pol.traineddata`, `eng.traineddata`

**Mobile app can't connect:**

- Verify Tailscale: `ping homelab`
- Check port: `ss -tlnp | grep 28981`

## Related Documentation

- [Paperless-ngx Docs](https://docs.paperless-ngx.com/)
- [NixOS Paperless Module](https://search.nixos.org/options?query=services.paperless)
