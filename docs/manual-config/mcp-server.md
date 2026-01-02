# MCP Server Integration (Claude Code)

**Why manual?** Long-lived access tokens must be created through the UI for security.
Cannot be generated or stored declaratively in Nix configuration.

**When to do this:** To enable Claude Code to control Home Assistant via Model Context Protocol.
Required for AI-powered smart home control and debugging.

## Long-Lived Access Token Setup

**1. Create token:**

1. Open Home Assistant UI
2. Click your **user profile** (bottom-left)
3. Scroll to **Long-Lived Access Tokens** section
4. Click **CREATE TOKEN**
5. Enter token name: `Claude Code MCP`
6. Click **OK**
7. **Copy token immediately** (only shown once)
8. Store securely for step 2

**2. Configure token in repository:**

Token stored in `.claude/config.json` (local to this repo):

```bash
# After copying token from HA, update config:
# Edit .claude/config.json and replace <YOUR_TOKEN_HERE>
```

**3. Verify access:**

```bash
# Test API access with token
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://192.168.0.241:8123/api/ | jq .message
```

Expected output: `"API running."`

## Notes

- Token expiration: **None** (permanent)
- MCP server: `homeassistant-ai/ha-mcp` (82 tools)
- Config location: `.claude/config.json` in repo (not global)
- Restart Claude Code after token update
- Test: "Show my Home Assistant overview"

## Security

- Token grants full API access - protect like password
- Never commit token to git (excluded via .gitignore)
- Revoke via **Settings** → **Profile** → **Long-Lived Access Tokens** if compromised

## Related Documentation

- [Home Assistant Authentication](https://www.home-assistant.io/docs/authentication/)
- [homeassistant-ai/ha-mcp GitHub](https://github.com/homeassistant-ai/ha-mcp)
