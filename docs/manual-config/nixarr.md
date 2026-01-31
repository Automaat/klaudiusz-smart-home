# Nixarr Media Server Stack

**Why manual?** While Nixarr services are enabled declaratively, initial
configuration (API keys, indexers, connections between services) must be
done through each service's web UI.

**When to do this:** After first deployment when all services are running.

## Architecture Overview

**Services:**

- **Jellyfin** (8096): Media streaming server
- **Sonarr** (8989): TV show management
- **Radarr** (7878): Movie management
- **Prowlarr** (9696): Indexer manager (central point for all arr apps)
- **Bazarr** (6767): Subtitle management
- **Transmission** (9091): Download client
- **Flood** (3001): Modern web UI for Transmission
- **Jellyseerr** (5055): Request interface for users

**Storage:**

- `/media/torrents/` - Transmission downloads (categorized by service)
- `/media/library/shows/` - Sonarr library (TV shows)
- `/media/library/movies/` - Radarr library (Movies)
- `/data/.state/nixarr/` - Service configs/databases

**Critical:** All on same filesystem (`/dev/sda2`) for hardlinks - prevents
file duplication when importing downloads.

## Initial Setup Order

**IMPORTANT:** Follow this order - later services depend on earlier ones.

1. Jellyfin → Create admin account, add libraries
2. Prowlarr → Add indexers
3. Transmission → Verify authentication, note download directory
4. Flood (optional) → Create account, verify Transmission connection
5. Sonarr → Connect to Prowlarr + Transmission
6. Radarr → Connect to Prowlarr + Transmission
7. Bazarr → Connect to Sonarr + Radarr
8. Jellyseerr → Connect to Jellyfin + Sonarr + Radarr

## 1. Jellyfin Setup

**Access:** <http://homelab:8096> or <http://192.168.0.241:8096>

### Initial Wizard

1. Open Jellyfin web UI
2. **Welcome** → Select language (English) → **Next**
3. **Create Admin Account:**
   - Username: `admin`
   - Password: (choose strong password, save to password manager)
   - **Next**
4. **Setup Media Libraries:**
   - Click **Add Media Library**
   - **Content type:** Shows
   - **Display name:** TV Shows
   - **Folders:** Click **+** → Enter `/media/library/shows` → **OK**
   - **Save**
   - Click **Add Media Library** again
   - **Content type:** Movies
   - **Display name:** Movies
   - **Folders:** Click **+** → Enter `/media/library/movies` → **OK**
   - **Save**
   - **Next**
5. **Preferred Metadata Language:** English (or Polish)
6. **Configure Remote Access:**
   - Leave defaults (LAN access enabled)
   - **Next**
7. **Finish** → Login with admin credentials

### Verify Libraries

1. Navigate to **Dashboard** → **Libraries**
2. Verify `TV Shows` and `Movies` libraries visible
3. Check paths: `/media/library/shows` and `/media/library/movies`

## 2. Prowlarr Setup

**Access:** <http://homelab:9696> or <http://192.168.0.241:9696>

### Initial Configuration

1. Open Prowlarr web UI
2. Navigate to **Settings** → **General**
3. Note **API Key** (generate if not present) - needed for Sonarr/Radarr
4. **Authentication:** Set to `Forms (Login Page)` if desired
   - Create username/password
   - **Save**

### Add Indexers

**NOTE:** Use public/legal indexers only. For testing, use public domain content trackers.

1. Navigate to **Indexers**
2. Click **Add Indexer** (+)
3. Search for desired indexers (examples):
   - **Public:** YTS, EZTV, Nyaa (public domain/legal content only)
   - **Private:** Add trackers if you have accounts
4. For each indexer:
   - Configure settings (API key, passkey, etc.)
   - **Test** → **Save**
5. Verify green checkmark appears

### Connect Apps (Sonarr/Radarr)

**Do this AFTER configuring Sonarr and Radarr below.**

1. Navigate to **Settings** → **Apps**
2. Click **Add Application** (+) → **Sonarr**
3. Configure:
   - **Prowlarr Server:** `http://localhost:9696`
   - **Sonarr Server:** `http://localhost:8989`
   - **API Key:** (copy from Sonarr → Settings → General)
   - **Test** → **Save**
