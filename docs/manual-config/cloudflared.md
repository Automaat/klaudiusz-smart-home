# Cloudflare Tunnel - External Home Assistant Access

**Why manual?** While Cloudflare Tunnel is configured declaratively in NixOS, the initial tunnel creation and domain configuration must be done through Cloudflare Dashboard.

**When to do this:** One-time setup for secure external access to Home Assistant at ha.mskalski.dev.

## Overview

Cloudflare Tunnel provides secure external access to Home Assistant without exposing ports or configuring dynamic DNS. Traffic flows:

```
Internet → Cloudflare Edge → Cloudflared (localhost) → Home Assistant (port 8123)
```

**Security features:**
- No open ports on home router
- TLS termination at Cloudflare Edge
- DDoS protection
- Access control via Cloudflare Access (optional)
- Automatic certificate management

## Architecture

**Declarative configuration (already done):**
- `services.cloudflared` enabled in `hosts/homelab/default.nix`
- Tunnel ID: `c0350983-f7b9-4770-ac96-34b8a5184c91`
- Ingress rule: `ha.mskalski.dev` → `http://localhost:8123`
- Proxy headers: Home Assistant trusts `X-Forwarded-For` from `127.0.0.1`

**Manual setup (one-time):**
- Create tunnel via Cloudflare Dashboard
- Generate tunnel credentials
- Configure DNS CNAME record

## Initial Setup

### 1. Create Tunnel (Cloudflare Dashboard)

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Select your domain (`mskalski.dev`)
3. Navigate to **Zero Trust** → **Networks** → **Tunnels**
4. Click **Create a tunnel**
5. Select **Cloudflared** as tunnel type
6. Name: `klaudiusz-homelab`
7. Click **Save tunnel**
8. Copy the **Tunnel ID** (UUID format)
9. Copy the **credentials.json** content

### 2. Store Credentials

**Encrypt credentials with SOPS:**

```bash
# On local machine
cd ~/sideprojects/klaudiusz-renovate-config

# Decrypt secrets file
mise run decrypt-secrets

# Add cloudflared credentials to secrets/secrets.decrypted.yaml
# Format: single-line JSON string
cloudflared:
  credentials: '{"AccountTag":"...","TunnelSecret":"...","TunnelID":"..."}'

# Encrypt back
mise run encrypt-secrets

# Commit encrypted secrets
git add secrets/secrets.yaml
git commit -s -S -m "feat(secrets): add cloudflared tunnel credentials"
```

**Verify on homelab:**

```bash
ssh homelab "sudo cat /run/secrets/cloudflared/credentials"
# Should show JSON credentials after rebuild
```

### 3. Configure DNS

1. In Cloudflare Dashboard, go to **DNS** → **Records**
2. Add CNAME record:
   - **Type**: CNAME
   - **Name**: `ha` (creates `ha.mskalski.dev`)
   - **Target**: `<tunnel-id>.cfargotunnel.com`
   - **Proxy status**: Proxied (orange cloud)
   - **TTL**: Auto
3. Click **Save**

### 4. Test External Access

**Verify tunnel status:**

```bash
ssh homelab "systemctl status cloudflared-tunnel-c0350983-f7b9-4770-ac96-34b8a5184c91"
```

**Check logs:**

```bash
ssh homelab "journalctl -u cloudflared-tunnel-c0350983-f7b9-4770-ac96-34b8a5184c91 -f"
```

**Test external access:**

```bash
curl -I https://ha.mskalski.dev
# Should return 200 OK or 302 redirect (Home Assistant login)
```

**Access from browser:**

1. Navigate to `https://ha.mskalski.dev`
2. Should show Home Assistant login page
3. Verify authentication works
4. Check **Developer Tools** → **Info** → Client IP is not `127.0.0.1`

## Security Considerations

### Home Assistant Proxy Configuration

**Already configured in `home-assistant/default.nix`:**

```nix
http = {
  use_x_forwarded_for = true;
  trusted_proxies = ["127.0.0.1" "::1"];
};
```

**Why required:**
- Cloudflared runs locally, proxies requests to `localhost:8123`
- Without proxy headers, HA sees all requests from `127.0.0.1`
- Breaks: authentication rate limiting, IP-based access control, audit logs
- `use_x_forwarded_for` tells HA to trust `X-Forwarded-For` header
- `trusted_proxies` restricts trust to localhost only

### Additional Security

**Recommendations:**
- Enable MFA in Home Assistant (Settings → Account → Multi-factor Authentication)
- Use strong passwords (password manager)
- Monitor failed login attempts
- Consider Cloudflare Access for additional authentication layer

**Cloudflare Access (optional):**
- Add authentication before reaching Home Assistant
- SSO integration (Google, GitHub, etc.)
- Geo-restrictions, device posture checks
- Configuration: Zero Trust → Access → Applications

## Credential Rotation

**If credentials are compromised:**

1. Revoke tunnel in Cloudflare Dashboard
2. Create new tunnel (follow Initial Setup)
3. Update tunnel ID in:
   - `hosts/homelab/default.nix` (cloudflareTunnelId variable)
   - `hosts/homelab/secrets.nix` (cloudflareTunnelId variable)
4. Encrypt new credentials with SOPS
5. Rebuild NixOS: `sudo nixos-rebuild switch --flake /etc/nixos#homelab`

**Credentials location:**
- Encrypted: `secrets/secrets.yaml` (in git)
- Decrypted: `/run/secrets/cloudflared/credentials` (on homelab, 0400 mode)

## Troubleshooting

### Tunnel Not Connecting

**Check service status:**

```bash
ssh homelab "systemctl status cloudflared-tunnel-*"
```

**Check logs:**

```bash
ssh homelab "journalctl -u cloudflared-tunnel-* -n 50"
```

**Common issues:**
- Invalid credentials → check `/run/secrets/cloudflared/credentials`
- Network connectivity → verify internet access
- DNS not propagated → wait 5 minutes, clear DNS cache

### "Unable to Reach" Error

1. Verify tunnel status (see above)
2. Check Home Assistant is running: `systemctl status home-assistant`
3. Test local access: `curl http://localhost:8123`
4. Check Cloudflare DNS record is proxied (orange cloud)

### Client IP Shows 127.0.0.1

**Symptom:** All requests in HA logs show `127.0.0.1`

**Cause:** Proxy configuration not enabled

**Fix:**
1. Verify `use_x_forwarded_for = true` in `home-assistant/default.nix`
2. Rebuild: `sudo nixos-rebuild switch --flake /etc/nixos#homelab`
3. Restart HA: `sudo systemctl restart home-assistant`

## Related Documentation

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Home Assistant HTTP Integration](https://www.home-assistant.io/integrations/http/)
- [SOPS Setup Guide](../SOPS_SETUP.md)
