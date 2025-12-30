# First Install Guide

Complete installation guide for Klaudiusz Smart Home on fresh hardware.

## Prerequisites

- Intel N100/N305 mini PC (or any x86_64, 8GB+ RAM, 64GB+ storage)
- USB drive (4GB+)
- Network connection (ethernet recommended)
- SSH public key (`~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`)
- GitHub account with fork of this repo

## 1. Download NixOS ISO

**On your local machine:**

```bash
wget https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
```

Or download from: <https://nixos.org/download/> (select minimal ISO)

## 2. Create Bootable USB

**On your local machine:**

```bash
# Linux/macOS
sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M status=progress

# Replace /dev/sdX with your USB drive (check with lsblk)
# WARNING: This will erase the USB drive!
```

Or use [Balena Etcher](https://etcher.balena.io/) (GUI, cross-platform)

## 3. Boot from USB

1. Insert USB into mini PC
2. Power on, press F2/F7/F12/DEL (depends on BIOS) to enter boot menu
3. Select USB drive to boot
4. Wait for NixOS installer to load (you'll see a shell prompt)

## 4. Connect to Network

**On the mini PC (via keyboard/monitor):**

```bash
# Ethernet (recommended) - usually works automatically
# Check connection
ping -c 3 nixos.org

# WiFi (if needed)
sudo systemctl start wpa_supplicant
wpa_cli
# In wpa_cli:
> add_network
> set_network 0 ssid "YOUR_WIFI_NAME"
> set_network 0 psk "YOUR_WIFI_PASSWORD"
> enable_network 0
> quit

# Verify connection
ping -c 3 nixos.org
```

## 5. Partition Disk

**On the mini PC:**

```bash
# List disks to identify your drive
lsblk

# Partition (assuming /dev/nvme0n1 - adjust if different)
sudo parted /dev/nvme0n1 -- mklabel gpt
sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/nvme0n1 -- set 1 esp on
sudo parted /dev/nvme0n1 -- mkpart primary ext4 512MiB 100%

# Format
sudo mkfs.fat -F 32 -n boot /dev/nvme0n1p1
sudo mkfs.ext4 -L nixos /dev/nvme0n1p2

# Mount
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
```

**For SATA SSD:** Replace `/dev/nvme0n1` with `/dev/sda` (and `p1`/`p2` with `1`/`2`)

## 6. Generate Hardware Config

**On the mini PC:**

```bash
sudo nixos-generate-config --root /mnt
```

This creates `/mnt/etc/nixos/hardware-configuration.nix` with your hardware details.

## 7. Clone Repository

**On the mini PC:**

```bash
# Install git
nix-shell -p git

# Save hardware config before removing default config
sudo cp /mnt/etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix

# Remove default config
sudo rm -rf /mnt/etc/nixos/*

# Clone your fork
cd /mnt/etc/nixos
sudo git clone https://github.com/YOUR_USERNAME/klaudiusz-smart-home.git .

# Copy hardware config to correct location
sudo cp /tmp/hardware-configuration.nix \
        /mnt/etc/nixos/hosts/homelab/hardware-configuration.nix
```

## 8. Configure

**On the mini PC:**

```bash
sudo nano /mnt/etc/nixos/hosts/homelab/default.nix
```

### Update these lines

1. **SSH public key** (around line 50-60):

```nix
users.users.admin = {
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3... your-email@example.com"  # ← Paste your public key here
  ];
};
```

To get your public key on local machine:

```bash
cat ~/.ssh/id_ed25519.pub
# or
cat ~/.ssh/id_rsa.pub
```

1. **Comin git URL** (around line 100-105):

```nix
services.comin = {
  enable = true;
  remotes = [
    {
      name = "origin";
      url = "https://github.com/YOUR_USERNAME/klaudiusz-smart-home.git";  # ← Update this
      branches.main.name = "main";
    }
  ];
};
```

Save (Ctrl+X, Y, Enter)

## 9. Install NixOS

**On the mini PC:**

```bash
sudo nixos-install --flake /mnt/etc/nixos#homelab
```

This will:

- Download all packages (~2-5GB, takes 10-30 minutes)
- Build the system
- Ask for root password (set a strong one)

**Note:** Grafana and Prometheus services won't start until you configure secrets in step 12.
Other services (Home Assistant, Wyoming voice) will work immediately.

When done:

```bash
sudo reboot
```

Remove USB drive when prompted.

## 10. First Login

**From your local machine:**

```bash
# Wait for system to boot (~30 seconds)
ssh admin@homelab.local
# or if .local doesn't work, use IP
ssh admin@192.168.1.XXX

# Check services are running
systemctl status home-assistant
systemctl status wyoming-faster-whisper-default
systemctl status wyoming-piper-default
systemctl status comin
```

## 11. Setup Git Push

**On homelab (via SSH):**

First, setup GitHub authentication. Choose one:

### Option A: SSH key (recommended)

```bash
# Generate SSH key on homelab
ssh-keygen -t ed25519 -C "your-email@example.com"

# Display public key
cat ~/.ssh/id_ed25519.pub
# Copy output and add to GitHub: Settings → SSH and GPG keys → New SSH key
```

### Option B: Personal Access Token

- Create token at: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
- Scopes: `repo` (full control)
- Use HTTPS URL with token in step below

Now configure git:

```bash
cd /etc/nixos

# Configure git
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"

# Setup SSH remote (for push access)
git remote set-url origin git@github.com:YOUR_USERNAME/klaudiusz-smart-home.git

# Push to verify
git push -u origin main
```

From now on, changes pushed to GitHub will auto-deploy via Comin (~60 seconds).

## 12. Setup Secrets (sops-nix)

**On homelab (via SSH):**

```bash
# Generate age encryption key
sudo mkdir -p /var/lib/sops-nix
sudo sh -c 'umask 077; nix shell nixpkgs#age -c age-keygen -o /var/lib/sops-nix/key.txt'
sudo chown root:root /var/lib/sops-nix/key.txt

# Get public key
sudo nix shell nixpkgs#age -c age-keygen -y /var/lib/sops-nix/key.txt
# Copy the output (starts with "age1...")
```

**On your local machine:**

```bash
cd ~/path/to/klaudiusz-smart-home

# Update .sops.yaml with the public key from above
nano .sops.yaml
# Replace the existing age key with yours

# Edit secrets (will encrypt on save)
nix run nixpkgs#sops -- secrets/secrets.yaml
```

Fill in:

```yaml
grafana-admin-password: your-secure-password
home-assistant-prometheus-token: will-set-this-later-in-ha-ui
```

Save (Ctrl+X, Y, Enter)

```bash
# Commit and push
git add .sops.yaml secrets/secrets.yaml
git commit -s -S -m "chore: update sops keys and secrets"
git push
```

Wait ~60 seconds for Comin to pull and rebuild.

## 13. Setup Home Assistant

**On your local machine:**

Open <http://homelab.local:8123> (or <http://192.168.1.XXX:8123>)

1. Create admin account
2. Complete onboarding wizard
3. Go to **Settings → Voice Assistants → Add Assistant**
4. Configure:
   - **Name:** `Polski Asystent`
   - **Language:** `Polish`
   - **Conversation agent:** `Home Assistant`
   - **Speech-to-text:** `faster-whisper`
   - **Text-to-speech:** `piper`
5. Save

### Copy Custom Sentences

**On homelab (via SSH):**

```bash
sudo mkdir -p /var/lib/hass/custom_sentences/pl
sudo cp /etc/nixos/custom_sentences/pl/*.yaml /var/lib/hass/custom_sentences/pl/
sudo chown -R hass:hass /var/lib/hass/custom_sentences
sudo systemctl restart home-assistant
```

Wait ~30 seconds, then test voice commands in HA UI:

- "Która godzina"
- "Włącz światło w kuchni" (if you have lights configured)

### Create Prometheus Token

**In Home Assistant UI:**

1. Go to **Profile → Security → Long-lived access tokens**
2. Create token named `prometheus`
3. Copy the token

**On your local machine:**

```bash
# Edit secrets again
nix run nixpkgs#sops -- secrets/secrets.yaml
```

Update:

```yaml
home-assistant-prometheus-token: <paste-token-here>
```

Save, commit, push:

```bash
git add secrets/secrets.yaml
git commit -s -S -m "chore: add prometheus token"
git push
```

## 14. Setup Tailscale (Optional but Recommended)

**On homelab (via SSH):**

```bash
sudo tailscale up --accept-routes
```

Follow the login URL in your browser.

Now you can access:

- Home Assistant: <http://homelab:8123> (from anywhere)
- Grafana: <http://homelab:3000> (only on Tailscale)
- Prometheus: <http://homelab:9090> (only on Tailscale)

## 15. Verify Everything Works

**On homelab (via SSH):**

```bash
# Check all services
systemctl status home-assistant
systemctl status wyoming-faster-whisper-default
systemctl status wyoming-piper-default
systemctl status comin
systemctl status prometheus
systemctl status grafana
systemctl status postgresql

# Check logs
journalctl -u home-assistant --since "5 minutes ago"
journalctl -u comin --since "5 minutes ago"

# Verify secrets are decrypted
ls -l /run/secrets/
```

**On your local machine:**

- Home Assistant: <http://homelab.local:8123>
- Grafana: <http://homelab:3000> (via Tailscale)
- Test voice command in HA UI

## Next Steps

- Add devices to Home Assistant (Zigbee, WiFi, etc.)
- Configure automations in `hosts/homelab/home-assistant/automations.nix`
- Add custom voice commands in `custom_sentences/pl/intents.yaml`
- Setup backups (TODO - not yet automated)

## Troubleshooting

### Can't SSH into homelab

```bash
# Check if machine is reachable
ping homelab.local

# Try IP directly
nmap -sn 192.168.1.0/24  # Find IP on network
ssh admin@<IP>
```

### Home Assistant not starting

```bash
journalctl -u home-assistant -f

# Common issue: database migration
# Check PostgreSQL status
systemctl status postgresql
```

### Comin not pulling changes

```bash
journalctl -u comin -f

# Manual pull
cd /etc/nixos
sudo git pull
sudo nixos-rebuild switch --flake .#homelab
```

### Voice not working

```bash
# Check Wyoming services
systemctl status wyoming-faster-whisper-default
systemctl status wyoming-piper-default

# Check ports
ss -tlnp | grep 10300  # Whisper
ss -tlnp | grep 10200  # Piper
```

### Secrets not decrypting

```bash
# Verify age key exists
sudo ls -l /var/lib/sops-nix/key.txt

# Check public key matches
sudo nix shell nixpkgs#age -c age-keygen -y /var/lib/sops-nix/key.txt
# Compare with .sops.yaml in repo

# Re-encrypt if needed (on local machine)
nix run nixpkgs#sops -- updatekeys secrets/secrets.yaml
```

## GitOps Workflow

After initial setup, all changes are automatic:

```text
Local machine:
  Edit files → git commit → git push
    ↓
GitHub:
  Repo updated
    ↓
Homelab:
  Comin pulls every ~60s → NixOS rebuilds → Services restart
```

Manual rebuild only needed for testing:

```bash
ssh admin@homelab
sudo nixos-rebuild switch --flake /etc/nixos#homelab
```
