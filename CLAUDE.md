# Klaudiusz Smart Home

## Overview

NixOS-based smart home with Home Assistant, Polish voice commands (Whisper/Piper), GitOps via Comin.

- **Hardware:** Blackview MP60 mini PC
- **Stack:** NixOS, Flakes, Home Assistant, Wyoming (faster-whisper, piper)
- **Language:** Polish (pl)

## Hardware Specifications

**Model:** Blackview MP60 mini PC

- **CPU:** Intel Celeron N5095 (quad-core, up to 2.9 GHz)
- **RAM:** 16GB DDR4
- **Storage:** 512GB M.2 SSD (expandable to 2TB)
- **Network:**
  - Gigabit Ethernet (1000Mbps)
  - Dual-band WiFi (2.4G + 5G, 802.11ac)
  - Bluetooth 4.2
- **Ports:** 2x USB 3.0, 2x USB 2.0, 2x HDMI
- **Graphics:** Intel UHD (4K support)
- **Boot:** F7/F12 for boot menu
- **Original OS:** Windows 11 Pro (replaced with NixOS)

### Hardware Considerations

- Disk device: likely `/dev/nvme0n1` (M.2 SSD) or `/dev/sda` (check with `lsblk`)
- WiFi/Bluetooth available but ethernet recommended for stability
- 16GB RAM sufficient for HA + Whisper + Piper + Grafana + Prometheus
- 512GB ample for OS + Docker volumes + backups

## Project Structure

```text
flake.nix                           # Entry point, Comin GitOps
hosts/homelab/
├── default.nix                     # System config
├── hardware-configuration.nix      # Generated, machine-specific
└── home-assistant/
    ├── default.nix                 # HA + voice services
    ├── intents.nix                 # Voice command handlers
    └── automations.nix             # Automations, helpers, scripts
custom_sentences/pl/                # Polish voice patterns
docs/manual-config/                 # GUI configuration steps (per integration)
```

## Manual Configuration

Some HA features cannot be configured declaratively via NixOS and require GUI setup.

**When manual GUI steps are needed:**

- Create separate file in `docs/manual-config/{integration-name}.md`
- Use existing files as template
- Include:
  - Why manual configuration is needed
  - When to perform setup
  - Step-by-step instructions
  - Verification steps
  - Troubleshooting (if applicable)
  - Related documentation links
- Update `docs/manual-config/README.md` with link to new file

## Development Workflow

### GitOps Flow

```text
Edit locally → Push to main → CI tests → Production branch updates → Comin pulls (~60s) → NixOS rebuilds
```

**CI Gating:**

- Comin pulls from `production` branch (not `main`)
- `production` only updates when CI passes (static + integration tests)
- Workflow auto-pushes main → production on success
- Prevents broken configs from deploying to homelab

### Before Changes

1. ASK clarifying questions (what devices? what behavior?)
2. Check existing patterns in codebase
3. Plan changes, get approval for architecture changes
4. Implement incrementally

### Testing

- Rebuild locally: `nixos-rebuild build --flake .#homelab`
- Test on device: `nixos-rebuild test --flake .#homelab`
- Check services: `systemctl status home-assistant`

### Automation Development with MCP

**Fast iteration workflow (requires HA MCP server):**

1. Create/test automation via MCP → HA GUI
2. Verify works with real devices/sensors
3. Port working automation to automations.nix
4. Delete GUI version
5. Rebuild and verify declarative version

**Benefits:**

- No rebuild cycles during experimentation
- Test with actual hardware states
- Declarative Nix only for proven automations

**Requirements:**

- HA MCP server configured
- Access token set up
- MCP tools available in Claude Code

## NixOS Conventions

### Module Organization

- One concern per file (intents.nix, automations.nix)
- Use `imports` for composition
- Comments use `# ===` section headers

### Service Config Pattern

```nix
services.example = {
  enable = true;
  settings = { ... };
};
```

### NixOS NEVER

- Hardcode secrets (use sops-nix or agenix)
- Modify hardware-configuration.nix manually
- Use `with pkgs;` in module scope
- Add unused extraComponents

