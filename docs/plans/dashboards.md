# Home Assistant Dashboard Design Plan

**Date:** 2026-01-06
**Status:** Planning
**Target:** Multiple-dashboard setup with custom cards

## Executive Summary

Implement beautiful, functional HA dashboards using modern best practices:

- **5 specialized dashboards** (main, monitoring, media, mobile, discovery)
- **Custom cards** (Mushroom, Mini Graph, Button Card, card-mod, auto-entities)
- **Responsive design** (desktop + mobile optimized)
- **Areas covered** (living areas, bedrooms)
- **Catppuccin theme** (already installed)

## Research Findings Summary

### Dashboard Architecture (2024-2025)

**View Types:**

- **Sections** (recommended) - Modern grid-based, drag-and-drop, responsive
- **Masonry** - Space-saving, less predictable layout
- **Panel** - Single full-width card (maps, media players)
- **Sidebar** - Two-column desktop, single mobile

**Modern Best Practices:**

- Tile card as default (2024+)
- Grid-based layouts for multi-column sections
- Built-in features (sliders, controls) over separate cards
- Sections view for responsive design

### Top Custom Cards

1. **Mushroom Cards** ⭐ Most popular
   - Zero dependencies, visual editor, minimalistic
   - Clean modern UI without coding
   - Repository: `piitaya/lovelace-mushroom`

2. **Mini Graph Card**
   - Compact sensor history graphs
   - 24h trends, customizable
   - Repository: `kalkih/mini-graph-card`

3. **Button Card** (custom)
   - Advanced customization, templates, state-based styling
   - Repository: `custom-cards/button-card`

4. **card-mod**
   - Custom CSS for any card/global theme styling
   - Repository: `thomasloven/lovelace-card-mod`

5. **auto-entities**
   - Dynamic entity lists with filters
   - Discovery dashboard helper
   - Repository: `thomasloven/lovelace-auto-entities`

## Implementation Plan

### Phase 1: Install Custom Cards (NixOS Declarative)

**File:** `hosts/homelab/home-assistant/default.nix`

#### Step 1.1: Add Custom Card Sources

Add fetchFromGitHub declarations at top of file (with existing `bubbleCardSource`):

```nix
mushroomCardSource = pkgs.fetchFromGitHub {
  owner = "piitaya";
  repo = "lovelace-mushroom";
  # renovate: datasource=github-tags depName=piitaya/lovelace-mushroom
  rev = "v4.1.3";  # Check latest stable release
  hash = "";  # Run nix-prefetch to calculate
};

miniGraphCardSource = pkgs.fetchFromGitHub {
  owner = "kalkih";
  repo = "mini-graph-card";
  # renovate: datasource=github-tags depName=kalkih/mini-graph-card
  rev = "v0.12.1";
  hash = "";
};

buttonCardSource = pkgs.fetchFromGitHub {
  owner = "custom-cards";
  repo = "button-card";
  # renovate: datasource=github-tags depName=custom-cards/button-card
  rev = "v4.1.3";
  hash = "";
};

cardModSource = pkgs.fetchFromGitHub {
  owner = "thomasloven";
  repo = "lovelace-card-mod";
  # renovate: datasource=github-tags depName=thomasloven/lovelace-card-mod
  rev = "3.4.3";
  hash = "";
};

autoEntitiesSource = pkgs.fetchFromGitHub {
  owner = "thomasloven";
  repo = "lovelace-auto-entities";
  # renovate: datasource=github-tags depName=thomasloven/lovelace-auto-entities
  rev = "1.13.0";
  hash = "";
};
```

#### Step 1.2: Add Symlinks in preStart

Merge with existing `systemd.services.home-assistant.preStart`:

