# Zigbee Setup Guide

Complete guide for adding Zigbee devices using Home Assistant Connect ZBT-2.

## Hardware

### Home Assistant Connect ZBT-2

- Silicon Labs EFR32MG21 chip
- Zigbee 3.0 + Thread/Matter support
- USB-C connector
- CP2102N USB-to-UART bridge (idVendor: 10c4, idProduct: ea60)

Product page: <https://www.home-assistant.io/connect/zbt-2/>

## Prerequisites

- Home Assistant Connect ZBT-2 dongle
- USB port on your homelab server
- Working NixOS + Home Assistant setup

## Installation

### 1. Plug in ZBT-2

Connect the dongle to any USB port on your homelab server.

### 2. Verify Device Detection

**SSH into homelab:**

```bash
ssh admin@homelab.local
```

**Check USB device:**

```bash
# List USB devices
lsusb | grep 10c4:ea60

# Expected output:
# Bus 001 Device 003: ID 10c4:ea60 Silicon Labs CP210x UART Bridge

# Check serial device
ls -la /dev/tty* | grep -E "(USB|ACM)"

# Expected output (one of):
# /dev/ttyUSB0
# /dev/ttyACM0

# View kernel messages
dmesg | tail -20

# Expected output includes:
# usb 1-1: New USB device found, idVendor=10c4, idProduct=ea60
# cp210x 1-1:1.0: cp210x converter detected
# usb 1-1: cp210x converter now attached to ttyUSB0
```

### 3. Configuration Already Applied

ZHA support is **already configured** in this repository:

**In `hosts/homelab/home-assistant/default.nix`:**

```nix
# ZHA component enabled
extraComponents = [
  "zha"  # Zigbee Home Automation
];

# ZHA config
services.home-assistant.config.zha = {
  database_path = "/var/lib/hass/zigbee.db";
};

# User permissions
users.users.hass.extraGroups = ["dialout"];

# Persistent device symlink + auto-start Home Assistant when dongle appears
services.udev.extraRules = ''
  SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", TAG+="systemd", ENV{SYSTEMD_WANTS}="home-assistant.service"
'';
```

### 4. Rebuild System

**On homelab (via SSH):**

```bash
# Manual rebuild (or wait ~60s for Comin)
sudo nixos-rebuild switch --flake /etc/nixos#homelab
```

**Verify udev rule created the symlink:**

```bash
ls -la /dev/zigbee

# Expected output:
# lrwxrwxrwx 1 root root 7 Dec 30 10:00 /dev/zigbee -> ttyUSB0
```

### 5. Restart Home Assistant

```bash
sudo systemctl restart home-assistant

# Check logs
journalctl -u home-assistant -f
```

Look for ZHA initialization:

```text
INFO (MainThread) [homeassistant.components.zha.core.gateway] Zigbee Home Automation starting
INFO (MainThread) [bellows.ezsp] EZSP Radio is using /dev/zigbee
INFO (MainThread) [homeassistant.components.zha.core.gateway] Radio type: EZSP
```

### 6. Configure ZHA in Home Assistant UI

**Open Home Assistant:** <http://homelab.local:8123>

1. Go to **Settings → Devices & Services**
2. ZHA should auto-discover and show "Discovered" badge
3. Click **Configure**
4. Select serial port: `/dev/zigbee`
5. Click **Submit**
6. ZHA will initialize (takes ~30 seconds)

**If ZHA doesn't auto-discover:**

1. Click **Add Integration**
2. Search for "Zigbee Home Automation"
3. Select `/dev/zigbee`
4. Submit

## Adding Zigbee Devices

### Enable Pairing Mode

**In Home Assistant UI:**

1. Go to **Settings → Devices & Services → Zigbee Home Automation**
2. Click **Configure**
3. Click **Add devices via this device**
4. Pairing mode is active for 60 seconds

### Pair Device

Follow device-specific pairing instructions:

**Common methods:**

- **Bulbs:** Turn on/off 5-6 times quickly
- **Switches:** Hold reset button 5-10 seconds
- **Sensors:** Press reset button 3 times
- **Plugs:** Hold button 5 seconds

**Check pairing status in HA:**

- Notification appears when device joins
- Device shows in **Devices & Services → ZHA**

### Configure Device

1. Click on newly added device
2. Set **Name** (e.g., "Salon - Główne światło")
3. Assign **Area** (e.g., "Salon")
4. Configure entities if needed

## Device Recommendations

### Tested & Working

| Type   | Brand | Model          | Notes                |
| ------ | ----- | -------------- | -------------------- |
| Bulb   | IKEA  | TRÅDFRI E27    | Affordable, reliable |
| Switch | IKEA  | TRÅDFRI remote | 5 buttons, battery   |
| Sensor | Aqara | Motion sensor  | Fast response        |
| Plug   | IKEA  | TRÅDFRI outlet | EU plug              |