4. Repeat for Radarr:
   - Click **Add Application** (+) → **Radarr**
   - **Radarr Server:** `http://localhost:7878`
   - **API Key:** (copy from Radarr → Settings → General)
   - **Test** → **Save**
5. Click **Sync App Indexers** to push indexers to Sonarr/Radarr

## 3. Transmission Setup

**Access:** <http://homelab:9091> or <http://192.168.0.241:9091>

### Secure Access

**CRITICAL:** Port 9091 is open on firewall. Enable authentication to prevent unauthorized access.

**Authentication is configured declaratively via NixOS** (not web UI - daemon has no settings button):

**Password is stored in sops-encrypted secrets:**

1. Decrypt secrets: `mise run decrypt-secrets`
2. Edit `secrets/secrets.decrypted.yaml`, add/update:

   ```yaml
   transmission-rpc-password: your-strong-password
   ```

3. Encrypt: `mise run encrypt-secrets`
4. Commit encrypted `secrets/secrets.yaml`

**Configuration** (already set in `hosts/homelab/arr/default.nix`):

```nix
transmission.extraSettings = {
  rpc-authentication-required = true;
  rpc-username = "admin";
  # Password injected via systemd preStart from sops secret
};
```

**Verification:**

```bash
# Rebuild
sudo nixos-rebuild switch --flake /etc/nixos#homelab

# Test authentication required
curl -I http://homelab:9091  # Should return 401 Unauthorized
```

**Password handling:** Password stored encrypted in sops, injected into settings.json on service start,
then auto-hashed to SHA1 by Transmission.

**Alternative (Advanced):** Restrict via firewall:

- Remove port 9091 from `networking.firewall.allowedTCPPorts`
- Access via SSH tunnel: `ssh -L 9091:localhost:9091 homelab`
- Or configure reverse proxy with authentication

### Verify Download Configuration

Download settings are managed declaratively by nixarr. Verify via web UI:

1. Open Transmission web UI (enter credentials if prompted)
2. Check download directory: `/media/torrents`
3. Check seeding limits (optional, configure via extraSettings if needed):

```nix
transmission.extraSettings = {
  # ... existing settings ...
  ratio-limit-enabled = true;
  ratio-limit = 2.0;
  idle-seeding-limit-enabled = true;
  idle-seeding-limit = 10080;  # 7 days in minutes
};
```

**Note:** Transmission daemon has no web UI settings editor. All configuration via Nix or manual
`settings.json` editing (requires service stop).

### Flood Web UI (Alternative Interface)

**Access:** <http://homelab:3001> or <http://192.168.0.241:3001>

**Why Flood?** Transmission 4.x removed the built-in web UI. Flood provides a modern, feature-rich alternative with better UX.

**Configuration:** Transmission connection pre-configured via NixOS (environment variables). Manual setup required for user account only.

#### Initial Setup

1. Open Flood web UI in browser
2. **Create Account** (first-time only):
   - **Username:** Choose username (e.g., `admin`)
   - **Password:** Choose strong password (Flood account, separate from Transmission)
   - Click **Create Account**
3. **Client Connection** (auto-configured):
   - Flood automatically connects to Transmission via pre-configured environment variables
   - If prompted, verify settings:
     - **Client:** Transmission
     - **Host:** `192.168.15.1` (VPN namespace)
     - **Port:** `9091`
     - **Username:** `admin` (from sops secret)
     - **Password:** (auto-injected from sops secret)
   - Click **Connect**
4. **Verify Connection:**
   - Dashboard should load showing Transmission stats
   - Add test torrent to confirm functionality

#### Features

- **Modern UI:** Drag-and-drop torrent files, real-time stats
- **Multi-view:** List, grid, and detailed views
- **Filtering:** By status, tracker, label
- **RSS Feeds:** Subscribe to torrent RSS feeds
- **Mobile-friendly:** Responsive design

#### Troubleshooting

**Flood won't start:**

```bash
# Check service status
ssh homelab "systemctl status flood.service"

# Check logs
ssh homelab "journalctl -u flood.service -n 50"

# Common issue: Permission denied on sops secret
# Verify preStart runs as root (+ prefix)
```

**Cannot connect to Transmission:**

1. Verify Transmission running: `systemctl status transmission`
2. Check Transmission authentication working (curl test above)
3. Review Flood environment variables:

