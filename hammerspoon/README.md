# Hammerspoon Scripts

Hammerspoon scripts for macOS integration with Home Assistant.

## Zoom Smart Plug Controller

Automatically controls office smart plug based on Zoom meeting state.

**What it does:**
- Monitors Zoom meeting status
- Turns ON office smart plug when meeting starts
- Turns OFF when meeting ends

**Requirements:**
- [Hammerspoon](https://www.hammerspoon.org/) installed on macOS
- Zoom client installed
- Network access to Home Assistant (homeassistant.local:8123)

**Installation:**

1. **Install Hammerspoon** (if not already):
   ```bash
   brew install --cask hammerspoon
   ```

2. **Copy script to Hammerspoon config directory:**
   ```bash
   mkdir -p ~/.hammerspoon
   cp zoom-smart-plug.lua ~/.hammerspoon/
   ```

3. **Add to init.lua:**
   ```bash
   echo 'require("zoom-smart-plug")' >> ~/.hammerspoon/init.lua
   ```

4. **Reload Hammerspoon config:**
   - Click Hammerspoon icon in menu bar
   - Select "Reload Config"

**Configuration:**

Edit `~/.hammerspoon/zoom-smart-plug.lua` if needed:

```lua
local config = {
    -- Update webhook_id to match your Home Assistant installation
    ha_webhook_url = "http://homeassistant.local:8123/api/webhook/zoom_meeting_7cca0951_0a49_4bdc_a8d3_cc46ea7d8980",
    check_interval = 5,  -- seconds
    zoom_process = "zoom.us",
}
```

**Verification:**

1. Start Hammerspoon and reload config
2. Check Console.app for Hammerspoon logs
3. Join test Zoom meeting
4. Office smart plug should turn ON
5. End meeting, plug should turn OFF

**Troubleshooting:**

- **Script not loading:** Check `~/.hammerspoon/init.lua` for syntax errors
- **Webhook fails:** Verify HA accessible at homeassistant.local:8123 (check mDNS resolution)
- **Meeting not detected:** Check Hammerspoon console for logs (`hs.console()`)
- **Permissions:** Grant Hammerspoon accessibility permissions in System Preferences

**Home Assistant Side:**

Webhook automation deployed via NixOS in `hosts/homelab/home-assistant/areas/office.nix`
