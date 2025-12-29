# Secrets Management with sops-nix

This directory contains encrypted secrets managed by [sops-nix](https://github.com/Mic92/sops-nix).

## Initial Setup (On Target Machine)

### 1. Generate Age Key

On the homelab server, generate the age encryption key:

```bash
sudo mkdir -p /var/lib/sops-nix
sudo sh -c 'umask 077; nix run nixpkgs#age -- -generate -o /var/lib/sops-nix/key.txt'
sudo chown root:root /var/lib/sops-nix/key.txt
```

### 2. Get Public Key

Extract the public key:

```bash
nix run nixpkgs#age -- -y /var/lib/sops-nix/key.txt
```

### 3. Update .sops.yaml

Replace the placeholder public key in `.sops.yaml` at the repository root with the public key from step 2.

### 4. Encrypt Secrets

Edit secrets with sops (automatically encrypts on save):

```bash
# First time - will encrypt the file
nix run nixpkgs#sops -- secrets/secrets.yaml
```

Fill in your actual secrets:
- `grafana-admin-password`: Secure password for Grafana admin
- `home-assistant-prometheus-token`: Long-lived token from HA

**Note:** SSH public keys are configured directly in `hosts/homelab/default.nix` (not secrets since they're public).

### 5. Deploy

Push changes to git. Comin will pull and NixOS will decrypt secrets at `/run/secrets/`.

## Editing Secrets

```bash
# Edit encrypted secrets
nix run nixpkgs#sops -- secrets/secrets.yaml
```

## Secret Locations

After NixOS activation, secrets are available at:
- Grafana password: `/run/secrets/grafana-admin-password`
- HA Prometheus token: `/var/lib/prometheus2/ha-token` (custom path)

## Security Notes

- Private key (`/var/lib/sops-nix/key.txt`) NEVER leaves the target machine
- Public key in `.sops.yaml` is safe to commit
- Encrypted `secrets.yaml` is safe to commit
- Only the target machine with the private key can decrypt

## Troubleshooting

### "Failed to decrypt" error

- Verify `/var/lib/sops-nix/key.txt` exists and is readable
- Check that public key in `.sops.yaml` matches the private key
- Re-encrypt secrets after key change: `sops updatekeys secrets/secrets.yaml`

### Permission denied on secret files

Secrets are owned by the service user (e.g., `grafana`, `prometheus`). Check ownership in `hosts/homelab/secrets.nix`.