```bash
ssh homelab "systemctl show flood.service -p Environment"
# Should show TRANSMISSION_URL and TRANSMISSION_USER
```

4. Check password injected:

```bash
ssh homelab "cat /run/flood-transmission.env"
# Should show TRANSMISSION_PASS=<password>
```

**Account locked out:**

Flood stores user data in `/var/lib/flood`. To reset:

```bash
# Remove Flood state (WARNING: deletes all Flood settings)
ssh homelab "sudo systemctl stop flood && sudo rm -rf /var/lib/flood && sudo systemctl start flood"
```

#### Security Notes

- **Port 3001** must be added to firewall (already configured)
- **Flood authentication** independent from Transmission (separate user/pass)
- **Recommendation:** Use same strong password as Transmission for consistency
- **Access control:** Consider restricting to LAN/Tailscale only

## 4. Sonarr Setup

**Access:** <http://homelab:8989> or <http://192.168.0.241:8989>

### Initial Configuration

1. Open Sonarr web UI
2. Navigate to **Settings** → **General**
3. Note **API Key** (needed for Prowlarr)
4. Set authentication if desired

### Add Root Folder

1. Navigate to **Settings** → **Media Management**
2. Under **Root Folders**, click **Add Root Folder** (+)
3. Enter `/media/library/shows`
4. **OK**

### Add Download Client

1. Navigate to **Settings** → **Download Clients**
2. Click **Add** (+) → **Transmission**
3. Configure:
   - **Name:** Transmission
   - **Host:** `localhost`
   - **Port:** `9091`
   - **URL Base:** (leave blank)
   - **Username:** `admin` (from Transmission auth config)
   - **Password:** (from sops secrets: transmission-rpc-password)
   - **Category:** `sonarr` (optional, for organization)
4. **Test** → **Save**

### Connect to Prowlarr

1. Navigate to **Settings** → **Indexers**
2. Indexers should auto-appear after Prowlarr sync (see Prowlarr setup step 3)
3. If not, manually add:
   - Click **Add** (+) → **Custom**
   - Use Prowlarr API connection

### Verify Configuration

1. Navigate to **System** → **Status**
2. Check **Health:**
   - All checks should be green
   - If warnings about indexers, re-sync from Prowlarr

## 5. Radarr Setup

**Access:** <http://homelab:7878> or <http://192.168.0.241:7878>

**NOTE:** Radarr setup identical to Sonarr, just use `/media/library/movies` as root folder.

### Initial Configuration

1. Open Radarr web UI
2. Navigate to **Settings** → **General**
3. Note **API Key** (needed for Prowlarr)
4. Set authentication if desired

### Add Root Folder

1. Navigate to **Settings** → **Media Management**
2. Under **Root Folders**, click **Add Root Folder** (+)
3. Enter `/media/library/movies`
4. **OK**

### Add Download Client

1. Navigate to **Settings** → **Download Clients**
2. Click **Add** (+) → **Transmission**
3. Configure:
   - **Name:** Transmission
   - **Host:** `localhost`
   - **Port:** `9091`
   - **Category:** `radarr` (optional)
4. **Test** → **Save**

### Connect to Prowlarr

1. Navigate to **Settings** → **Indexers**
2. Indexers should auto-appear after Prowlarr sync
3. Verify green status

## 6. Bazarr Setup

**Access:** <http://homelab:6767> or <http://192.168.0.241:6767>

### Initial Configuration

1. Open Bazarr web UI
2. Navigate to **Settings** → **General**
3. Set authentication if desired

### Connect to Sonarr

1. Navigate to **Settings** → **Sonarr**
2. Click **Add** (+)
3. Configure:
   - **Name:** Sonarr
   - **Hostname or IP Address:** `localhost`
   - **Port:** `8989`
   - **API Key:** (copy from Sonarr → Settings → General)
   - **Base URL:** (leave blank)
4. **Test** → **OK**

### Connect to Radarr

1. Navigate to **Settings** → **Radarr**
2. Click **Add** (+)
3. Configure:
   - **Name:** Radarr
   - **Hostname or IP Address:** `localhost`
   - **Port:** `7878`
   - **API Key:** (copy from Radarr → Settings → General)
4. **Test** → **OK**

### Add Subtitle Providers

