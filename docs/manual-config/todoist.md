# Todoist Integration Setup

## Why Manual Configuration

Todoist requires OAuth authentication via Home Assistant GUI - cannot be configured declaratively.

## Prerequisites

- Todoist account (free or premium)
- Home Assistant accessible via browser

## Setup Steps

### 1. Enable Integration Component

Integration component already enabled in `hosts/homelab/home-assistant/default.nix`:

```nix
# Line ~67
"todoist" # Todo list integration
```

### 2. Add Integration via GUI

1. Open Home Assistant web interface
2. Navigate to **Settings** → **Devices & Services**
3. Click **+ Add Integration** (bottom right)
4. Search for "Todoist"
5. Click **Todoist** in results
6. Click **Authorize** to start OAuth flow
7. Sign in to Todoist account (browser redirect)
8. Grant Home Assistant access to Todoist
9. Return to Home Assistant (auto-redirect)

### 3. Verify Integration

After successful OAuth:

- Integration appears in **Devices & Services** → **Integrations**
- Status: **Configured**
- Entities created for each Todoist list

Check entities:

1. **Settings** → **Devices & Services** → **Entities**
2. Filter by domain: `todo`
3. Look for `todo.inbox`, `todo.*` (based on your Todoist lists)

## Verification

### Via GUI

1. **Settings** → **Devices & Services** → **Entities**
2. Find `todo.inbox` (or your list name)
3. Click entity → View state/attributes
4. State shows number of incomplete tasks

### Via Developer Tools

1. **Developer Tools** → **Services**
2. Service: `todo.add_item`
3. Target: `todo.inbox`
4. Data:
   ```yaml
   item: "Test task from HA"
   ```
5. Click **Call Service**
6. Check Todoist app/web - task should appear

### Via Voice (after completing intents setup)

Test Polish voice commands:

- "Dodaj mleko do inbox" (Add milk to inbox)
- "Pokaż zadania" (Show tasks)
- "Oznacz mleko jako zrobione" (Mark milk as done)

## Troubleshooting

**Integration not appearing:**

- Verify `"todoist"` in extraComponents
- Check HA logs:
  ```bash
  journalctl -u home-assistant | grep -i todoist
  ```
- Restart HA: `sudo systemctl restart home-assistant`

**OAuth fails:**

- Check browser console for errors
- Ensure HA accessible from browser (not localhost-only)
- Try incognito/private window
- Verify Todoist account login works independently

**No entities created:**

- Create at least one list in Todoist first
- Reload integration: **Devices & Services** → Todoist → **⋮** → **Reload**
- Check entity registry: **Developer Tools** → **Statistics** → Domain filter: `todo`

**Tasks not syncing:**

- Check Todoist API status: https://status.todoist.com/
- Verify OAuth token valid: **Devices & Services** → Todoist → **Configure**
- Re-authenticate if needed: **⋮** → **Reauthenticate**

**Voice commands not working:**

- Ensure intents configured (see `hosts/homelab/home-assistant/intents.nix`)
- Verify sentence patterns (see `custom_sentences/pl/intents.yaml`)
- Check HA logs: `journalctl -u home-assistant | grep intent`
- Test via Developer Tools first (bypass voice recognition)

## Available Services

Once configured, Todoist provides these services:

- `todo.add_item` - Add task to list
- `todo.remove_item` - Remove task from list
- `todo.update_item` - Update task (rename, mark complete, etc.)
- `todo.get_items` - Retrieve tasks with status filter

Example automation:

```yaml
action:
  - service: todo.add_item
    target:
      entity_id: todo.inbox
    data:
      item: "Buy groceries"
```

## Related Documentation

- [Home Assistant Todoist Integration](https://www.home-assistant.io/integrations/todoist/)
- [Todoist API Documentation](https://developer.todoist.com/rest/v2/)
- [HA Todo Domain](https://www.home-assistant.io/integrations/todo/)