### NixOS ALWAYS

- Pin nixpkgs via flake.lock
- Use `lib.mkDefault` for overridable values
- Group related options with comments
- Test rebuild before push

## Home Assistant Patterns

### Declarative vs GUI

| In Nix (Git)                   | In GUI            |
| ------------------------------ | ----------------- |
| Intents, core automations      | Dashboards        |
| Template sensors               | Quick experiments |
| Critical security automations  | Device tweaks     |
| Input helpers                  | Per-device config |

### Intent Script Pattern

```nix
IntentName = {
  speech.text = "Response with {{ slots.name }}";
  action = [{
    service = "domain.action";
    target.entity_id = "domain.{{ slots.name | lower | replace(' ', '_') }}";
  }];
};
```

### Automation Pattern

```nix
{
  id = "unique_snake_case";
  alias = "Category - Description";
  trigger = [{ platform = "..."; }];
  condition = [{ condition = "..."; }];  # Optional
  action = [{ service = "..."; }];
}
```

### Polish Voice Commands

- Use both formal/informal: `(włącz|zapal)`
- Add skip words: `proszę`, `może`, `mi`
- Template: `"(verb1|verb2) [optional] {slot}"`
- Test with: "Która godzina", "Włącz salon"

### Writing Performant Voice Intents

**Performance Model:**

- Hassil template matcher (not ML), first-match greedy algorithm
- Fast rejection via `required_keywords` (check before pattern expansion)
- Pattern expansion cost: alternations multiplicative, optionals exponential (2^n), permutations factorial (n!)

**Performance Rules:**

- **ALWAYS** add `required_keywords` to every intent for fast rejection
- **NEVER** use optionals for skip_words (`[mi]`, `[no]`, `[może]`, `[proszę]`)
- **LIMIT** permutations to 2-4 items max (factorial growth)
- **PREFER** multiple simple patterns over one complex pattern
- **ORDER** patterns by frequency (most common first)

**Pattern Complexity:**

```yaml
# ❌ BAD: 2^3 = 8 expansions (skip_words as optionals)
"włącz [mi] [no] [może] światło"

# ✅ GOOD: 1 expansion (skip_words auto-ignored)
"włącz światło"

# ❌ BAD: 5! = 120 permutations
"(a; b; c; d; e)"

# ✅ GOOD: Split into separate patterns
"(a|b) followed by (c|d|e)"
```

**Polish Inflection Handling:**

- Entity/area names must use base forms (nominative case) in HA GUI
- Inflected forms DON'T work: `"w Łazience"` ❌ fails
- Workaround: add inflected forms to `area_names` list in sentences YAML
- Add GUI aliases for natural speech variations

**Required Keywords Pattern:**

```yaml
IntentName:
  data:
    - required_keywords: [verb1, verb2, noun1, noun2]  # Fast path: check first
      sentences:
        - "(verb1|verb2) {slot}"
        - "noun1 (verb1|verb2)"
```

### Zigbee Configuration (ZHA)

**Device Setup:**

- ZHA integration enabled declaratively
- Persistent device: `/dev/zigbee` via udev
- Database: `/var/lib/hass/zigbee.db`
- User: hass in dialout group
- Manual setup wizard required (see docs/manual-config/zha.md)

**Device Naming:**

- Use Polish area names via GUI
- Format: `{area} - {function}`
- Example: `Salon - Główne światło`
- Areas auto-work with voice commands

### Home Assistant NEVER

- Duplicate intents between Nix and GUI
- Hardcode entity IDs that don't exist
- Create automations without unique `id`
- Use complex Jinja2 in speech.text

### Home Assistant ALWAYS

- Use Polish responses in speech.text
- Normalize entity names: `lower | replace(' ', '_')`
- Group related intents (lights, climate, scenes)
- Add fallback for unknown commands

## Anti-Patterns to AVOID

### Over-Engineering

- ❌ Abstract patterns used once
- ❌ Complex conditionals for simple automations
- ❌ Wrapper modules for single services
- ❌ Dynamic entity discovery (keep explicit)