1. Navigate to **Settings** → **Providers**
2. Click **Add** (+) under **Providers**
3. Popular options:
   - **OpenSubtitles** (free account required)
   - **Subscene**
   - **Addic7ed** (account required)
4. Configure credentials → **Save**

### Configure Languages

1. Navigate to **Settings** → **Languages**
2. **Languages Filter:** Add desired languages (e.g., English, Polish)
3. **Default Enabled:** Check languages for auto-download
4. **Save**

## 7. Jellyseerr Setup

**Access:** <http://homelab:5055> or <http://192.168.0.241:5055>

### Initial Wizard

1. Open Jellyseerr web UI
2. **Sign in with Jellyfin:**
   - **Jellyfin URL:** `http://localhost:8096`
   - **Email/Username:** `admin` (from Jellyfin setup)
   - **Password:** (Jellyfin admin password)
   - **Sign In**
3. **Configure Jellyfin:** Should auto-detect libraries → **Continue**

### Connect to Sonarr

1. Navigate to **Settings** → **Services** → **Sonarr**
2. Click **Add Sonarr Server**
3. Configure:
   - **Default Server:** ✓ (checked)
   - **4K Server:** ☐ (unchecked)
   - **Server Name:** Sonarr
   - **Hostname or IP Address:** `localhost`
   - **Port:** `8989`
   - **API Key:** (copy from Sonarr)
   - **URL Base:** (leave blank)
   - **Use SSL:** ☐
4. **Test** → Should show quality profiles and root folders
5. Select:
   - **Quality Profile:** (choose default or preferred)
   - **Root Folder:** `/media/library/shows`
   - **Language Profile:** (optional)
6. **Save Changes**

### Connect to Radarr

1. Navigate to **Settings** → **Services** → **Radarr**
2. Click **Add Radarr Server**
3. Configure:
   - **Default Server:** ✓
   - **4K Server:** ☐
   - **Server Name:** Radarr
   - **Hostname or IP Address:** `localhost`
   - **Port:** `7878`
   - **API Key:** (copy from Radarr)
   - **URL Base:** (leave blank)
4. **Test** → **Save Changes**
5. Select quality profile and root folder `/media/library/movies`

### Configure Permissions

1. Navigate to **Settings** → **Users**
2. Select users and set permissions:
   - **Request:** Allow requesting content
   - **Auto Approve:** Auto-approve requests (optional)
   - **Manage Requests:** Approve/deny others' requests

## Verification Steps

### Service Health Checks

```bash
# Check all services running
ssh homelab "systemctl status jellyfin sonarr radarr prowlarr bazarr transmission jellyseerr"

# Check logs for errors
ssh homelab "journalctl -u jellyfin -n 20"
ssh homelab "journalctl -u sonarr -n 20"
ssh homelab "journalctl -u radarr -n 20"
```

### Network Accessibility

```bash
# Test from local machine
curl -I http://homelab:8096  # Jellyfin
curl -I http://homelab:8989  # Sonarr
curl -I http://homelab:7878  # Radarr
curl -I http://homelab:9696  # Prowlarr
curl -I http://homelab:6767  # Bazarr
curl -I http://homelab:9091  # Transmission
curl -I http://homelab:3001  # Flood
curl -I http://homelab:5055  # Jellyseerr
```

### Storage Verification

```bash
# Check directories created
ssh homelab "ls -la /media"
# Should show: library/, torrents/

# Check library subdirectories
ssh homelab "ls -la /media/library"
# Should show: shows/, movies/, music/, books/, audiobooks/

# Check state directories
ssh homelab "ls -la /data/.state/nixarr"
# Should show service directories

# Check disk usage
ssh homelab "df -h | grep sda2"
```

### Functional Test (Public Domain Content)

1. **Add Test Content:**
   - Open Sonarr → **Add Series**
   - Search for public domain show (e.g., old TV shows in public domain)
   - Select quality → **Add Series**
   - **Search** for episodes

2. **Monitor Download:**
   - Open Transmission → Verify torrent appears
   - Wait for download to complete

3. **Verify Import:**
   - Check Sonarr → **Activity** → **Queue**
   - Wait for import completion
   - Verify episode appears in **Series** list

