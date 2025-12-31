# SOPS Setup Guide

## Overview

This project uses sops-nix with age encryption for secrets management. Three age keys are configured:

- **Homelab key**: For the homelab server (stored in Bitwarden)
- **Local key**: For local development (already installed at `~/.config/sops/age/keys.txt`)
- **Test key**: For CI/VM tests (private key committed in `tests/age-key.txt`)

## Keys

### Public Keys (safe to share)

- Homelab: `age1gadh9f6axhd44wp4j6yqutsfcta6dtdcjuzhu77wefamtzcrdvtstlnqk7`
- Local: `age10nm6ar2haj797ycemkp640xs0sc4juym57ll5zxh7uupg8rkhy5szt58tc`
- Test: `age1u5wcrsntpnqs4ldtm7hnjfumm4p0f5pazh9e95kqxn4m3uzp6pts2t7hhz` (private key in `tests/age-key.txt`)

### Private Keys (in Bitwarden)

Both private keys are stored in Bitwarden as secure notes:

- `klaudiusz-homelab-age-key`
- `klaudiusz-local-age-key`

## Homelab Setup

### 1. Install Homelab Private Key

SSH to homelab and run:

```bash
# Create directory
sudo mkdir -p /var/lib/sops-nix

# Copy key from Bitwarden (retrieve from Bitwarden first)
sudo nano /var/lib/sops-nix/key.txt
# Paste the homelab private key content

# Set permissions
sudo chmod 600 /var/lib/sops-nix/key.txt
sudo chown root:root /var/lib/sops-nix/key.txt
```

### 2. Verify Key

```bash
# Public key should match: age1gadh9f6axhd44wp4j6yqutsfcta6dtdcjuzhu77wefamtzcrdvtstlnqk7
nix shell nixpkgs#age -c age-keygen -y /var/lib/sops-nix/key.txt
```

### 3. Apply Configuration

Once the key is in place, Comin will pull the latest config and sops-nix will automatically decrypt secrets at `/run/secrets/`.

> **Important:** For `hosts/homelab`, `sops.age.generateKey` is set to `true`. If
> `/var/lib/sops-nix/key.txt` does **not** exist on the first boot, sops-nix will automatically
> generate a new random key file. This key will not match the Bitwarden-backed homelab key and
> cannot decrypt existing secrets. If you want to use the Bitwarden-stored key:
>
> - Make sure you install `/var/lib/sops-nix/key.txt` from Bitwarden **before the first boot**, or
> - Disable auto-generation by setting `sops.age.generateKey = false;` in your NixOS config so the
>   system fails instead of silently generating a mismatched key.

## Local Development

### Editing Secrets

```bash
# Edit encrypted secrets (opens in $EDITOR)
nix run nixpkgs#sops -- secrets/secrets.yaml
```

### Testing Decryption

```bash
# Decrypt to stdout
nix run nixpkgs#sops -- -d secrets/secrets.yaml
```

## Bitwarden Storage Steps

### Option 1: CLI (after fixing auth)

```bash
# Unlock Bitwarden
export BW_SESSION=$(bw unlock --raw)

# Store homelab key
bw create item "$(cat <<EOF
{
  "organizationId": null,
  "folderId": null,
  "type": 2,
  "name": "klaudiusz-homelab-age-key",
  "notes": "$(cat /tmp/homelab-age-key.txt)",
  "favorite": false,
  "secureNote": { "type": 0 }
}
EOF
)"

# Store local key
bw create item "$(cat <<EOF
{
  "organizationId": null,
  "folderId": null,
  "type": 2,
  "name": "klaudiusz-local-age-key",
  "notes": "$(cat /tmp/local-age-key.txt)",
  "favorite": false,
  "secureNote": { "type": 0 }
}
EOF
)"
```

### Option 2: Web UI

1. Open Bitwarden web vault
2. Create new "Secure Note" items:
   - Name: `klaudiusz-homelab-age-key`
   - Notes: Content of `/tmp/homelab-age-key.txt`
3. Create second note:
   - Name: `klaudiusz-local-age-key`
   - Notes: Content of `/tmp/local-age-key.txt`

## Security Notes

- Private keys stored in Bitwarden (encrypted, backed up)
- Homelab key only on homelab server at `/var/lib/sops-nix/key.txt`
- Local key at `~/.config/sops/age/keys.txt`
- Encrypted secrets in git safe to commit
- Only machines with private keys can decrypt

## Secrets Currently Managed

1. `grafana-admin-password` - Grafana web UI admin password
2. `home-assistant-prometheus-token` - Long-lived token for Prometheus scraping
3. `telegram-bot-token` - Telegram notification bot token
4. `telegram-chat-id` - Telegram chat ID for notifications

## Troubleshooting

### "failed to decrypt" error

- Verify private key exists and is readable
- Check public key in `.sops.yaml` matches private key
- Re-encrypt if keys changed: `nix run nixpkgs#sops -- updatekeys secrets/secrets.yaml`

### Permission denied

- Secrets owned by service users (grafana, prometheus, hass)
- Check `hosts/homelab/secrets.nix` for ownership config
