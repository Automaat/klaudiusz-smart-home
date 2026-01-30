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
- **Jellyseerr** (5055): Request interface for users

**Storage:**

- `/media/downloads/` - Transmission downloads
- `/media/tv/` - Sonarr library
- `/media/movies/` - Radarr library
- `/data/.state/nixarr/` - Service configs/databases

**Critical:** All on same filesystem (`/dev/sda2`) for hardlinks - prevents
file duplication when importing downloads.

## Initial Setup Order

**IMPORTANT:** Follow this order - later services depend on earlier ones.

1. Jellyfin → Create admin account, add libraries
2. Prowlarr → Add indexers
3. Transmission → Note download directory
4. Sonarr → Connect to Prowlarr + Transmission
5. Radarr → Connect to Prowlarr + Transmission
6. Bazarr → Connect to Sonarr + Radarr
7. Jellyseerr → Connect to Jellyfin + Sonarr + Radarr

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
   - **Folders:** Click **+** → Enter `/media/tv` → **OK**
   - **Save**
   - Click **Add Media Library** again
   - **Content type:** Movies
   - **Display name:** Movies
   - **Folders:** Click **+** → Enter `/media/movies` → **OK**
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
3. Check paths: `/media/tv` and `/media/movies`

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

### Verify Configuration

1. Open Transmission web UI
2. Click **Settings** gear icon (top-right)
3. Navigate to **Torrents** tab
4. Verify **Download to:** `/media/downloads`
5. **Seeding:**
   - Stop seeding at ratio: `2.0` (adjust as desired)
   - Or stop seeding after: `7 days`
6. **Apply** → **Close**

**NOTE:** Nixarr pre-configures most settings. No authentication setup needed.

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
3. Enter `/media/tv`
4. **OK**

### Add Download Client

1. Navigate to **Settings** → **Download Clients**
2. Click **Add** (+) → **Transmission**
3. Configure:
   - **Name:** Transmission
   - **Host:** `localhost`
   - **Port:** `9091`
   - **URL Base:** (leave blank)
   - **Username:** (leave blank - no auth)
   - **Password:** (leave blank)
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

**NOTE:** Radarr setup identical to Sonarr, just use `/media/movies` as root folder.

### Initial Configuration

1. Open Radarr web UI
2. Navigate to **Settings** → **General**
3. Note **API Key** (needed for Prowlarr)
4. Set authentication if desired

### Add Root Folder

1. Navigate to **Settings** → **Media Management**
2. Under **Root Folders**, click **Add Root Folder** (+)
3. Enter `/media/movies`
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
   - **Root Folder:** `/media/tv`
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
5. Select quality profile and root folder `/media/movies`

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
curl -I http://homelab:5055  # Jellyseerr
```

### Storage Verification

```bash
# Check directories created
ssh homelab "ls -la /media"
# Should show: downloads/, tv/, movies/

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
   ssh homelab "find /media/downloads -name '*.mkv' -type f -exec stat {} \;"

   # Find imported file
   ssh homelab "find /media/tv -name '*.mkv' -type f -exec stat {} \;"

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
ssh homelab "df /media/downloads /media/tv /media/movies"
# All should show same device (e.g., /dev/sda2)

# Check permissions
ssh homelab "ls -la /media"
ssh homelab "ls -la /media/downloads"
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
ssh homelab "sudo rm -rf /data/.state/nixarr /media"

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

## Security Notes

- **VPN:** Currently disabled. Enable `services.nixarr.vpn` for privacy when downloading from public trackers.
- **Authentication:** Set passwords on all web UIs (especially if exposed beyond LAN).
- **Firewall:** Ports only accessible from LAN + Tailscale (not internet-exposed).
- **Legal Content:** Only use for legal content (public domain, personal media, authorized downloads).
