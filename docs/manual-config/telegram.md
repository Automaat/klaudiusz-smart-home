# Telegram Integration Setup

## Why Manual Configuration

As of Home Assistant 2025.12.0, Telegram bot must be configured via UI - YAML configuration deprecated.

## Prerequisites

- Telegram account
- SOPS secrets configured (bot token stored in secrets.yaml)

## Setup Steps

### 1. Create Bot (If Not Already Done)

1. Open Telegram, search for `@BotFather`
2. Send `/newbot`
3. Follow prompts:
   - Bot name: `Klaudiusz Smart Home` (or your choice)
   - Username: must end in `bot` (e.g., `klaudiusz_home_bot`)
4. Copy bot token (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

**Current bot:** @klaudiusz_home_bot (token stored in secrets.yaml)

### 2. Get Chat ID (If Not Already Done)

1. Search for your bot in Telegram
2. Send any message (e.g., `/start`)
3. Get chat ID:

   ```bash
   # Replace TOKEN with bot token from secrets
   TOKEN=$(sops -d secrets/secrets.yaml | grep telegram-bot-token | cut -d: -f2- | tr -d ' "')
   curl -s https://api.telegram.org/bot${TOKEN}/getUpdates | jq '.result[0].message.chat.id'
   ```

4. Copy chat ID (numeric value)

**Current chat ID:** 8508480746 (stored in secrets.yaml)

### 3. Add Integration via UI

**IMPORTANT:** This must be done AFTER deploying NixOS config (telegram_bot component enabled).

1. Go to Settings → Devices & Services
2. Click "+ Add Integration"
3. Search for "Telegram Bot"
4. Select "Telegram broadcast" (for receiving commands) or "Telegram polling" (simpler)
5. Enter bot token from secrets.yaml:

   ```bash
   # Get token
   sops -d secrets/secrets.yaml | grep telegram-bot-token
   ```

6. Enter allowed chat IDs: `8508480746` (or your chat ID)
7. Click "Submit"

### 4. Add Notifier via UI

1. Settings → Devices & Services → Telegram Bot integration
2. Click "Configure"
3. Click "+ Add Notifier"
4. Name: `telegram`
5. Chat ID: `8508480746` (or your chat ID)
6. Click "Submit"

Creates `notify.telegram` service automatically.

### 5. Enable Automations (Optional)

Uncomment notify actions in `hosts/homelab/home-assistant/automations.nix` and `monitoring.nix`:

- Startup notification
- System alerts (CPU, memory, disk, temperature)

## Verification

1. Test notification:
   - Developer Tools → Services → Actions
   - Action: `notify.send_message`
   - Target: `notify.telegram`
   - Data: `{"message": "Test from HA"}`
   - Check Telegram for message

2. Check integration status:
   - Settings → Devices & Services
   - Look for "Telegram Bot" with green status
   - Verify notify entity exists: `notify.telegram`

## Troubleshooting

**Integration won't add:**

- Verify bot token:
  ```bash
  TOKEN=$(sops -d secrets/secrets.yaml | grep telegram-bot-token | cut -d: -f2- | tr -d ' "')
  curl -s https://api.telegram.org/bot${TOKEN}/getMe | jq .
  ```
- Ensure `telegram_bot` in extraComponents (default.nix:64)
- Restart HA if just enabled: `sudo systemctl restart home-assistant`

**Notifications not received:**

- Send message to bot first (activates chat)
- Verify chat ID matches in notifier config
- Check HA logs: `journalctl -u home-assistant | grep -i telegram`

**Wrong chat ID:**

- Send new message to bot
- Run getUpdates command from step 2
- Look for your username in response

## Migration from YAML (2025.12.0+)

Old YAML config (deprecated):
```nix
telegram_bot = [{ platform = "polling"; api_key = "!secret ..."; }];
notify = [{ platform = "telegram"; ... }];
```

**Migration steps:**
1. Remove YAML config from default.nix (already done)
2. Deploy NixOS config
3. Follow "Add Integration via UI" steps above

## Notify Service Migration (2026.5.0+)

The `notify.telegram` service is deprecated. Use `notify.send_message` action with notify entities instead.

**Old format (deprecated):**
```nix
{
  service = "notify.telegram";
  data = {
    message = "Test message";
  };
}
```

**New format:**
```nix
{
  action = "notify.send_message";
  target.entity_id = "notify.telegram";
  data = {
    message = "Test message";
  };
}
```

**Notes:**
- Notify entity created automatically when adding notifier via UI
- Entity ID format: `notify.{notifier_name}` (e.g., `notify.telegram` if named "telegram")
- All automations in this repo already use new format
- Migration complete - ready for HA 2026.5.0+

## Related Documentation

- [Telegram Bot Integration](https://www.home-assistant.io/integrations/telegram_bot/)
- [Telegram Notify Platform](https://www.home-assistant.io/integrations/telegram/)
- [Notifier Migration](https://www.home-assistant.io/integrations/telegram_bot#notifiers)
- [Migration PR #144617](https://github.com/home-assistant/core/pull/144617)