```nix
systemd.services.home-assistant.preStart = lib.mkAfter ''
  mkdir -p /var/lib/hass/www/community
  # Existing bubble-card
  ln -sfn ${bubbleCardSource}/dist /var/lib/hass/www/community/bubble-card
  # New cards
  ln -sfn ${mushroomCardSource} /var/lib/hass/www/community/mushroom
  ln -sfn ${miniGraphCardSource}/dist /var/lib/hass/www/community/mini-graph-card
  ln -sfn ${buttonCardSource}/dist /var/lib/hass/www/community/button-card
  ln -sfn ${cardModSource} /var/lib/hass/www/community/card-mod
  ln -sfn ${autoEntitiesSource} /var/lib/hass/www/community/auto-entities
'';
```

#### Step 1.3: Get Latest Stable Releases & Hashes

```bash
# Check latest releases on GitHub
gh repo view piitaya/lovelace-mushroom --json latestRelease
gh repo view kalkih/mini-graph-card --json latestRelease
gh repo view custom-cards/button-card --json latestRelease
gh repo view thomasloven/lovelace-card-mod --json latestRelease
gh repo view thomasloven/lovelace-auto-entities --json latestRelease

# Calculate hashes
nix-prefetch-url --unpack https://github.com/piitaya/lovelace-mushroom/archive/refs/tags/v4.1.3.tar.gz
nix-prefetch-url --unpack https://github.com/kalkih/mini-graph-card/archive/refs/tags/v0.12.1.tar.gz
# ... repeat for each card
```

#### Step 1.4: Deploy Changes

```bash
# Create feature branch
git checkout -b feat/dashboard-custom-cards

# Edit default.nix with sources + hashes
# ...

# Commit
git add hosts/homelab/home-assistant/default.nix
git commit -s -S -m "feat(ha): add custom dashboard cards (Mushroom, Mini Graph, Button, card-mod, auto-entities)"

# Push
git push -u origin feat/dashboard-custom-cards

# Create PR
gh pr create --title "feat(ha): add custom dashboard cards" --body "$(cat <<'EOF'
## Motivation

Setup foundation for beautiful, functional HA dashboards using modern custom cards.

## Implementation information

Added NixOS declarations for 5 custom cards:
- Mushroom Cards (minimalist, most popular)
- Mini Graph Card (sensor trends)
- Button Card (advanced customization)
- card-mod (CSS styling)
- auto-entities (dynamic discovery)

Cards installed via fetchFromGitHub + symlinks to /var/lib/hass/www/community/.
Renovate comments enable automatic version updates.

## Supporting documentation

- [Mushroom Cards](https://github.com/piitaya/lovelace-mushroom)
- [Mini Graph Card](https://github.com/kalkih/mini-graph-card)
- [Button Card](https://github.com/custom-cards/button-card)
- [card-mod](https://github.com/thomasloven/lovelace-card-mod)
- [auto-entities](https://github.com/thomasloven/lovelace-auto-entities)
- HA Dashboard Chapter 1: https://www.home-assistant.io/blog/2024/03/04/dashboard-chapter-1/
EOF
)"

# Merge after CI passes
# ...

# Wait for Comin to deploy to homelab
```

### Phase 2: Register Resources in HA GUI

After rebuild completes on homelab:

**Steps:**

1. Navigate to HA: Settings → Dashboards → Resources
2. Click "+ Add Resource" for each card
3. Enter URL (JavaScript Module type)

**Resource URLs:**

- `/local/community/mushroom/mushroom.js`
- `/local/community/mini-graph-card/mini-graph-card-bundle.js`
- `/local/community/button-card/button-card.js`
- `/local/community/card-mod/card-mod.js`
- `/local/community/auto-entities/auto-entities.js`

**Verification:**

- Check browser console for errors (F12)
- Resources should load without 404s
- Test by creating sample Mushroom card

### Phase 3: Test card-mod with Catppuccin Theme

**Goal:** Verify card-mod works with existing Catppuccin theme

**Test Pattern:**

1. Create test dashboard view
2. Add Mushroom light card
3. Apply card-mod styling:

```yaml
type: custom:mushroom-light-card
entity: light.salon
card_mod:
  style: |
    ha-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.15);
    }
```

1. Verify styling renders correctly
2. Test theme switching (Catppuccin variants)
3. Document working patterns

