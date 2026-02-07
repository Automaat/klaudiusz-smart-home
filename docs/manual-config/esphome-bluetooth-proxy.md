# ESPHome Bluetooth Proxy - Manual Configuration

## Why Manual Configuration?

ESP32 Bluetooth proxy setup requires:

- **Firmware flashing** via USB/OTA (cannot be automated via Nix)
- **WiFi credentials** entry during initial setup (device-specific)
- **Area assignment** in HA GUI after adoption (for Bermuda trilateration)

These steps involve physical device access and runtime configuration outside declarative scope.

---

## When to Perform Setup

**Use ESP32 proxies if:**

- Built-in homelab BLE adapter coverage insufficient (test first with Bermuda diagnostics)
- RSSI < -80 dBm in rooms distant from homelab server
- Bermuda reports "unknown" for person location frequently

**Timing:** Before Bermuda integration setup (Phase 2 in person tracking plan).

---

## Hardware Requirements

### Recommended Boards

**ESP32-C3/S3 Series (Preferred):**

- **ESP32-C3-DevKitM-1** (~$5) - Compact, low power, good BLE range
- **ESP32-S3-DevKitC-1** (~$10) - Better WiFi antenna, USB-C
- **Seeed XIAO ESP32C3** (~$6) - Tiny form factor, breadboard-friendly

**Avoid:**

- **ESP8266** - No Bluetooth support
- **ESP32 original (dual-core)** - Higher power, older BLE stack
- **ESP32-C6/H2** - Newer chips, less ESPHome support (as of 2025)

### Requirements

- USB-C or Micro-USB cable (data capable, not charge-only)
- 5V power supply (USB adapter or powered hub)
- WiFi network (2.4GHz, same as homelab server)

---

## Deployment Methods

### Method 1: ESPHome Web Flasher (Easiest)

**No local ESPHome installation needed, works in Chrome/Edge.**