### Brands Compatible with Zigbee 3.0

- IKEA TRÅDFRI
- Philips Hue (but use Hue hub for best experience)
- Aqara
- Sonoff
- Tuya
- Xiaomi
- OSRAM

## Troubleshooting

### ZHA Not Starting

**Check logs:**

```bash
journalctl -u home-assistant | grep -i zha
```

**Common issues:**

1. **Device not accessible**

   ```bash
   # Check device exists
   ls -la /dev/zigbee

   # Check permissions
   sudo usermod -aG dialout hass
   sudo systemctl restart home-assistant
   ```

2. **Wrong device path**

   ```bash
   # Find correct device
   ls -la /dev/ttyUSB* /dev/ttyACM*

   # Update udev rule if needed
   ```

3. **USB not recognized**

   ```bash
   # Check USB connection
   lsusb | grep 10c4:ea60

   # Try different USB port
   # Reconnect dongle
   ```

### Device Won't Pair

1. **Reset device** - follow manufacturer instructions
2. **Move closer** - within 2m of coordinator
3. **Remove existing pairing** - reset device completely
4. **Check battery** - replace if low
5. **Extend timeout**:

   ```bash
   # In HA Developer Tools → Services:
   # Service: zha.permit
   # Duration: 254 (max)
   ```

### Devices Randomly Offline

**Build mesh network:**

- Add powered devices (plugs, bulbs) as routers
- Place routers between coordinator and battery devices
- Minimum 3-5 powered devices for stable mesh

**Check coordinator:**

```bash
# ZHA should be at /dev/zigbee
ls -la /dev/zigbee

# Verify coordinator firmware
# In HA: Settings → Devices & Services → ZHA → Configure → Reconfigure Radio
```

### Check Zigbee Network Health

**In Home Assistant UI:**

1. Go to **Settings → Devices & Services → ZHA**
2. Click device name
3. Check:
   - **LQI** (Link Quality): >100 is good
   - **RSSI**: >-80 dBm is acceptable
   - **Last seen**: should be recent

**Visualize network:**

1. Install **ZHA Network Visualization Card** via HACS
2. Add to dashboard
3. See mesh topology

## Voice Commands for Zigbee Devices

Polish voice commands work automatically with Zigbee devices.

**Example sentences** (already configured):

```yaml
# Turn on light
"Włącz światło w {area}"
"Zapal lampę w {area}"

# Turn off light
"Zgaś światło w {area}"
"Wyłącz lampę w {area}"

# All lights
"Włącz wszystkie światła"
"Zgaś wszystkie światła"
```

**After pairing device:**

1. Assign to area (e.g., "Salon")
2. Rename entity to Polish name
3. Voice command: "Włącz światło w salonie"

## Advanced Configuration

### Customize Zigbee Config

**In `hosts/homelab/home-assistant/default.nix`:**

```nix
services.home-assistant.config.zha = {
  database_path = "/var/lib/hass/zigbee.db";

  # Optional: enable debug logging
  # zigpy_config = {
  #   ota = {
  #     ikea_provider = true;  # Enable IKEA firmware updates
  #   };
  # };
};
```

### Backup Zigbee Network

**Zigbee network config stored in:**

- `/var/lib/hass/zigbee.db` - device database
- `/var/lib/hass/.storage/core.config_entries` - ZHA config

**Backup before rebuilding:**

```bash
sudo cp /var/lib/hass/zigbee.db /var/lib/hass/zigbee.db.backup
```

**Restore:**

```bash
sudo systemctl stop home-assistant
sudo cp /var/lib/hass/zigbee.db.backup /var/lib/hass/zigbee.db
sudo chown hass:hass /var/lib/hass/zigbee.db
sudo systemctl start home-assistant
```

### Migrate from Other Coordinator

**From ConBee/RaspBee:**

1. Stop deCONZ/ZHA
2. Backup network
3. Plug in ZBT-2
4. Configure ZHA with `/dev/zigbee`
5. Restore backup in ZHA

**From Zigbee2MQTT:**

- Requires re-pairing all devices
- Export device names/configs first
- Zigbee2MQTT uses different network format

## Thread/Matter Support (Future)

ZBT-2 supports Thread/Matter but requires:

1. Home Assistant 2024.2+
2. Matter integration enabled
3. Thread network configuration

**Not yet implemented in this repo** - will be added when Matter devices available.

## Next Steps

- Pair your first Zigbee device
- Create automations in `hosts/homelab/home-assistant/automations.nix`
- Add device to area for voice control
- Build mesh network with powered devices

## Resources

- [ZHA Documentation](https://www.home-assistant.io/integrations/zha/)
- [Connect ZBT-2 Product Page](https://www.home-assistant.io/connect/zbt-2/)
- [Zigbee Device Compatibility](https://zigbee.blakadder.com/)
- [ZHA Device Support](https://github.com/zigpy/zha-device-handlers)