4. **Check Hardlinks:**

   ```bash
   # Find downloaded file
   ssh homelab "find /media/torrents -name '*.mkv' -type f -exec stat {} \;"

   # Find imported file
   ssh homelab "find /media/library/shows -name '*.mkv' -type f -exec stat {} \;"

   # Same inode number = hardlink working (no duplication)
   ```

5. **Verify Jellyfin Playback:**
   - Open Jellyfin → **TV Shows**
   - Verify show appears
   - Click play → Test streaming

6. **Test Jellyseerr:**
   - Open Jellyseerr
   - Search for content
   - Request movie/show
   - Verify appears in Sonarr/Radarr queue

## Troubleshooting

### Service Won't Start

```bash
# Check service status
ssh homelab "systemctl status <service>"

# Check logs
ssh homelab "journalctl -u <service> -n 50"

# Restart service
ssh homelab "sudo systemctl restart <service>"
```

### Prowlarr Sync Failing

1. Verify API keys match in all services
2. Navigate to **Settings** → **Apps**
3. Test each connection
4. Click **Sync App Indexers** to force sync

### Download Not Starting

1. Check Transmission running: `systemctl status transmission`
2. Verify download client configured in Sonarr/Radarr
3. Check indexers returning results in Prowlarr
4. Review **System** → **Logs** in Sonarr/Radarr

### Import Failing / Hardlinks Not Working

```bash
# Verify same filesystem
ssh homelab "df /media/torrents /media/library/shows /media/library/movies"
# All should show same device (e.g., /dev/sda2)

# Check permissions
ssh homelab "ls -la /media"
ssh homelab "ls -la /media/library"
ssh homelab "ls -la /media/torrents"
```

### Jellyfin Not Showing Content

1. Navigate to **Dashboard** → **Libraries**
2. Click library → **Scan Library**
3. Check **Dashboard** → **Scheduled Tasks** → **Scan Media Library**
4. Review logs: **Dashboard** → **Logs**

## Removal Instructions

**If deciding not to keep Nixarr:**

```bash
# 1. Stop services (automatic when disabling module)
# 2. Remove data
ssh homelab "sudo rm -rf /data/.state/nixarr /media/library /media/torrents"

# 3. Remove module from git
# - Delete hosts/homelab/arr/
# - Remove ./arr from imports in hosts/homelab/default.nix
# - Remove nixarr from flake.nix inputs
# - Remove nixarr.nixosModules.default from flake.nix modules
# - Remove firewall ports (8096, 8989, 7878, 9696, 6767, 9091, 5055)
# - Remove "media" group from admin user extraGroups

# 4. Rebuild
sudo nixos-rebuild switch --flake /etc/nixos#homelab
```

## Related Documentation