1. Navigate to: [https://esphome.github.io/bluetooth-proxies/](https://esphome.github.io/bluetooth-proxies/)
2. Connect ESP32 via USB
3. Click **"Connect"** → Select serial port (e.g., `/dev/ttyUSB0`, `COM3`)
4. Choose firmware:
   - **ESP32-C3:** `bluetooth-proxy-esp32c3.bin`
   - **ESP32-S3:** `bluetooth-proxy-esp32s3.bin`
5. Click **"Install"** → Wait for flashing (~30 seconds)
6. **WiFi Setup:**
   - Device creates hotspot: `bluetooth-proxy-XXXXXX`
   - Connect phone/laptop to hotspot
   - Enter WiFi SSID/password in captive portal
7. Device auto-discovered in HA (**Configuration → Integrations → ESPHome**)
8. Click **"Configure"** → Set friendly name (e.g., "Salon Bluetooth Proxy")

**Pros:**

- No CLI tools required
- Works on any OS with Chrome
- Beginner-friendly

**Cons:**

- No customization (fixed firmware)
- Requires USB access (not suitable for remote deployment)

---

### Method 2: ESPHome Dashboard (Customizable)

**For advanced users wanting custom ESPHome configs (e.g., sensors + proxy).**

1. Access ESPHome dashboard (if running on homelab):

   ```bash

   # Not configured by default, add to NixOS config if needed
   # See: https://esphome.io/guides/getting_started_command_line.html

   ```

2. Create new device → Copy Bluetooth proxy YAML from plan Phase 2:

   ```yaml

   substitutions:
     device_name: salon-bluetooth-proxy
     friendly_name: "Salon Bluetooth Proxy"

   esphome:
     name: ${device_name}

   esp32:
     board: esp32-c3-devkitm-1
     framework:
       type: esp-idf

   wifi:
     ssid: !secret wifi_ssid
     password: !secret wifi_password

   api:
   ota:
   logger:

   esp32_ble_tracker:
     scan_parameters:
       active: true

   bluetooth_proxy:
     active: true

   ```

3. Upload via USB or OTA
4. Device appears in HA ESPHome integration

**Pros:**

- Full config customization
- Can add sensors (temp, motion) to same device
- OTA updates

**Cons:**

- Requires ESPHome installation
- More complex for beginners

---

### Method 3: ESPHome CLI (Offline Flashing)

**For air-gapped environments or bulk deployments.**

1. Install ESPHome CLI:

   ```bash

   # NixOS
   nix-shell -p esphome

   # Or use mise (if configured)
   mise use esphome

   ```

2. Create config file: `salon-bluetooth-proxy.yaml` (use YAML from Method 2)

3. Compile firmware:

   ```bash

   esphome compile salon-bluetooth-proxy.yaml

   ```

4. Flash via USB:

   ```bash

   esphome upload salon-bluetooth-proxy.yaml

   ```

5. Monitor logs:

   ```bash

   esphome logs salon-bluetooth-proxy.yaml

   ```

**Pros:**

- Works offline
- Can flash multiple devices with same config

**Cons:**

- Requires local ESPHome installation
- Manual firmware management

---

## Area Assignment (Critical for Bermuda)

After ESP32 adopted in HA:

1. Navigate to **Settings → Devices & Services → ESPHome**
2. Click device (e.g., "Salon Bluetooth Proxy")
3. Click **Settings (gear icon)**
4. **Assign to Area:** Select room (e.g., "Salon")
5. **Area names must match HA areas** used in automations

**Important:**

- Use Polish area names (e.g., "Łazienka", not "Bathroom") if automations use Polish
- Bermuda uses `area_id()` lookups → exact name matching required
- Rename areas in **Settings → Areas** if needed

---

## Placement Best Practices

### Coverage Planning

**Minimum:** 1 proxy per room requiring person tracking (4 proxies for 4 rooms)

**Optimal:** 2-3 proxies per floor for overlapping coverage

**Range:**

- **Ideal:** 5-10m from tracked device
- **Maximum:** ~15m (degrades through walls)
- **Interference:** Avoid near microwave, 2.4GHz router, USB3 devices

### Physical Placement

**Height:** 1-2m above floor (desk/shelf level, not ceiling or floor)

**Line-of-sight:** Clear path to typical person locations (avoid behind metal furniture)

**Power:** Stable USB power (not battery, continuous operation needed)

**Examples:**

- **Salon:** Bookshelf near TV, opposite wall shelf
- **Sypialnia:** Nightstand, dresser
- **Biuro:** Desk edge, wall-mounted near doorway
- **Łazienka:** Vanity countertop (away from water)

---

## Verification Steps

### 1. Check ESP32 Connectivity

**HA Integration:**

- Navigate to **Settings → Devices & Services → ESPHome**
- Device status: **Online** (green check)
- Entities: `bluetooth_proxy_{device}_ble_scanner` present

**Logs:**

```bash

# ESPHome dashboard logs
# Or HA: Settings → System → Logs → Filter: esphome

```

Look for: `BLE tracker initialized`, `Bluetooth proxy started`

### 2. Test BLE Scanning

1. Place iPhone/watch near proxy (~2m)
2. Navigate to **Developer Tools → States**
3. Search: `bluetooth_proxy_`
4. Check `bluetooth_proxy_{device}_ble_scanner` state shows "scanning"
5. Attributes should show detected BLE devices (MACs, RSSI)

### 3. Verify Bermuda Detection

1. Navigate to **Settings → Devices & Services → Bermuda BLE**
2. Click **Configure** → **Diagnostics**
3. Check "BLE Scanners" section:
   - All ESP32 proxies listed
   - RSSI values updating (e.g., `-65 dBm`)
   - Tracked devices (iPhones) visible across multiple proxies

**Good RSSI values:**

- `-40 to -60 dBm`: Excellent (same room)
- `-60 to -75 dBm`: Good (adjacent room)
- `-75 to -85 dBm`: Fair (distant room)
- `< -85 dBm`: Poor (add proxy or reduce interference)

---

## Troubleshooting

### ESP32 Not Discovered in HA

**Symptoms:** Device flashed but doesn't appear in Integrations

**Fixes:**

1. Check WiFi connection: Device LED should stop blinking after 30s
2. Verify same network as HA (not guest WiFi, VLANs may block mDNS)
3. Restart HA: `sudo systemctl restart home-assistant`
4. Manual discovery: Settings → Integrations → Add → ESPHome → Enter IP
5. Check router DHCP leases for ESP32 MAC address

### Poor BLE Range

**Symptoms:** RSSI < -80 dBm despite proximity

**Fixes:**

1. Move proxy closer to typical person locations
2. Remove metal obstacles (appliances, mirrors)
3. Change ESP32 orientation (antenna direction matters)
4. Check for 2.4GHz WiFi congestion (switch WiFi channel)
5. Replace with ESP32-S3 (better antenna design)

### High Power Consumption

**Symptoms:** ESP32 warm to touch, power supply overloaded

**Fixes:**

1. Reduce `scan_parameters.interval` in YAML (default 320ms → 1000ms)
2. Disable WiFi sleep: `power_save_mode: none` (stability over power)
3. Use esp-idf framework (more efficient than Arduino for BLE)
4. Check for defective board (should draw ~80mA at 5V)

### Frequent Disconnections

**Symptoms:** ESP32 goes offline intermittently

**Fixes:**

1. Improve WiFi signal (closer to AP, fewer walls)
2. Disable aggressive power saving: `fast_connect: true` in `wifi:`
3. Set static IP in router DHCP (avoid lease expiration kicks)
4. Update ESPHome firmware (newer versions improve stability)
5. Check power supply (insufficient current causes brownouts)

---

## Related Documentation

- [ESPHome Official Docs](https://esphome.io/) - Full YAML reference
- [Bluetooth Proxy Guide](https://esphome.io/components/bluetooth_proxy.html) - Component details
- [Bermuda Integration](bermuda-ble.md) - Person tracking setup
- [ESPHome Bluetooth Proxies](https://esphome.github.io/bluetooth-proxies/) - Web flasher

---

## Notes

- **OTA Updates:** After initial USB flash, all updates via WiFi (no USB needed)
- **Multiple proxies:** Use unique `device_name` substitution per proxy
- **Security:** ESP32 on trusted WiFi only (BLE scanner exposes nearby devices)
- **Battery devices:** Not recommended (use USB power, continuous scanning drains battery in hours)
- **Firmware updates:** ESPHome auto-updates in HA (check for updates monthly)
