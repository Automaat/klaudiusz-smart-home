# Starting Setup Plan - Klaudiusz Smart Home

## Decisions Made

- **Remote access:** Tailscale
- **Backup destination:** NFS (setup later)
- **Unused helpers:** Keep (implement automations)
- **Database:** Migrate to PostgreSQL
- **Wake word:** Yes, enable openwakeword

## Current State

### ✅ Working

- Home Assistant + Polish voice (Whisper/Piper)
- GitOps via Comin
- 19 voice intents, 2 scripts, basic automations
- NixOS 24.11, CI pipeline with tests
- Firewall configured (ports 22, 8123, 10200, 10300, 3000)
- Prometheus + Grafana monitoring (15d retention, node_exporter, HA metrics)
- Service auto-restart on failure (HA, Whisper, Piper) + HA watchdog

### ⚠️ Broken/Incomplete

- [x] Template sensor references non-existent `sensor.last_boot` (fixed in PR #11)
- [x] Scripts reference missing entities - fixed by removing/commenting placeholders (PR #16)
- [x] Input helpers - kept for future use, automations commented out (PR #16)
- [ ] SSH keys placeholder
- [x] Comin repo URL configured

## Priority 1: Critical Gaps

### 1. Backup/Recovery

**Status:** ❌ Missing entirely

- [ ] Automated HA database backups
- [ ] Configuration backups
- [ ] NFS storage setup (deferred)
- [ ] Restore procedure documented
- [ ] Temporary: local backups with Restic

**Implementation:**

- Restic + systemd timer (local initially)
- Daily backups to /backup or external USB
- Keep: 7 daily, 4 weekly, 6 monthly
- NFS migration when ready

### 2. Monitoring & Health

**Status:** ✅ Complete

- [x] System resource tracking (CPU, RAM, disk)
- [x] Service health checks (HA, Whisper, Piper)
- [x] Disk space alerts (warn 80%, critical 90%)
- [x] Availability monitoring

**Implementation:**

- HA System Monitor integration
- Template sensors for service status
- Automations for critical alerts
- systemd email alerts for service failures

### 3. Security Hardening

**Status:** ✅ Complete (SSH keys still placeholder)

- [ ] Configure SSH authorized_keys
- [x] Configure Comin repository URL
- [x] fail2ban for SSH
- [x] Bind Wyoming services to localhost (currently 0.0.0.0)
- [x] Tailscale setup for remote access
- [ ] fail2ban for Home Assistant (lower priority with Tailscale)

**Implementation:**

- Add SSH keys to NixOS config
- Set actual git repo in Comin
- NixOS fail2ban service
- Restrict Wyoming to 127.0.0.1
- services.tailscale.enable = true

### 4. Maintenance Automation

**Status:** ✅ Complete (except backup & reboot notifications)

- [x] Auto-restart on service failure (HA, Whisper, Piper)
- [x] Old generation cleanup (weekly, delete >30d, auto-optimize)
- [x] Log rotation (1G max, 100M/file, 30d retention)
- [x] HA watchdog (restart on hang) (5min timeout, 10s restart delay)
- [ ] Auto-reboot notification on kernel updates

**Implementation:**

- systemd Restart=on-failure
- nix.gc (weekly, --delete-older-than 30d)
- journald SystemMaxUse/MaxFileSize/MaxRetentionSec
- systemd watchdog for HA

## Priority 2: Fix Broken References ✅ COMPLETE

- [x] Fix `sensor.uptime` (remove `sensor.last_boot` reference) (PR #11)
- [x] Update scripts to use actual entity IDs or make generic (PR #16 - commented out as placeholders)
- [x] Implement automations using input helpers (PR #16 - commented out as placeholders for future devices)
- [x] Verify all intents reference valid services/entities (PR #16)

## Priority 3: Database Migration ✅ COMPLETE

- [x] Install PostgreSQL (PR #15)
- [x] Configure HA to use PostgreSQL (PR #15)
- [x] Migrate existing SQLite data (optional - new DB created) (PR #15)
- [x] Configure recorder exclusions (PR #15)
- [x] Set retention policy (30 days) (PR #15)
- [ ] Test backup/restore with PostgreSQL (deferred - pending backup automation)

## Priority 4: Voice Enhancements

- [ ] Add Wyoming Openwakeword service
- [ ] Configure Polish wake word or train custom
- [ ] Integrate with HA voice pipeline
- [ ] Test hands-free activation
- [ ] Add LED/sound feedback for wake word

## Priority 5: Nice-to-Have Improvements

### High Value

- [x] Secrets management (sops-nix for Grafana password + HA Prometheus token)
- [x] Recorder limits (exclude noisy sensors)
- [ ] Low battery alerts automation
- [ ] Unavailable device detection automation
- [ ] Custom sentences auto-sync to /var/lib/hass
- [ ] Set configWritable=false (prevent GUI drift)

### Medium Value

- [ ] Pre-commit hooks (nix fmt, yamllint)
- [ ] Update notifications automation
- [ ] Network connectivity checks + auto-restart
- [ ] MQTT broker (when adding ESP devices)

### Low Priority

- [x] Prometheus + Grafana monitoring (⚠️ Grafana exposed on network with default credentials - change on first
  login, migrate to Tailscale in Phase 2)
- [ ] Network isolation (IoT VLAN)
- [ ] VM-based local testing
- [ ] Example device configurations

## Implementation Order

### Phase 1: Foundation ⚠️ Partial (3/4 done)

1. ⚠️ Configure SSH keys and Comin repo URL (Comin done PR #14, SSH keys still pending)
2. [x] Fix broken entity references (PR #16)
3. [x] Add system monitoring sensors (PR #11)
4. [x] Bind Wyoming to localhost (PR #14)

### Phase 2: Security & Remote Access ✅ COMPLETE

1. [x] Enable fail2ban for SSH
2. [x] Setup Tailscale
3. [x] Add service health checks
4. [x] Configure automated restarts (HA, Whisper, Piper + watchdog)

### Phase 3: Maintenance ⚠️ Partial (3/4 done)

1. [x] Set up log rotation
2. [x] Configure generation cleanup
3. [x] Add disk space monitoring
4. [ ] Add backup automation (local - deferred pending backup destination)

### Phase 4: Database & Voice ⚠️ Partial (2/4 done)

1. [x] Migrate to PostgreSQL (PR #15)
2. [x] Configure recorder limits (PR #15)
3. [ ] Add openwakeword service
4. [x] Implement helper automations (PR #16 - commented as placeholders pending actual devices)

### Phase 5: Quality of Life

1. [ ] Low battery alerts
2. [ ] Unavailable device detection
3. [ ] Pre-commit hooks
4. [ ] NFS backup migration

## Recent Changes

**Merged PRs:**

- **PR #17** (2025-12-30): Implemented Phase 3 - maintenance automation (log rotation, Nix GC)
- **PR #16** (2025-12-30): Fixed broken entity references, commented out placeholders for future devices
- **PR #15** (2025-12-29): Migrated Home Assistant to PostgreSQL
- **PR #14** (2025-12-29): Implemented Phase 2 - security & remote access
- **PR #13** (2025-12-29): Added sops-nix secrets management
- **PR #11** (2025-12-28): Added Grafana + Prometheus monitoring stack

## Summary

### ✅ Completed Phases

- **Phase 2:** Security & Remote Access (PR #14)

### ✅ Completed Priorities

- **Priority 2:** Fix Broken References (PR #16)
- **Priority 3:** Database Migration (PR #15)

### ⚠️ In Progress

- **Phase 1:** Foundation (3/4 done - SSH keys pending)
- **Phase 3:** Maintenance (3/4 done - log rotation, GC, disk monitoring complete; backup pending)
- **Phase 4:** Database & Voice (2/4 done - database complete, voice pending)

### 🔴 Remaining Priority Tasks

**Priority 1 - Critical:**

- Backup/Recovery (entire section - most critical gap)
- Configure SSH authorized_keys

**Priority 3 - Maintenance:**

- Backup automation (local Restic - deferred pending backup destination)

**Priority 4 - Voice:**

- Add openwakeword service

**Priority 5 - Nice-to-Have:**

- Low battery alerts
- Unavailable device detection
- Custom sentences auto-sync
- Set configWritable=false
- Pre-commit hooks
- Update notifications
- Network connectivity checks

## Next Steps

**Recommended priority:**

1. **Backup/Recovery** (Priority 1 - most critical missing piece - no data protection currently)
2. **Configure SSH keys** (Priority 1 - security hardening incomplete)
3. **Maintenance automation** (Phase 3 - log rotation + generation cleanup)
