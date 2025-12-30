# First Install Guide

Complete installation guide for Klaudiusz Smart Home on fresh hardware using NixOS GNOME live environment.

**Why GNOME ISO?**

- Easier network setup (GUI)
- Browse documentation during installation
- Use GUI text editor for config files
- More user-friendly for first-time NixOS users

## Prerequisites

- Blackview MP60 mini PC (Intel N5095, 16GB RAM, 512GB SSD)
  - Or any x86_64 machine with 8GB+ RAM, 64GB+ storage
- USB drive (4GB+)
- Network connection (ethernet recommended)
- SSH public key (`~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`)
- GitHub account with fork of this repo

## Already Installed NixOS with GUI Installer?

If you've already installed NixOS using the graphical installer and just need to switch to this repo's
configuration, follow steps 1-5 below, then continue from step 11 in the main guide.

**On your installed homelab system:**

1. **Backup hardware config:**

   ```bash
   sudo cp /etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix
   ```

2. **Replace default config with repo:**

   ```bash
   sudo rm -rf /etc/nixos/*
   cd /etc/nixos
   sudo git clone https://github.com/Automaat/klaudiusz-smart-home.git .
   sudo cp /tmp/hardware-configuration.nix hosts/homelab/hardware-configuration.nix
   ```

3. **Configure SSH key and git URL:**

   ```bash
   sudo nano hosts/homelab/default.nix
   ```

   Update:
   - **SSH key** (~line 50-60): Paste your public key in `openssh.authorizedKeys.keys`
   - **Git URL** (~line 100-105): Update `services.comin.remotes[0].url` to your fork

   Save (Ctrl+X, Y, Enter)

4. **Rebuild system:**

   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#homelab
   ```

   Takes 10-30 minutes. Downloads and configures Home Assistant, Wyoming voice, etc.

5. **Reboot:**

   ```bash
   sudo reboot
   ```

**After reboot:** Continue from **step 11** (Setup Git Push) in the main guide below.

---

## 1. Download NixOS ISO

**On your local machine:**

```bash
wget https://channels.nixos.org/nixos-24.11/latest-nixos-gnome-x86_64-linux.iso
```

Or download from: <https://nixos.org/download/> (select GNOME ISO for graphical installer)

## 2. Create Bootable USB

**On your local machine:**

```bash
# Linux/macOS
sudo dd if=nixos-gnome-*.iso of=/dev/sdX bs=4M status=progress

# Replace /dev/sdX with your USB drive (check with lsblk)
# WARNING: This will erase the USB drive!
```

Or use [Balena Etcher](https://etcher.balena.io/) (GUI, cross-platform, recommended)

## 3. Boot from USB

1. Insert USB into mini PC
2. Power on, press F2/F7/F12/DEL (depends on BIOS) to enter boot menu
   - Blackview MP60: typically F7 or F12 for boot menu
3. Select USB drive to boot
4. Wait for NixOS GNOME live environment to load (~1-2 minutes)
5. GNOME desktop will appear with "Install NixOS" icon on desktop

**Note:** This will replace Windows 11 Pro with NixOS. Back up any data first.

**Tip:** Firefox is preinstalled in live environment - use it to read this guide online during installation.

## 4. Connect to Network

**On the mini PC (GNOME desktop):**

1. **Ethernet (recommended):** Usually auto-connects, check network icon in top-right
2. **WiFi (if needed):**
   - Click network icon in top-right corner
   - Select your WiFi network
   - Enter password
   - Wait for connection

**Verify connection:** Open terminal (Activities → Terminal) and run:

```bash
ping -c 3 nixos.org
```

## 5. Partition Disk

**Don't use the graphical installer** - we'll install using our flake configuration instead.

**On the mini PC:** Open terminal (Activities → Terminal)

```bash
# List disks to identify your drive
lsblk
# Blackview MP60: should show 512GB drive (nvme0n1 or sda)

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

**Note:** The GNOME desktop is available if you need to browse documentation or look up commands during installation.