- [Nixarr GitHub](https://github.com/rasmus-kirk/nixarr)
- [Jellyfin Documentation](https://jellyfin.org/docs/)
- [Sonarr Wiki](https://wiki.servarr.com/sonarr)
- [Radarr Wiki](https://wiki.servarr.com/radarr)
- [Prowlarr Wiki](https://wiki.servarr.com/prowlarr)
- [Bazarr Wiki](https://wiki.bazarr.media/)
- [Jellyseerr Documentation](https://docs.jellyseerr.dev/)
- [Transmission Manual](https://transmissionbt.com/)

## ProtonVPN Integration

**Architecture:** Transmission runs in isolated network namespace with ProtonVPN
WireGuard connection. Sonarr/Radarr/Prowlarr remain on LAN to avoid rate limiting.

**Features:**

- Automatic NAT-PMP port forwarding (renewed every 45s)
- Only Transmission uses VPN (via VPN-Confinement module)
- Dynamic port mapping to Transmission on renewal

### Manual Setup (One-Time)

**1. Download WireGuard Config:**

1. Login to [account.protonvpn.com](https://account.protonvpn.com) → Downloads → WireGuard configuration
2. Select **P2P-optimized server** (e.g., NL-FREE#123)
3. **Enable NAT-PMP checkbox** (critical for port forwarding)
4. Download config, rename to `protonvpn.conf` (max 15 chars for systemd)

**2. Encrypt with SOPS:**

```bash
cd /path/to/your/klaudiusz-smart-home

# Copy downloaded config
cp ~/Downloads/protonvpn.conf secrets/protonvpn-wg.conf.plain

# Encrypt with sops
sops -e secrets/protonvpn-wg.conf.plain > secrets/protonvpn-wg.conf

# Securely delete plaintext
shred -u secrets/protonvpn-wg.conf.plain

# Add to git
git add secrets/protonvpn-wg.conf
```

**3. Deploy:**

```bash
# Commit and push
git commit -s -S -m "feat(nixarr): add ProtonVPN WireGuard config"
git push

# Wait for Comin to pull changes, or manually trigger:
ssh homelab "sudo systemctl restart comin"
```

### Verification

**Check VPN Connection:**

```bash
# Check VPN interface in namespace
ssh homelab "sudo ip netns exec transmission-ns ip addr show wg0"

# Verify VPN IP (should differ from host)
ssh homelab "sudo ip netns exec transmission-ns curl -4 ifconfig.me"  # VPN IP
ssh homelab "curl -4 ifconfig.me"  # Host IP (should differ)
```

**Check Port Forwarding:**

```bash
# Service status
ssh homelab "systemctl status transmission-port-forwarding.service"

# Recent logs
ssh homelab "journalctl -u transmission-port-forwarding.service -n 50"

# View mapped port
ssh homelab "cat /run/transmission-natpmp-port"
```

**Test Port Forwarding (Functional):**

1. Add legal torrent (e.g., Ubuntu ISO) via Transmission web UI
2. Monitor for incoming connections in Transmission
3. Incoming connections indicate port forwarding working

**Verify Arr Services NOT Using VPN:**

```bash
# Prowlarr should use home IP (not VPN)
# Test indexer searches - should not be rate limited
```

### Transmission Authentication

**CRITICAL:** VPN namespace changes network exposure. Enable authentication:

1. Edit Transmission settings (if not already enabled)
2. Configure username/password
3. Update Sonarr/Radarr download client credentials

### Server Rotation

**When to rotate:** Server maintenance, poor performance, IP flagged

**Steps:**

1. Download new WireGuard config from ProtonVPN (different server)
2. Encrypt and replace `secrets/protonvpn-wg.conf`
3. **Update gateway IP** if different:
   - Check `Endpoint` line in downloaded config
   - Update `GATEWAY` variable in `hosts/homelab/arr/default.nix` (line ~59)
4. Commit, push, deploy

**Gateway IP check:**

```bash
# Extract gateway from config
sed -n 's/^Endpoint = \([^:]*\):.*/\1/p' secrets/protonvpn-wg.conf.plain
```

Standard ProtonVPN gateway: `10.2.0.1` (most servers). If different, update systemd service.

### Troubleshooting

**VPN not connecting:**

```bash
# Check WireGuard interface
ssh homelab "sudo ip netns exec transmission-ns wg show"

# Check systemd service
ssh homelab "systemctl status wg-quick-wg0"

# Verify config decrypted
ssh homelab "sudo ls -la /run/secrets/protonvpn-wg-conf"
```

**Port forwarding failing:**

```bash
# Check NAT-PMP service logs
ssh homelab "journalctl -u transmission-port-forwarding.service -n 100"

# Common errors:
# - "natpmpc failed" → VPN not connected or NAT-PMP not enabled
# - "Failed to extract mapped port" → Gateway IP wrong or ProtonVPN config invalid
```

**Transmission not updating port:**

```bash
# Check Transmission RPC accessible
ssh homelab "transmission-remote localhost:9091 --session-info"

# Manually set port to test
ssh homelab "transmission-remote localhost:9091 --port 12345"
```

**IPv6 Issues:**

IPv6 disabled system-wide (required for ProtonVPN NAT-PMP). If issues:

```bash
# Check IPv6 disabled
ssh homelab "cat /proc/sys/net/ipv6/conf/all/disable_ipv6"
# Should output: 1
```

**Tailscale connectivity after IPv6 disable:** Test Tailscale peer connections:

```bash
tailscale ping homelab
```

If issues, check Tailscale logs:

```bash
ssh homelab "journalctl -u tailscaled -n 50"
```

## Security Notes

- **VPN:** Enabled via ProtonVPN WireGuard. Only Transmission uses VPN.
- **Authentication:** Set passwords on all web UIs (especially Transmission, now VPN-exposed).
- **Firewall:** Ports only accessible from LAN + Tailscale (not internet-exposed).
- **Legal Content:** Only use for legal content (public domain, personal media, authorized downloads).
