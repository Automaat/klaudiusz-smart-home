# 🏠 Klaudiusz Smart Home

NixOS-based smart home configuration with Home Assistant and Polish voice commands.

## 📋 Features

- ✅ **Home Assistant** - smart home hub
- ✅ **Polish voice commands** - Whisper STT + Piper TTS
- ✅ **GitOps** - auto-deploy via Comin
- ✅ **Declarative config** - everything in Nix

## 🖥️ Hardware Requirements

| Component | Recommended | Minimum |
| --------- | ----------- | ------- |
| CPU | Intel N100/N305 | Any x86_64 |
| RAM | 16GB | 8GB |
| Storage | 256GB NVMe | 64GB SSD |
| Optional | Zigbee USB dongle | - |

**Tested on:** Beelink Mini S12 Pro (N100, 16GB, 500GB)

---

## 🚀 Installation Guide

### Step 1: Download NixOS ISO

```bash
# Download minimal ISO (recommended for servers)
wget https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
```

Or download from: <https://nixos.org/download/>

### Step 2: Create Bootable USB

```bash
# On Linux/macOS
sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M status=progress

# Or use Balena Etcher (GUI)
```

### Step 3: Boot & Connect

1. Insert USB into mini PC
2. Boot from USB (F2/F7/F12 for boot menu)
3. Wait for NixOS installer to load

```bash
# Connect to WiFi (if needed)
sudo systemctl start wpa_supplicant
wpa_cli
> add_network
> set_network 0 ssid "YOUR_WIFI"
> set_network 0 psk "YOUR_PASSWORD"
> enable_network 0
> quit

# Or use ethernet (recommended)
```

### Step 4: Partition Disk

```bash
# List disks
lsblk

# Partition (assuming /dev/nvme0n1)
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

### Step 5: Generate Hardware Config

```bash
sudo nixos-generate-config --root /mnt
```

### Step 6: Clone This Repo

```bash
# Install git
nix-shell -p git

# Clone
cd /mnt/etc/nixos
sudo git clone https://github.com/Automaat/klaudiusz-smart-home.git .

# Copy hardware config
sudo cp /mnt/etc/nixos/hardware-configuration.nix \
        /mnt/etc/nixos/hosts/homelab/hardware-configuration.nix
```

### Step 7: Configure

```bash
# Edit configuration
sudo nano /mnt/etc/nixos/hosts/homelab/default.nix

# Update:
# 1. Add your SSH public key
# 2. Update Comin git URL to your fork
```

```bash
# Edit flake.nix if needed
sudo nano /mnt/etc/nixos/flake.nix
```

### Step 8: Install

```bash
sudo nixos-install --flake /mnt/etc/nixos#homelab

