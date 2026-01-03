# Telegram Integration Setup

## Why Manual Configuration

Telegram requires bot token and chat ID from Telegram's BotFather - cannot be auto-generated.

## Prerequisites

- Telegram account
- SOPS secrets configured (see `docs/SOPS_SETUP.md`)

## Setup Steps

### 1. Create Bot

1. Open Telegram, search for `@BotFather`
2. Send `/newbot`
3. Follow prompts:
   - Bot name: `Klaudiusz Smart Home` (or your choice)
   - Username: must end in `bot` (e.g., `klaudiusz_home_bot`)
4. Copy bot token (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 2. Get Chat ID

1. Search for your new bot in Telegram
2. Send any message to bot (e.g., `/start`)
3. Get chat ID via browser:
   ```bash
   # Replace TOKEN with your bot token
   curl https://api.telegram.org/botTOKEN/getUpdates
   ```
4. Find `"chat":{"id":123456789}` in response
5. Copy chat ID (numeric value)

### 3. Update Secrets

```bash
# Edit encrypted secrets
sops secrets/secrets.yaml

# Add/update:
telegram_bot_token: "YOUR_BOT_TOKEN"
telegram_chat_id: "YOUR_CHAT_ID"
```

### 4. Enable Integration

Uncomment in `hosts/homelab/home-assistant/default.nix`:

```nix
# Line ~64
"telegram_bot"

# Lines ~155-161
telegram_bot = [
  {
    platform = "polling";
    api_key = "!secret telegram_bot_token";
    allowed_chat_ids = ["!secret telegram_chat_id"];
  }
];

# Lines ~164-170
notify = [
  {
    platform = "telegram";
    name = "telegram";
    chat_id = "!secret telegram_chat_id";
  }
];
```

### 5. Deploy

```bash
# Commit changes
git add .
git commit -s -S -m "feat: enable Telegram notifications"
git push

# Wait for CI + Comin (~60s)
# Or manual: nixos-rebuild switch --flake .#homelab
```

### 6. Enable Automations (Optional)

Uncomment notify actions in `hosts/homelab/home-assistant/automations.nix`:
- Startup notification
- System alerts (CPU, memory, disk, temperature)

## Verification

1. Check bot connected:
   ```bash
   journalctl -u home-assistant | grep -i telegram
   ```
   Look for: `Telegram bot polling started`

2. Test notification in HA:
   - Developer Tools → Services
   - Service: `notify.telegram`
   - Data: `{"message": "Test from HA"}`
   - Check Telegram for message

## Troubleshooting

**Bot doesn't respond:**
- Verify token with `getMe`:
  ```bash
  curl https://api.telegram.org/botTOKEN/getMe
  ```
- Check `allowed_chat_ids` matches your chat ID

**Notifications not received:**
- Send message to bot first (activates chat)
- Check HA logs for errors
- Verify secrets mounted: `cat /run/secrets/telegram-bot-token`

**Wrong chat ID:**
- Send new message to bot
- Run `getUpdates` again
- Look for your username in response

## Related Documentation

- [Telegram Bot Integration](https://www.home-assistant.io/integrations/telegram_bot/)
- [Telegram Notify Platform](https://www.home-assistant.io/integrations/telegram/)
- [BotFather Commands](https://core.telegram.org/bots#6-botfather)