## 6. Generate Hardware Config

**In terminal:**

```bash
sudo nixos-generate-config --root /mnt
```

This creates `/mnt/etc/nixos/hardware-configuration.nix` with your hardware details.

## 7. Clone Repository

**In terminal:**

```bash
# Install git
nix-shell -p git

# Save hardware config before removing default config
sudo cp /mnt/etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix

# Remove default config
sudo rm -rf /mnt/etc/nixos/*

# Clone your fork
cd /mnt/etc/nixos
sudo git clone https://github.com/Automaat/klaudiusz-smart-home.git .

# Copy hardware config to correct location
sudo cp /tmp/hardware-configuration.nix \
        /mnt/etc/nixos/hosts/homelab/hardware-configuration.nix
```

## 8. Configure

### Option A: Terminal editor (nano)

```bash
sudo nano /mnt/etc/nixos/hosts/homelab/default.nix
```

### Option B: GUI editor

Open Files app, navigate to `/mnt/etc/nixos/hosts/homelab/`, open `default.nix` in Text Editor

### Update these lines

1. **SSH public key** (around line 50-60):

   ```nix
   users.users.admin = {
     openssh.authorizedKeys.keys = [
       "ssh-ed25519 AAAAC3... your-email@example.com"  # ← Paste your public key here
     ];
   };
   ```

   To get your public key:
   - **On local machine:** `cat ~/.ssh/id_ed25519.pub` (or `id_rsa.pub`)
   - **Or use GNOME:** Open Firefox in live environment, check email/GitHub settings where you saved your key

2. **Comin git URL** (around line 100-105):

   ```nix
   services.comin = {
     enable = true;
     remotes = [
       {
         name = "origin";
         url = "https://github.com/Automaat/klaudiusz-smart-home.git";  # ← Update this
         branches.main.name = "main";
       }
     ];
   };
   ```

**Save:**

- nano: Ctrl+X, Y, Enter
- GUI editor: Ctrl+S, close window

## 9. Install NixOS

**In terminal:**

```bash
sudo nixos-install --flake /mnt/etc/nixos#homelab
```

This will:

- Download all packages (~2-5GB, takes 10-30 minutes)
- Build the system
- Ask for root password (set a strong one)

**Note:** Grafana and Prometheus services won't start until you configure secrets in step 12.
Other services (Home Assistant, Wyoming voice) will work immediately.

**You can use GNOME during installation** - browser, file manager, etc. Installation runs in background.

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
git remote set-url origin git@github.com:Automaat/klaudiusz-smart-home.git

# Push to verify
git push -u origin main
```

From now on, changes pushed to GitHub will auto-deploy via Comin (~60 seconds).

## 12. Setup Secrets (sops-nix)

The system uses SOPS for secret management. Run the automated setup script:

**On homelab (via SSH):**

```bash
cd /etc/nixos
sudo nix-shell -p age sops --run "bash scripts/setup-secrets.sh"
```

This script will:
1. Generate age key at `/var/lib/sops-nix/key.txt`
2. Update `.sops.yaml` with new public key
3. Create `secrets/secrets.yaml` with dummy values
4. Encrypt the secrets file

**Review and update secrets:**

```bash
# Edit encrypted secrets (opens in editor)
sudo nix-shell -p sops --run "sops /etc/nixos/secrets/secrets.yaml"
```

Replace dummy values:
```yaml
grafana-admin-password: your-secure-password
home-assistant-prometheus-token: will-set-later-in-ha-ui
telegram-bot-token: your-bot-token  # or leave dummy
telegram-chat-id: your-chat-id      # or leave dummy
```

Save and exit (Ctrl+X, Y, Enter)

**Commit changes:**

```bash
cd /etc/nixos
git add .sops.yaml secrets/secrets.yaml
git commit -s -S -m "chore: setup secrets for homelab"
git push
```

Wait ~60 seconds for Comin to pull and rebuild, or rebuild immediately:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#homelab
```

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