**If successful:** Proceed to create global theme modifications
**If issues:** Use card-mod per-card basis only

### Phase 4: Create Dashboard Structure

**5 Dashboards to create via HA GUI:**

#### 4.1 Main Control Dashboard

**URL Path:** `main-control`
**Purpose:** Daily controls, lights, climate, scenes
**Target Devices:** Desktop + Mobile
**Sidebar:** ✅ Visible

**View Type:** Sections

**Sections:**

1. **Living Areas**
   - Salon lights (Mushroom light cards)
   - Kitchen lights
   - Climate control (Mushroom climate card)
   - Scene buttons (Button Card)

2. **Bedrooms**
   - Master bedroom lights + climate
   - Guest bedroom controls
   - Scene buttons

**Design:**

- Grid cards for 2-3 column layouts in sections
- Large tap targets (mobile-friendly)
- Quick actions (no deep navigation)

**Card Types:**

- `custom:mushroom-light-card` - Clean light controls
- `custom:mushroom-climate-card` - Thermostat
- `custom:button-card` - Scenes (with templates)
- `tile` - Built-in for covers/switches

#### 4.2 Monitoring Dashboard

**URL Path:** `monitoring`
**Purpose:** Sensor data, trends, system health
**Target Devices:** Desktop primarily
**Sidebar:** ✅ Visible

**View Type:** Sections

**Sections:**

1. **Salon Sensors**
   - Temperature (Mini Graph Card, 24h)
   - Humidity (Mini Graph Card)
   - Power consumption (if available)

2. **Bedroom Sensors**
   - Temperature trends
   - Humidity trends

3. **System Health**
   - HA uptime (Tile card with trend)
   - Network status
   - Disk usage
   - CPU/Memory (if exposed)

**Design:**

- Information density (desktop-focused)
- Mini Graph Card with 24h history ranges
- Tile cards with built-in trend charts (2025.9 feature)
- Group sensors by room/type

**Card Types:**

- `custom:mini-graph-card` - Sensor history
- `tile` - System sensors with trend charts
- `entities` - Compact sensor lists

#### 4.3 Media Dashboard

**URL Path:** `media`
**Purpose:** Audio/video control
**Target Devices:** Desktop + Tablet
**Sidebar:** ✅ Visible

**View Type:** Panel (full-screen)

**Content:**

- Main media player (full-width)
- Mushroom media cards for multi-room audio
- Volume controls
- Source selection
- Playback shortcuts

**Design:**

- Panel view for immersive experience
- Large album art
- Quick volume adjustments
- Room-by-room audio grouping

**Card Types:**

- `media-control` - Built-in full-width player
- `custom:mushroom-media-card` - Room controls
- `custom:button-card` - Preset playlists

#### 4.4 Mobile Dashboard

**URL Path:** `mobile`
**Purpose:** Simplified touch-optimized controls
**Target Devices:** Mobile phone only
**Sidebar:** ❌ Hidden (direct link only)

**View Type:** Sections (single column)

**Sections:**

1. **Quick Controls**
   - Most-used lights (large Mushroom cards)
   - Main climate control
   - Essential scenes

2. **Status**
   - Critical sensors (temperature)
   - Security status

**Design:**

- Single column layout
- Extra-large tap targets
- Minimal scrolling
- Swipe-friendly navigation
- No nested menus

**Card Types:**

- `custom:mushroom-light-card` - Large, touch-friendly
- `custom:mushroom-climate-card` - Simple thermostat
- `custom:button-card` - Large scene buttons

#### 4.5 Discovery Dashboard

**URL Path:** `discovery`
**Purpose:** Auto-generated entity lists, find devices
**Target Devices:** Desktop
**Sidebar:** ✅ Visible

**View Type:** Sections

**Sections:**

1. **All Lights** (auto-entities)
2. **All Sensors** (auto-entities)
3. **All Switches** (auto-entities)
4. **All Climate** (auto-entities)
5. **All Covers** (auto-entities)

**Design:**

