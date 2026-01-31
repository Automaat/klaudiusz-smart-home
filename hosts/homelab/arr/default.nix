{
  config,
  pkgs,
  lib,
  ...
}: {
  # ===========================================
  # Nixarr Media Stack
  # ===========================================

  nixarr = {
    enable = true;

    # Storage configuration
    mediaDir = "/media"; # Base for /media/{tv,movies,downloads}
    stateDir = "/data/.state/nixarr"; # Service configs/databases

    # Media server
    jellyfin.enable = true;

    # Arr stack
    sonarr.enable = true;
    radarr.enable = true;
    prowlarr.enable = true;
    bazarr.enable = true;

    # Download client
    transmission = {
      enable = true;
      vpn.enable = true;
      extraSettings = {
        # Disable whitelists - authentication handles access control
        rpc-host-whitelist-enabled = false;
        rpc-whitelist-enabled = false;

        # Authentication - CRITICAL: port 9091 is firewall-exposed
        rpc-authentication-required = true;
        rpc-username = "admin";
        # Password injected via preStart from sops secret
      };
    };

    # Request management
    jellyseerr.enable = true;

    # VPN configuration (transmission only)
    vpn = {
      enable = true;
      wgConf = config.sops.secrets."protonvpn-wg-conf".path;
    };
  };

  # ===========================================
  # ProtonVPN NAT-PMP Port Forwarding
  # ===========================================

  environment.systemPackages = [pkgs.libnatpmp];

  systemd.services."transmission-port-forwarding" = {
    description = "ProtonVPN NAT-PMP port forwarding for Transmission";
    after = ["network-online.target" "transmission.service" "wg.service"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "transmission-natpmp" ''
        set -euo pipefail

        # Check if wg namespace exists (exit successfully if not ready yet, timer will retry)
        if ! ${pkgs.iproute2}/bin/ip netns list | ${pkgs.gnugrep}/bin/grep -q '^wg\b'; then
          echo "VPN namespace 'wg' not ready yet, skipping (timer will retry)"
          exit 0
        fi

        # Transmission listens on wg-br bridge (not localhost) inside VPN namespace
        GATEWAY="10.2.0.1"
        TRANSMISSION_RPC="192.168.15.1:9091"

        # Get Transmission's current listening port (or use default)
        CURRENT_PORT=$(${pkgs.iproute2}/bin/ip netns exec wg \
          ${pkgs.transmission_4}/bin/transmission-remote "$TRANSMISSION_RPC" \
          --session-info 2>/dev/null | \
          ${pkgs.ripgrep}/bin/rg 'Listening port: (\d+)' -r '$1' || echo "51413")

        echo "Current Transmission port: $CURRENT_PORT"
        echo "Requesting NAT-PMP TCP port mapping..."

        # Request mapping for current port (private=public ideally)
        NATPMP_OUTPUT=$(${pkgs.iproute2}/bin/ip netns exec wg \
          ${pkgs.libnatpmp}/bin/natpmpc -a "$CURRENT_PORT" 0 tcp 60 -g "$GATEWAY" 2>&1) || {
          echo "ERROR: natpmpc failed: $NATPMP_OUTPUT" >&2
          exit 1
        }

        MAPPED_PORT=$(echo "$NATPMP_OUTPUT" | ${pkgs.ripgrep}/bin/rg -o 'Mapped public port (\d+)' -r '$1')

        if [ -z "$MAPPED_PORT" ]; then
          echo "ERROR: Failed to extract mapped port" >&2
          exit 1
        fi

        echo "Mapped public port: $MAPPED_PORT"

        # Request UDP mapping for same port (BitTorrent uses TCP + UDP)
        echo "Requesting NAT-PMP UDP port mapping..."
        ${pkgs.iproute2}/bin/ip netns exec wg \
          ${pkgs.libnatpmp}/bin/natpmpc -a "$CURRENT_PORT" 0 udp 60 -g "$GATEWAY" 2>&1 || {
          echo "WARNING: UDP mapping failed (DHT/uTP may not work)" >&2
        }

        # Store port for next run comparison
        RUNTIME_DIR="''${RUNTIME_DIRECTORY:-/run/transmission-natpmp}"
        PREV_PORT_FILE="$RUNTIME_DIR/port"
        PREV_PORT=""
        [ -f "$PREV_PORT_FILE" ] && PREV_PORT=$(cat "$PREV_PORT_FILE")

        if [ "$MAPPED_PORT" != "$PREV_PORT" ]; then
          echo "Port changed ($PREV_PORT -> $MAPPED_PORT), updating Transmission..."
          ${pkgs.iproute2}/bin/ip netns exec wg \
            ${pkgs.transmission_4}/bin/transmission-remote "$TRANSMISSION_RPC" \
            --port "$MAPPED_PORT" || echo "WARNING: Failed to update Transmission port"
          echo "$MAPPED_PORT" > "$PREV_PORT_FILE"
        else
          echo "Port unchanged ($MAPPED_PORT), skipping Transmission update"
        fi
      '';
      RuntimeDirectory = "transmission-natpmp";
      RuntimeDirectoryMode = "0755";
    };
  };

  systemd.timers."transmission-port-forwarding" = {
    description = "Timer for ProtonVPN NAT-PMP port renewal";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "45s";
      OnUnitActiveSec = "45s";
      Unit = "transmission-port-forwarding.service";
    };
  };

  # ===========================================
  # Transmission RPC Password Injection
  # ===========================================
  # Override transmission service to inject password from sops before start

  systemd.services.transmission = {
    preStart = lib.mkAfter ''
      # Inject RPC password from sops secret into settings.json
      SETTINGS_FILE="${config.nixarr.stateDir}/transmission/.config/transmission-daemon/settings.json"
      PASSWORD_FILE="${config.sops.secrets."transmission-rpc-password".path}"

      if [ -f "$PASSWORD_FILE" ]; then
        # Update settings.json using jq (transmission will hash it on next start)
        # Use --rawfile to avoid exposing password in process args
        if ${pkgs.jq}/bin/jq --rawfile pass "$PASSWORD_FILE" \
          '.["rpc-password"] = ($pass | rtrimstr("\n"))' \
          "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"; then
          mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
          echo "RPC password injected from sops secret"
        else
          rm -f "$SETTINGS_FILE.tmp"
          echo "ERROR: Failed to inject RPC password (jq failure)"
          exit 1
        fi
      else
        echo "WARNING: RPC password secret not found at $PASSWORD_FILE"
      fi
    '';
  };

  # ===========================================
  # Flood Web UI for Transmission
  # ===========================================
  # Transmission 4.x doesn't include built-in web UI
  # Use Flood as modern alternative

  services.flood = {
    enable = true;
    host = "0.0.0.0";
    port = 3001;
  };

  systemd.services.flood = {
    after = ["transmission.service"];
    serviceConfig = {
      # Use systemd LoadCredential for secure password injection
      LoadCredential = "transmission-pass:${config.sops.secrets."transmission-rpc-password".path}";
      # Wrapper script to inject credential into environment before starting Flood
      ExecStart = lib.mkForce (pkgs.writeShellScript "flood-start" ''
        # Read password from systemd credential and export as env var
        export TRANSMISSION_PASS="$(${pkgs.coreutils}/bin/tr -d '\n' < "$CREDENTIALS_DIRECTORY/transmission-pass")"

        # Start Flood with all environment variables available
        exec ${pkgs.flood}/bin/flood \
          --host ${config.services.flood.host} \
          --port ${toString config.services.flood.port} \
          --rundir=/var/lib/flood
      '');
    };
    environment = {
      # Transmission RPC in VPN namespace
      TRANSMISSION_URL = "http://192.168.15.1:9091/transmission/rpc";
      TRANSMISSION_USER = "admin";
      # TRANSMISSION_PASS injected by wrapper script from LoadCredential
    };
  };

  # ===========================================
  # Networking - Firewall Ports
  # ===========================================
  # NOTE: These are added to main default.nix firewall config
  # Keeping here as documentation of required ports

  # networking.firewall.allowedTCPPorts = [
  #   8096  # Jellyfin
  #   8989  # Sonarr
  #   7878  # Radarr
  #   9696  # Prowlarr
  #   6767  # Bazarr
  #   9091  # Transmission RPC
  #   3001  # Flood web UI
  #   5055  # Jellyseerr
  # ];
}