# Set root password when prompted
# Reboot
sudo reboot
```

---

## ⚙️ Post-Installation

### 1. First Login

```bash
# SSH into the machine
ssh admin@homelab.local
# or
ssh admin@<IP_ADDRESS>
```

### 2. Push Config to Git

```bash
cd /etc/nixos
git remote set-url origin git@github.com:Automaat/klaudiusz-smart-home.git
git push -u origin main
```

### 3. Setup Voice Assistant in HA

1. Open <http://homelab.local:8123>
2. Create admin account
3. Go to **Settings → Voice Assistants → Add Assistant**
4. Configure:
   - Name: `Polski Asystent`
   - Language: `Polish`
   - Conversation agent: `Home Assistant`
   - Speech-to-text: `faster-whisper`
   - Text-to-speech: `piper`

### 4. Copy Custom Sentences

```bash
sudo mkdir -p /var/lib/hass/custom_sentences/pl
sudo cp /etc/nixos/custom_sentences/pl/*.yaml /var/lib/hass/custom_sentences/pl/
sudo chown -R hass:hass /var/lib/hass/custom_sentences
sudo systemctl restart home-assistant
```

---

## 🗣️ Polish Voice Commands

| Command | Action |
| ------- | ------ |
| "Włącz światło w salonie" | Turn on living room light |
| "Zgaś wszystkie światła" | Turn off all lights |
| "Ustaw temperaturę na 22 stopnie" | Set thermostat to 22°C |
| "Dobranoc" | Run goodnight routine |
| "Wychodzę" | Run leaving home routine |
| "Która godzina" | Tell current time |

---

## 🔄 GitOps Workflow

After initial setup, all changes are deployed automatically:

```text
Edit locally → git push → Comin pulls (~60s) → NixOS rebuilds
```

### Manual Rebuild (if needed)

```bash
ssh admin@homelab
sudo nixos-rebuild switch --flake /etc/nixos#homelab
```

---

## 📁 Project Structure

```text
klaudiusz-smart-home/
├── flake.nix                 # Nix flake entry point
├── hosts/
│   └── homelab/
│       ├── default.nix       # Main host config
│       ├── hardware-configuration.nix
│       └── home-assistant/
│           ├── default.nix   # HA + voice config
│           ├── intents.nix   # Voice command handlers
│           └── automations.nix
└── custom_sentences/
    └── pl/
        └── intents.yaml      # Polish voice patterns
```

---

## 🧪 Testing

### Test Levels

#### Static Tests (Fast - PRs)

- Config validation (automation IDs, service calls, entity IDs)
- Schema validation (YAML syntax, intents, Jinja2 templates)
- Service validation (PostgreSQL config)
- HA config structure validation
- Runs on: All PRs via CI

#### Integration Tests (Slow - Main Only)

- NixOS VM boot test (~5-10 min)
- Service health checks (HA, PostgreSQL, Grafana, Prometheus, Wyoming)
- HTTP endpoint validation
- Runs on: Main branch pushes via CI

### Local Testing

```bash
# Quick check (before commit)
nix flake check

# Static tests only (fast)
./scripts/test-integration.sh --static-only

# Integration tests (slow, boots VM)
./scripts/test-integration.sh --integration-only

# All tests (comprehensive)
./scripts/test-integration.sh

# Verbose output
./scripts/test-integration.sh --verbose
```

### CI/CD Pipeline

**On PRs:**

- Static checks (fast feedback)
- Format validation
- YAML/Markdown lint

**On Main:**

- All PR checks
- Full system build
- VM integration tests (boots system, verifies services)
- **Blocks Comin deployment if tests fail**

### Available Checks

```bash
# List all checks
nix eval .#checks.x86_64-linux --apply builtins.attrNames

# Run specific check
nix build .#checks.x86_64-linux.vm-integration-test
nix build .#checks.x86_64-linux.ha-config-validation
nix build .#checks.x86_64-linux.all-static-tests
nix build .#checks.x86_64-linux.all-integration-tests
```

---

## 🔧 Configuration Tips

### Add Zigbee Support

Uncomment in `hosts/homelab/home-assistant/default.nix`:

```nix
extraComponents = [
  "zha"  # or use zigbee2mqtt
];
```

### Add More Devices

```nix
extraComponents = [
  "hue"       # Philips Hue
  "cast"      # Google Cast
  "esphome"   # ESPHome devices
  "mqtt"      # MQTT devices
];
```

### Offload AI to Beast PC

Add to HA config:

```nix
services.home-assistant.config.rest_command = {
  ask_ollama = {
    url = "http://BEAST_PC_IP:11434/api/generate";
    method = "POST";
    content_type = "application/json";
    payload = ''{"model": "qwen3:8b", "prompt": "{{ query }}"}'';
  };
};
```

---

## 🐛 Troubleshooting

### Check Service Status

```bash
systemctl status home-assistant
systemctl status wyoming-faster-whisper-default
systemctl status wyoming-piper-default
```

### View Logs

```bash
journalctl -u home-assistant -f
journalctl -u wyoming-faster-whisper-default -f
```

### Rebuild After Changes

```bash
sudo nixos-rebuild switch --flake /etc/nixos#homelab
```

### Comin Status

```bash
systemctl status comin
journalctl -u comin -f
```

---

## 📚 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Assistant Docs](https://www.home-assistant.io/docs/)
- [NixOS Home Assistant Wiki](https://wiki.nixos.org/wiki/Home_Assistant)
- [Comin GitOps](https://github.com/nlewo/comin)
- [Polish Intents](https://github.com/home-assistant/intents/tree/main/sentences/pl)

---

## 📝 License

MIT
