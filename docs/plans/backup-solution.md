# Backblaze B2 Backup Solution - Implementation Plan

## Overview

Dual-repository Restic backup (local + Backblaze B2) for disaster recovery from complete hardware failure.

**Specs:**
- **Backup size:** ~200-400GB (all critical data + time-series)
- **Frequency:** Daily at 2 AM
- **Retention:** 7 daily, 4 weekly, 6 monthly
- **Cost:** $2-4/month B2 (well under $10 budget)
- **RTO:** <4h (local restore) or <24h (B2 download)

## Architecture

### Two Restic Repositories

1. **Local:** `/backup/homelab-restic` (on main SSD)
   - Fast restore (minutes-hours)
   - Primary recovery path
   - Fail if unavailable

2. **Backblaze B2:** `b2:homelab-backup:/`
   - Offsite protection
   - Hardware failure recovery
   - Fire-and-forget (log errors, don't fail)

### Data Backup Scope

**Critical directories (~200-400GB):**
```
/var/lib/hass              # HA config, automations, zigbee.db
/var/lib/postgresql        # Recorder DB (via pg_dump)
/var/lib/influxdb2         # Metrics (365d)
/var/lib/loki              # Logs (365d)
/var/lib/prometheus        # Metrics (365d)
/var/lib/grafana           # Dashboards
/var/lib/comin             # GitOps state
/var/lib/crowdsec          # Security DB
/etc/nixos                 # Flake config (git-backed, include for safety)
```

**Critical exclusion:** `/var/lib/sops-nix/key.txt` backed up separately (see Secrets section)

### Backup Flow

```
2:00 AM: Local backup
  ↓ Pre-backup: pg_dump → /tmp/postgres-backup.sql
  ↓ Restic backup to /backup/homelab-restic
  ↓ Cleanup temp files
  ↓ On failure: Telegram alert

2:30 AM: B2 backup
  ↓ Pre-backup: pg_dump (reuse)
  ↓ Restic backup to b2:homelab-backup
  ↓ Export Prometheus metrics
  ↓ Cleanup temp files
  ↓ On failure: Telegram alert
```

## Cost Analysis

**Backblaze B2 (200GB scenario):**
- Storage: 190GB × $0.006/GB = **$1.14/month**
- API calls (daily backups): **$0.65/month**
- Egress (DR restore): **$0** (first 600GB/month free)
- **Total: $1.79 - $4.00/month** ✅

## Implementation

### 1. Backblaze B2 Setup (Manual)

**One-time steps:**

1. Create account: https://www.backblaze.com/sign-up/cloud-storage
2. Create bucket:
   - Name: `homelab-backup`
   - Lifecycle: Private
   - Encryption: Server-side
3. Create application key:
   - Name: `homelab-restic-backup`
   - Access: Read/Write to `homelab-backup` only
   - **Save Key ID and Key** (shown once!)
4. Test connectivity manually:
   ```bash
   export B2_ACCOUNT_ID=...
   export B2_ACCOUNT_KEY=...
   export RESTIC_PASSWORD=...
   restic -r b2:homelab-backup:/ init
   ```

### 2. Secrets Configuration

**Generate passwords:**
```bash
openssl rand -base64 32  # Local repo password
openssl rand -base64 32  # B2 repo password
```

**Add to secrets:**
```bash
mise run decrypt-secrets
# Edit secrets/secrets.decrypted.yaml - add:
# restic-local-password: "<password1>"
# restic-b2-password: "<password2>"
# restic-b2-env: |
#   B2_ACCOUNT_ID=<id>
#   B2_ACCOUNT_KEY=<key>
mise run encrypt-secrets
```

**Update hosts/homelab/secrets.nix:**
```nix
sops.secrets = {
  # ... existing secrets ...

  "restic-local-password" = {
    owner = "root";
    mode = "0400";
    restartUnits = ["restic-backups-homelab-local.service"];
  };

  "restic-b2-password" = {
    owner = "root";
    mode = "0400";
    restartUnits = ["restic-backups-homelab-b2.service"];
  };

  "restic-b2-env" = {
    owner = "root";
    mode = "0400";
    restartUnits = ["restic-backups-homelab-b2.service"];
  };
};
```

### 3. NixOS Configuration

**Create hosts/homelab/backups.nix:**

Key components:
- `services.restic.backups.homelab-local` - Local repository config
- `services.restic.backups.homelab-b2` - B2 repository config
- PostgreSQL pg_dump in `backupPrepareCommand`
- Prometheus metrics export in `backupCleanupCommand`
- Systemd service hardening (ReadOnlyPaths, SupplementaryGroups)
- Notification service: `notify-backup-failure@.service` (follows pattern at default.nix:713-734)

**Patterns to follow:**
- Timer config: default.nix:360-367
- LoadCredential: default.nix:394-397
- Oneshot service: default.nix:383-428
- Prometheus textfile export: default.nix:317-358

**Metrics exported:**
```prometheus
restic_backup_success{repository="local|b2"} 1
restic_backup_size_bytes{repository="local|b2"} 234567890
restic_backup_last_run_timestamp{repository="local|b2"} 1737000000
```

**Import in hosts/homelab/default.nix:**
```nix
imports = [
  # ... existing ...
  ./backups.nix
];
```

### 4. Monitoring & Alerting

**Add to hosts/homelab/grafana/default.nix:**

Follow `mkSystemdAlertRule` pattern (default.nix:114-121):

```nix
{
  uid = "restic_backup_failed";
  title = "Restic Backup Failed";
  condition = "C";
  data = [
    {
      refId = "A";
      datasourceUid = "prometheus";
      model.expr = "restic_backup_success";
    }
    {
      refId = "C";
      datasourceUid = "-100";
      model.type = "threshold";
      # conditions: value < 1
    }
  ];
  for = "30m";
  annotations.summary = "Backup to {{ $labels.repository }} failed";
  labels.severity = "critical";
}

{
  uid = "restic_backup_stale";
  title = "Backup Not Run in 26h";
  # Similar pattern, check (time() - restic_backup_last_run_timestamp) > 26h
  for = "1h";
  labels.severity = "warning";
}
```

**Create hosts/homelab/grafana/dashboards/services/backup.json:**

Panels:
- Backup status (gauge: green/red)
- Repository size (time series)
- Time since last backup (single stat)
- Backup duration (histogram)

### 5. Disaster Recovery Documentation

**Create docs/manual-config/backups.md:**

Sections:
- Full system restore from B2 (hardware failure)
- Partial restore (single service)
- Database point-in-time recovery
- Monthly test restore procedure
- Age key backup locations (CRITICAL)

**Age key backup (4× redundant):**
1. USB flash drive (encrypted)
2. Password manager (Bitwarden: "Homelab Age Encryption Key")
3. Printed paper backup (QR code)
4. Cloud storage (GPG-encrypted)

⚠️ **Without age key, encrypted secrets UNRECOVERABLE!**

**Update docs/manual-config/README.md** with link to backups.md

## Critical Files

### New Files

1. **hosts/homelab/backups.nix** (~350 lines)
   - Core Restic configuration
   - Two repositories (local + B2)
   - Metrics export script
   - Notification integration

2. **hosts/homelab/grafana/dashboards/services/backup.json** (~500 lines)
   - Backup status dashboard

3. **docs/manual-config/backups.md** (~200 lines)
   - DR procedures
   - Restore walkthroughs

### Modified Files

1. **hosts/homelab/secrets.nix** (+20 lines)
   - Add 3 Restic secrets

2. **hosts/homelab/default.nix** (+1 line)
   - Import backups.nix

3. **hosts/homelab/grafana/default.nix** (+80 lines)
   - Add 2 alert rules

4. **secrets/secrets.yaml** (+3 secrets)
   - Via mise tasks (encrypted)

5. **docs/manual-config/README.md** (+1 link)

## Testing & Validation

### Pre-Deployment

- [ ] `nix flake check` passes
- [ ] B2 credentials valid (manual test)
- [ ] Secrets encrypted correctly
- [ ] Static tests pass (CI)

### Post-Deployment

- [ ] Local backup completes
- [ ] B2 backup completes
- [ ] Metrics in Prometheus
- [ ] Grafana dashboard shows data
- [ ] Telegram alert on manual failure
- [ ] Systemd timers active

### Verification Procedure

```bash
# Monitor first backup
journalctl -u restic-backups-homelab-local.service -f
journalctl -u restic-backups-homelab-b2.service -f

# Check metrics
curl localhost:9100/metrics | grep restic_backup

# List snapshots
restic -r /backup/homelab-restic snapshots
restic -r b2:homelab-backup:/ snapshots

# Test restore (non-destructive)
mkdir /tmp/restore-test
restic -r /backup/homelab-restic restore latest --target /tmp/restore-test --include /var/lib/hass/configuration.yaml
diff /var/lib/hass/configuration.yaml /tmp/restore-test/var/lib/hass/configuration.yaml
rm -rf /tmp/restore-test
```

### Monthly Validation

- [ ] Backup ran in last 26h (automated via Grafana alert)
- [ ] Repository integrity check passes
- [ ] Test restore of random file
- [ ] B2 bill matches expectations (<$10)

### Quarterly (Manual)

- [ ] Full DR simulation on VM
- [ ] Age key recovery test
- [ ] Review and update documentation

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Age key loss | CRITICAL | 4× redundant backups (USB, password manager, paper, cloud) |
| Both repos corrupt | HIGH | Weekly integrity checks, separate passwords |
| B2 account lockout | MEDIUM | Local repo provides recovery |
| Backup size explosion | LOW | Retention policy, monitoring alerts |
| Cost overrun | LOW | Dashboard monitoring, B2 cost alerts |

## Execution Order

1. **Setup** (1-2h):
   - Create B2 account + bucket
   - Generate Restic passwords
   - Configure secrets via mise

2. **Configuration** (2-3h):
   - Create backups.nix
   - Update secrets.nix
   - Add Grafana alerts
   - Create dashboard JSON
   - Import in default.nix

3. **Testing** (2-4h):
   - Test B2 connectivity
   - Build locally: `nix flake check`
   - Deploy via PR (branch → merge → CI → production)
   - Monitor first backup
   - Verify metrics in Grafana
   - Test restore procedure

4. **Documentation** (1h):
   - Create docs/manual-config/backups.md
   - Update README.md
   - Backup age key to 4 locations

**Total effort: 9-11 hours**

## Alternative Approaches Considered

**Restic vs Borg:**
- Restic: Native B2 support, better deduplication, simpler restore
- Borg: Faster for local-only, more mature
- **Decision:** Restic for cloud-native + NixOS integration

**Dual vs Single Repo:**
- Dual: Fast local restore, network resilience
- Single B2: Simpler, lower cost
- **Decision:** Dual for faster RTO (cost difference negligible)

**pg_dump vs Filesystem Backup:**
- pg_dump: Clean state, point-in-time consistency, easier restore
- Filesystem: Simpler
- **Decision:** pg_dump for reliability

## Unresolved Questions

None - all requirements clarified via user questions.

**Confirmed:**
- ✅ DR scenario: Complete hardware failure
- ✅ Budget: $5-10/month (actual: $2-4/month)
- ✅ Frequency: Daily at 2 AM
- ✅ Strategy: Dual backup (local + B2)
- ✅ Local location: `/backup` on main SSD (512GB available)
- ✅ Age key backups: Bitwarden + USB + paper + cloud

## Cost Optimization

Current cost ($2-4/month) already optimal. Further optimization not worth complexity:
- Reduce frequency: Save $0.30/month, lose up to 7d metrics
- Pre-compress: Save $0.10-0.20/month, slower restore
- Lifecycle policies: Save $0.05/month (already recommended)

**Recommendation:** Keep as-is.

## Future Enhancements (Out of Scope)

- Automated monthly restore testing (systemd timer)
- Pre-upgrade tagged snapshots
- Incremental PostgreSQL backups (WAL archiving)
- Off-site local backup (NFS to friend's homelab)
- Quarterly backup encryption key rotation
- Multi-cloud redundancy (Wasabi/S3)
