# Custom Conversation (Fallback Agent)

**Why manual?** Custom Conversation is installed declaratively via Nix, but the
agent configuration must be done through the Home Assistant UI. Each conversation
agent and its fallback behavior must be configured through the GUI setup wizard.

**When to do this:** When you want automatic fallback from local intent matching
to LLM-based conversation agents (OpenAI, Ollama, etc.) for unrecognized commands.

## Prerequisites

- Custom Conversation installed declaratively (already configured in Nix)
- Optional: OpenAI API key or local LLM (Ollama) for fallback agent
- Understanding of conversation agents (local intents vs. LLM)

## Configuration

### 1. Add Custom Conversation Integration

1. Navigate to **Settings** → **Devices & Services**
2. Click **+ ADD INTEGRATION** (bottom-right)
3. Search for **"Custom Conversation"**
4. Click to start configuration wizard

### 2. Configure Integration

**Basic Configuration:**

- **Name**: Descriptive name for the agent (e.g., "Fallback Conversation")
  - This creates conversation agent: `conversation.custom_conversation`
- **Primary Agent**: Select built-in Home Assistant conversation agent
  - Handles local intents (fast, free, offline)
- **Fallback Agent**: Select LLM agent (OpenAI, Ollama, etc.)
  - Handles complex queries when local intents don't match

**Advanced Options:**

- **LLM Provider Fallback**: Optional secondary LLM for quota exhaustion
  - Primary: Free tier LLM (e.g., OpenAI free quota)
  - Secondary: Paid LLM (e.g., OpenAI paid tier)
- **Intent Handling**: Configure which intents go to which agent
- **Prompt Customization**: Fine-tune LLM prompts (optional)

Click **Submit** to create the conversation agent.

### 3. Assign to Voice Assistant

1. Navigate to **Settings** → **Voice Assistants**
2. Select your voice assistant (or create new one)
3. Click **⚙️** (settings icon)
4. **Conversation Agent**: Select "Fallback Conversation" (or your chosen name)
5. Click **Save**

## How Fallback Works

**Request Flow:**

1. Voice input → Speech-to-Text (Whisper)
2. Text → Custom Conversation agent
3. **Primary Agent** (local intents) tries to match
   - ✅ Match found → Fast local response
   - ❌ No match → Route to **Fallback Agent** (LLM)
4. Fallback Agent processes complex query
5. Response → Text-to-Speech (Piper)

**Benefits:**

- Fast responses for common commands (lights, climate, etc.)
- Natural language for complex queries
- Cost optimization (local first, LLM only when needed)
- Offline fallback for critical commands

## Verify Integration

**Check Custom Conversation is working:**

1. **Settings** → **Devices & Services** → Find Custom Conversation
2. Click integration → Verify primary and fallback agents configured
3. Test voice command: "Włącz światło salon" (should use local intent)
4. Test complex query: "Co to jest fotosynteza?" (should use LLM fallback)

**Check logs for agent selection:**

```bash
ssh homelab "journalctl -u home-assistant | grep -i 'custom_conversation'"
```

Look for log entries showing which agent handled each request.

## Testing Fallback Behavior

**Local Intent (Primary Agent):**

Test with known commands that have local intents defined:

- "Włącz światło salon"
- "Jaka temperatura w sypialni?"
- "Która godzina?"

Expected: Fast response, no LLM API call.

**LLM Fallback (Fallback Agent):**

Test with queries outside local intents:

- "Wyjaśnij mi jak działa fotosynteza"
- "Co poradzisz na nudność?"
- "Jaka jest stolica Francji?"

Expected: Slower response, LLM processes query.

**Verify in logs:**

```bash
# Check for LLM API calls
ssh homelab "journalctl -u home-assistant | grep -E 'openai|ollama'"
```

## Troubleshooting

**Fallback not triggering (always uses primary):**

- Verify fallback agent is configured in integration settings
- Check primary agent is set to Home Assistant (not LLM)
- Review Custom Conversation logs for error messages
- Ensure LLM agent is properly configured (API key, endpoint)

**All queries going to LLM (no local matching):**

- Verify primary agent is "Home Assistant" not an LLM
- Check local intents are defined in `intents.nix`
- Review conversation logs: **Settings** → **System** → **Logs** → Filter "conversation"

**LLM quota exhausted:**

- Configure LLM provider fallback (secondary paid LLM)
- Add rate limiting via automation
- Consider free local LLM (Ollama) as fallback

**Integration not available after Nix rebuild:**

- Custom Conversation is installed declaratively via symlink
- Check symlink exists: `ssh homelab "ls -la /var/lib/hass/custom_components/custom_conversation"`
- Verify HA recognized the component:
  `ssh homelab "journalctl -u home-assistant | grep custom_conversation"`
- Restart Home Assistant: `ssh homelab "sudo systemctl restart home-assistant"`

## Cost Control

**Monitor LLM usage:**

Create automation to track OpenAI API calls and warn when quota approaching:

```yaml
automation:
  - id: openai_usage_warning
    alias: "Voice - OpenAI Usage Warning"
    trigger:
      - platform: state
        entity_id: counter.openai_daily_calls
    condition:
      - condition: template
        value_template: "{{ states('counter.openai_daily_calls') | int > 50 }}"
    action:
      - service: notify.telegram
        data:
          message: "OpenAI usage high: {{ states('counter.openai_daily_calls') }} calls today"
```

**Rate limiting strategy:**

- Limit LLM calls per hour via automation
- Use GPT-3.5-turbo for fallback (cheaper than GPT-4)
- Consider local LLM (Ollama + Deepseek) for unlimited free queries

## Related Documentation

- [Custom Conversation GitHub](https://github.com/michelle-avery/custom-conversation)
- [Home Assistant Conversation Integration](https://www.home-assistant.io/integrations/conversation/)
- [OpenAI Conversation Integration](https://www.home-assistant.io/integrations/openai_conversation/)
- [Voice Assistant Setup](voice-assistant-preview.md)