- Auto-populated using `custom:auto-entities`
- Filters by domain
- Useful for finding new devices
- No manual maintenance required

**Example auto-entities card:**

```yaml
type: custom:auto-entities
card:
  type: entities
  title: All Lights
filter:
  include:
    - domain: light
  exclude:
    - state: unavailable
sort:
  method: name
```

### Phase 5: Button Card Templates

**Goal:** Create reusable button templates for scenes

**Resources:**

- Base: [creative-button-card-templates](https://github.com/wfurphy/creative-button-card-templates)
- Customize for Polish language
- Adapt to Catppuccin colors

**Example Template:**

```yaml
button_card_templates:
  scene_button:
    show_icon: true
    show_name: true
    styles:
      card:
        - border-radius: 12px
        - background: var(--primary-background-color)
      name:
        - color: var(--primary-text-color)
    tap_action:
      action: call-service
      service: scene.turn_on
      service_data:
        entity_id: "[[entity]]"
```

**Apply to scenes:**

```yaml
type: custom:button-card
entity: scene.dobranoc
template: scene_button
name: Dobranoc
icon: mdi:weather-night
```

### Phase 6: Create Documentation

**File:** `docs/manual-config/dashboards.md`

**Content:**

```markdown
# Dashboard Configuration

## Overview

5 specialized dashboards, all managed via HA GUI.
Custom cards installed declaratively via NixOS.

## Installed Custom Cards

- **Mushroom Cards** (`/local/community/mushroom/mushroom.js`)
  - Minimalist card collection, visual editor
  - Used for: lights, climate, media, clean aesthetics

- **Mini Graph Card** (`/local/community/mini-graph-card/mini-graph-card-bundle.js`)
  - Sensor history graphs with 24h trends
  - Used for: monitoring dashboard, temperature/humidity trends

- **Button Card** (`/local/community/button-card/button-card.js`)
  - Advanced customization, templates
  - Used for: scene buttons, custom controls

- **card-mod** (`/local/community/card-mod/card-mod.js`)
  - CSS styling for cards/themes
  - Used for: Catppuccin customization, rounded corners

- **auto-entities** (`/local/community/auto-entities/auto-entities.js`)
  - Dynamic entity lists with filters
  - Used for: discovery dashboard

## Dashboards

### Main Control (`/lovelace/main-control`)
- **Purpose:** Daily controls, mobile + desktop
- **View:** Sections (responsive grid)
- **Areas:** Living rooms, bedrooms
- **Cards:** Mushroom tiles, Grid layouts, Button Card scenes
- **Sidebar:** Visible

### Monitoring (`/lovelace/monitoring`)
- **Purpose:** Sensor data, trends, system health
- **View:** Sections (information density)
- **Areas:** All rooms + system
- **Cards:** Mini Graph (24h), Tile with trends
- **Sidebar:** Visible

### Media (`/lovelace/media`)
- **Purpose:** Audio/video control
- **View:** Panel (full-screen)
- **Cards:** Media player, Mushroom media, playback controls
- **Sidebar:** Visible

### Mobile (`/lovelace/mobile`)
- **Purpose:** Touch-optimized, phone only
- **View:** Sections (single column)
- **Cards:** Large Mushroom cards, essential controls only
- **Sidebar:** Hidden (direct link: `/lovelace/mobile`)

### Discovery (`/lovelace/discovery`)
- **Purpose:** Auto-generated entity lists, device discovery
- **View:** Sections (auto-entities)
- **Cards:** Filtered by domain (lights, sensors, switches, etc.)
- **Sidebar:** Visible

## Button Card Templates

Located in dashboard YAML config (not file-based).

**Templates:**
- `scene_button` - Rounded, themed scene activation
- `light_preset` - Brightness/color presets
- `room_control` - Multi-action room buttons

**Customization:**
- Polish language
- Catppuccin colors
- Consistent styling

## Maintenance

### Custom Cards
- Updated via Renovate (NixOS declarations in `hosts/homelab/home-assistant/default.nix`)
- Rebuild required after version changes
- Resources auto-available after restart

### Dashboard Layouts
- Edited in HA GUI: Settings → Dashboards
- No declarative config (per project convention)
- Use MCP for testing iterations

### Theme
- Catppuccin installed via NixOS
- card-mod for per-card/global CSS
- Theme variables: `var(--primary-background-color)`, etc.

## Resources

### Official HA Documentation
- [Sections View](https://www.home-assistant.io/dashboards/sections/)
- [Dashboard Chapter 1](https://www.home-assistant.io/blog/2024/03/04/dashboard-chapter-1/)
- [Tile Card](https://www.home-assistant.io/dashboards/tile/)
- [2025.9 Release](https://www.home-assistant.io/blog/2025/09/03/release-20259)

### Custom Cards
- [Mushroom Cards GitHub](https://github.com/piitaya/lovelace-mushroom)
- [Mushroom Guide](https://smarthomescene.com/guides/mushroom-cards-complete-guide-to-a-clean-minimalistic-home-assistant-ui/)
- [Mini Graph Card](https://github.com/kalkih/mini-graph-card)
- [Button Card](https://github.com/custom-cards/button-card)
- [card-mod](https://github.com/thomasloven/lovelace-card-mod)
- [auto-entities](https://github.com/thomasloven/lovelace-auto-entities)

### Community
- [HA Community - Dashboards](https://community.home-assistant.io/c/projects/frontend/34)
- [Dashboard Showcase 2025](https://www.seeedstudio.com/blog/2025/08/27/home-assistant-display-showcase-from-community-designs-to-your-own-setup/)
```

## Implementation Checklist

### Phase 1: Checklist ✅ COMPLETE

- [x] Check latest stable releases on GitHub
- [x] Calculate nix hashes for all 5 cards
- [x] Add fetchFromGitHub sources to `default.nix`
- [x] Add symlinks in preStart
- [x] Create feature branch `feat/dashboard-custom-cards`
- [x] Commit with `-s -S`
- [x] Push and create PR
- [x] Merge after CI passes
- [x] Wait for Comin to deploy

**Status:** Phase 1 completed. Custom cards installed in `hosts/homelab/home-assistant/default.nix` with:

- Mushroom Cards v5.0.9
- Mini Graph Card v0.13.0
- Button Card v7.0.1
- card-mod v4.1.0
- auto-entities v1.16.1

All symlinks configured in preStart. Ready for Phase 2 (GUI configuration).

### Phase 2: Checklist ✅ COMPLETE

- [x] Navigate to Settings → Dashboards → Resources in HA GUI
- [x] Add Mushroom Cards resource
- [x] Add Mini Graph Card resource
- [x] Add Button Card resource
- [x] Add card-mod resource
- [x] Add auto-entities resource
- [x] Verify no console errors (F12)

**Status:** Phase 2 completed. All 5 custom card resources registered via HA GUI:

- Mushroom Cards: `/local/community/mushroom/mushroom.js`
- Mini Graph Card: `/local/community/mini-graph-card/mini-graph-card-bundle.js`
- Button Card: `/local/community/button-card/button-card.js`
- card-mod: `/local/community/card-mod/card-mod.js`
- auto-entities: `/local/community/auto-entities/auto-entities.js`

All resources loaded successfully without console errors. Ready for Phase 3 (card-mod + Catppuccin testing).

### Phase 3: Checklist ✅ COMPLETE

- [x] Create test dashboard view
- [x] Add Mushroom card with card-mod styling
- [x] Test with Catppuccin theme
- [x] Switch theme variants (Mocha, Latte, etc.)
- [x] Document working patterns
- [x] Decide on per-card vs global styling approach

**Status:** Phase 3 completed. Test dashboard verified and removed after successful testing.

**Test Results:**

- Created test dashboard with styled vs unstyled Mushroom cards
- Entity tested: `light.hallway`
- card-mod styling applied: rounded corners + shadow

**card-mod Configuration (Verified Working):**

```yaml
type: custom:mushroom-light-card
entity: light.hallway
card_mod:
  style: |
    ha-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.15);
    }
```

**Findings:**

- ✅ card-mod works with Mushroom cards
- ✅ Compatible with Catppuccin theme
- ✅ CSS styling applies correctly (rounded corners, shadows)
- ✅ No console errors
- ✅ Test dashboard removed after verification

**Recommendation:** Use **per-card styling** approach:

- Apply card-mod selectively for polish
- Catppuccin theme provides base colors
- Per-card styling for rounded corners, shadows, special effects
- Avoid global theme-mod (keep Catppuccin clean)

Ready for Phase 4 (build production dashboards).

### Phase 4: Checklist ✅ COMPLETE

- [x] Create Main Control dashboard (sections view)
  - [x] Living Areas section
  - [x] Bedrooms section
  - [x] Add Mushroom light cards
  - [x] Add climate controls
  - [x] Add scene buttons
- [x] Create Monitoring dashboard (sections view)
  - [x] Salon sensors section (Mini Graph Cards)
  - [x] Bedroom sensors section
  - [x] System health section
- [x] Create Media dashboard (panel view)
  - [x] Full-width media player
  - [x] Mushroom media cards
  - [x] Volume controls
- [x] Create Mobile dashboard (sections, single column)
  - [x] Quick controls section (large cards)
  - [x] Status section (critical info)
  - [x] Hide from sidebar
- [x] Create Discovery dashboard (sections view)
  - [x] All lights (auto-entities)
  - [x] All sensors (auto-entities)
  - [x] All switches (auto-entities)
  - [x] All climate (auto-entities)

**Status:** Phase 4 completed. All 5 production dashboards created via HA MCP:

**1. Main Control (`/lovelace/main-control`):**
- Sections: Living Areas, Bedrooms, Scenes
- Mushroom cards for lights (Kitchen), climate controls (Living Room, Bedroom, Office)
- Air Purifier control (Mushroom fan card)
- Scene buttons (Kitchen Read/Bright, Bathroom Energize/Relax/Neutral, All Off)
- Grid layouts (2 columns) for responsive design
- card-mod styling (rounded corners, shadows)

**2. Monitoring (`/lovelace/monitoring-sensors`):**
- Sections: Living Room Sensors, Bedroom Sensors, Air Quality, System Health
- Mini Graph Cards (24h history, 2 points/hour)
  - Living Room: Temperature, Humidity, Indoor PM2.5, Outdoor PM2.5
  - Bedroom: Temperature, Humidity
  - Air Quality: AQI Index, PM2.5 Outdoor vs Indoor comparison
- System Status entity card (HA status, Comin deployment time, safe to ventilate)

**3. Media (`/lovelace/media-control`):**
- Panel view (full-width)
- Built-in media-control card for TV
- Mushroom media player cards (TV, Voice Assistant speaker)
- Volume controls, playback controls
- card-mod styling

**4. Mobile (`/lovelace/mobile-quick`):**
- Single column sections (touch-optimized)
- Quick Controls: Kitchen/Hallway lights, Living Room climate, All Off button
- Status section: Temperature, Indoor PM2.5, Safe to Ventilate
- Hidden from sidebar (direct link only)
- Large cards with vertical layout

**5. Discovery (`/lovelace/discovery-entities`):**
- Sections: All Lights, All Sensors, All Switches, All Climate, All Binary Sensors
- Auto-entities cards (dynamic population by domain)
- Excludes unavailable/unknown entities
- Sorted alphabetically by name
- Zero maintenance (auto-updates when devices added)

All dashboards use modern 2024+ patterns: sections view, Mushroom cards, Mini Graph cards, card-mod styling, Grid layouts. Ready for Phase 5 (Button Card templates).

### Phase 5: Checklist

- [ ] Review creative-button-card-templates repo
- [ ] Create scene_button template
- [ ] Customize for Polish language
- [ ] Adapt to Catppuccin colors
- [ ] Apply to scene buttons in Main Control
- [ ] Test tap actions

### Phase 6: Checklist

- [ ] Create `docs/manual-config/dashboards.md`
- [ ] Document all 5 dashboards
- [ ] Document custom cards + resource URLs
- [ ] Document Button Card templates
- [ ] Add maintenance notes
- [ ] Add resource links
- [ ] Create feature branch `docs/dashboard-guide`
- [ ] Commit and create PR

### Phase 7: Checklist

- [ ] Test Main Control on desktop
- [ ] Test Main Control on mobile
- [ ] Test Monitoring dashboard (graphs load)
- [ ] Test Media dashboard (playback controls)
- [ ] Test Mobile dashboard on phone (tap targets)
- [ ] Test Discovery dashboard (auto-entities populate)
- [ ] Verify performance (load times, responsiveness)
- [ ] Check for console errors
- [ ] Verify theme consistency across all dashboards

### Phase 8: Checklist

- [ ] Gather feedback from daily use
- [ ] Adjust layouts based on usage patterns
- [ ] Add conditional cards if needed
- [ ] Optimize slow-loading sections
- [ ] Add more Button Card templates as needed
- [ ] Document any issues/workarounds

## Timeline Estimate

**No specific timeline** - implement at own pace, break into smaller tasks as needed.

**Suggested order:**

1. Phase 1 (NixOS changes) - Single PR, foundational
2. Phase 2 (Resources) - Quick GUI task
3. Phase 3 (card-mod test) - Verify compatibility
4. Phase 4 (Dashboards) - Iterative, can spread over time
5. Phase 5 (Templates) - After daily use feedback
6. Phase 6 (Docs) - Parallel with Phase 4/5
7. Phase 7-8 (Testing/Refinement) - Ongoing

## Notes

### Current Project Context

- Dashboard management: GUI (`lovelaceConfigWritable = true`)
- Theme: Catppuccin (already installed)
- Voice commands: Polish (Whisper/Piper)
- Areas: Living areas (Salon, Kitchen) + Bedrooms

### Design Philosophy

- Clean minimalist (Mushroom cards)
- Information density when needed (Monitoring)
- Mobile-friendly (large targets, swipe navigation)
- Discovery-friendly (auto-entities for new devices)

### MCP Integration

Per CLAUDE.md pattern for automations, apply same to dashboards:

1. Design/test in HA GUI (quick iteration)
2. Verify with real devices (mobile + desktop)
3. Keep in GUI (dashboards not declarative)
4. Document custom cards in Nix (reproducibility)

### Resources

All research findings documented in this plan.
Original research: 2026-01-06 (66K token Task agent output)

## References

### Research Sources

- [HA Dashboard Chapter 1: Drag-and-drop & Sections](https://www.home-assistant.io/blog/2024/03/04/dashboard-chapter-1/)
- [Dashboard Chapter 2: Redesigning Cards](https://www.home-assistant.io/blog/2024/07/26/dashboard-chapter-2/)
- [2025.9 Release: Tile Card Features](https://www.home-assistant.io/blog/2025/09/03/release-20259)
- [Mushroom Cards Guide](https://smarthomescene.com/guides/mushroom-cards-complete-guide-to-a-clean-minimalistic-home-assistant-ui/)
- [Dashboard Showcase 2025](https://www.seeedstudio.com/blog/2025/08/27/home-assistant-display-showcase-from-community-designs-to-your-own-setup/)

### GitHub Repositories

- [piitaya/lovelace-mushroom](https://github.com/piitaya/lovelace-mushroom)
- [kalkih/mini-graph-card](https://github.com/kalkih/mini-graph-card)
- [custom-cards/button-card](https://github.com/custom-cards/button-card)
- [thomasloven/lovelace-card-mod](https://github.com/thomasloven/lovelace-card-mod)
- [thomasloven/lovelace-auto-entities](https://github.com/thomasloven/lovelace-auto-entities)
- [wfurphy/creative-button-card-templates](https://github.com/wfurphy/creative-button-card-templates)
