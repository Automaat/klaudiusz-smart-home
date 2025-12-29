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
- [ ] Scripts reference missing entities (`light.salon`, `cover.salon`)
- [ ] Input helpers unused (need automations)
- [ ] SSH keys placeholder
- [x] Comin repo URL placeholder

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
**Status:** ❌ No system monitoring

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
**Status:** ⚠️ Basic, needs hardening

- [ ] Configure SSH authorized_keys
- [ ] Configure Comin repository URL
- [ ] fail2ban for SSH
- [ ] Bind Wyoming services to localhost (currently 0.0.0.0)
- [ ] Tailscale setup for remote access
- [ ] fail2ban for Home Assistant (lower priority with Tailscale)

**Implementation:**
- Add SSH keys to NixOS config
- Set actual git repo in Comin
- NixOS fail2ban service
- Restrict Wyoming to 127.0.0.1
- services.tailscale.enable = true

### 4. Maintenance Automation
**Status:** ⚠️ Partially complete

- [x] Auto-restart on service failure (HA, Whisper, Piper)
- [ ] Old generation cleanup (weekly)
- [ ] Log rotation (journald limits)
- [x] HA watchdog (restart on hang) (5min timeout, 10s restart delay)
- [ ] Auto-reboot notification on kernel updates

**Implementation:**
- systemd Restart=on-failure
- nix-collect-garbage timer (weekly, keep 5 generations)
- journald maxRetentionSec + maxFileSize
- systemd watchdog for HA

## Priority 2: Fix Broken References

- [x] Fix `sensor.uptime` (remove `sensor.last_boot` reference)
- [ ] Update scripts to use actual entity IDs or make generic
- [ ] Implement automations using input helpers (away_mode, guest_mode, sleep_mode)
- [ ] Verify all intents reference valid services/entities

## Priority 3: Database Migration

- [ ] Install PostgreSQL
- [ ] Configure HA to use PostgreSQL
- [ ] Migrate existing SQLite data
- [ ] Configure recorder exclusions
- [ ] Set retention policy (30 days)
- [ ] Test backup/restore with PostgreSQL

## Priority 4: Voice Enhancements

- [ ] Add Wyoming Openwakeword service
- [ ] Configure Polish wake word or train custom
- [ ] Integrate with HA voice pipeline
- [ ] Test hands-free activation
- [ ] Add LED/sound feedback for wake word

## Priority 5: Nice-to-Have Improvements

### High Value
- [x] Secrets management (sops-nix for Grafana password + HA Prometheus token)
- [ ] Recorder limits (exclude noisy sensors)
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
- [x] Prometheus + Grafana monitoring (⚠️ Grafana exposed on network with default credentials - change on first login, migrate to Tailscale in Phase 2)
- [ ] Network isolation (IoT VLAN)
- [ ] VM-based local testing
- [ ] Example device configurations

## Implementation Order

### Phase 1: Foundation (Do First)
1. [ ] Configure SSH keys and Comin repo URL
2. [ ] Fix broken entity references
3. [ ] Add system monitoring sensors
4. [ ] Bind Wyoming to localhost

### Phase 2: Security & Remote Access
5. [ ] Enable fail2ban for SSH
6. [ ] Setup Tailscale
7. [ ] Add service health checks
8. [x] Configure automated restarts (HA, Whisper, Piper + watchdog)

### Phase 3: Maintenance
9. [ ] Set up log rotation
10. [ ] Configure generation cleanup
11. [ ] Add disk space monitoring
12. [ ] Add backup automation (local)

### Phase 4: Database & Voice
13. [ ] Migrate to PostgreSQL
14. [ ] Configure recorder limits
15. [ ] Add openwakeword service
16. [ ] Implement helper automations

### Phase 5: Quality of Life
17. [ ] Low battery alerts
18. [ ] Unavailable device detection
19. [ ] Pre-commit hooks
20. [ ] NFS backup migration

## Next Steps

Pick phase or specific task to start implementation.