### Configuration Drift

- ❌ Mix declarative + GUI for same automation
- ❌ Edit /var/lib/hass directly
- ❌ Add components without using them
- ❌ Uncomment optional services "just in case"

### Voice Commands

- ❌ Long sentences (keep <5 words)
- ❌ Ambiguous slot names
- ❌ Missing Polish alternatives (włącz vs zapal)
- ❌ Complex actions in single intent

## Code Generation Rules

### Code Generation ALWAYS

- Read existing patterns before writing
- Incremental changes (one intent/automation at a time)
- Complete, working code (no placeholders)
- Test rebuild after each change

### Code Generation NEVER

- Generate entire files from scratch
- Add services without enabling them
- Create helpers without using them
- Skip the Nix syntax check

### Incremental Steps

1. Add one intent/automation
2. Rebuild and test
3. Add Polish sentences
4. Test voice command
5. Commit

## Hardware Integrations

### Zigbee (ZHA)

**Setup pattern:**

```nix
# Enable component
extraComponents = [ "zha" ];

# Configure
services.home-assistant.config.zha = {
  database_path = "/var/lib/hass/zigbee.db";
};

# Device access
users.users.hass.extraGroups = ["dialout"];

# Persistent symlink + auto-start Home Assistant when dongle appears
services.udev.extraRules = ''
  SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="831a", \
    SYMLINK+="zigbee", TAG+="systemd", ENV{SYSTEMD_WANTS}="home-assistant.service"
'';
```

**Connect ZBT-2 IDs:**

- idVendor: `303a` (Espressif ESP32)
- idProduct: `831a`

**Device Naming:**

- Use Polish area names
- Format: `{area} - {function}`
- Example: `Salon - Główne światło`
- Areas auto-work with voice commands

**Troubleshooting:**

1. Check device: `ls -la /dev/zigbee`
2. Check USB: `lsusb | grep 303a:831a`
3. Check logs: `journalctl -u home-assistant | grep -i zha`
4. Verify permissions: user in dialout group

## Remote Access

### SSH to Homelab

```bash
# Connect to homelab server
ssh homelab

# Connection details (from ~/.ssh/config):
# - Hostname: 192.168.0.241
# - User: admin
# - Key: ~/.ssh/id_ed25519_homelab
```

## Common Commands

### NixOS

```bash
# Rebuild
sudo nixos-rebuild switch --flake /etc/nixos#homelab
sudo nixos-rebuild test --flake /etc/nixos#homelab
sudo nixos-rebuild build --flake /etc/nixos#homelab

# Flake
nix flake check
nix flake update
```

### Services

```bash
systemctl status home-assistant
systemctl status wyoming-faster-whisper-default
systemctl status wyoming-piper-default
systemctl status comin

journalctl -u home-assistant -f
journalctl -u comin -f
```

### Home Assistant

```bash
# Restart
sudo systemctl restart home-assistant

# Config check
ha core check

# Logs
tail -f /var/lib/hass/home-assistant.log
```

## Troubleshooting

### CI Integration Test Failures

1. Go to failed GitHub Actions run
2. Download `integration-test-logs` artifact (retained 30 days)
3. Extract and review full test output
4. Check for Python import errors, service start failures, VM issues

### Rebuild Fails

1. Check syntax: `nix flake check`
2. Read error message (usually shows file:line)
3. Common: missing semicolon, unclosed brace, wrong attribute name

### Voice Not Working

1. Check services: `systemctl status wyoming-*`
2. Test Whisper: port 10300
3. Test Piper: port 10200
4. Check HA Voice Assistant config in UI

### Intent Not Matching

1. Check custom_sentences/pl/*.yaml syntax
2. Verify intent name matches in intents.nix
3. Check HA logs for intent errors
4. Test with exact phrase first

### Comin Not Pulling

1. Check status: `systemctl status comin`
2. Verify git URL in config
3. Check network/firewall
4. Manual pull: `cd /etc/nixos && git pull`
