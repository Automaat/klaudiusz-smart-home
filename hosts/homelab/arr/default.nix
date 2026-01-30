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
    transmission.enable = true;

    # Request management
    jellyseerr.enable = true;

    # VPN configuration (transmission only)
    vpn = {
      enable = true;
      wgConf = config.sops.secrets."protonvpn-wg-conf".path;
    };

    # Route transmission through VPN namespace
    transmission.vpn = {
      enable = true;
    };
  };

  # ===========================================
  # ProtonVPN NAT-PMP Port Forwarding
  # ===========================================

  environment.systemPackages = [pkgs.libnatpmp];

  systemd.services."transmission-port-forwarding" = {
    description = "ProtonVPN NAT-PMP port forwarding for Transmission";
    after = ["network-online.target" "transmission.service"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "transmission-natpmp" ''
        set -euo pipefail

        GATEWAY="10.2.0.1"  # ProtonVPN gateway

        echo "Requesting NAT-PMP port mapping..."
        NATPMP_OUTPUT=$(${pkgs.libnatpmp}/bin/natpmpc -a 1 0 tcp 60 -g "$GATEWAY" 2>&1) || {
          echo "ERROR: natpmpc failed: $NATPMP_OUTPUT" >&2
          exit 1
        }

        MAPPED_PORT=$(echo "$NATPMP_OUTPUT" | ${pkgs.ripgrep}/bin/rg -o 'Mapped public port (\d+)' -r '$1')

        if [ -z "$MAPPED_PORT" ]; then
          echo "ERROR: Failed to extract mapped port" >&2
          exit 1
        fi

        echo "Mapped port: $MAPPED_PORT"

        PREV_PORT_FILE="/run/transmission-natpmp-port"
        PREV_PORT=""
        [ -f "$PREV_PORT_FILE" ] && PREV_PORT=$(cat "$PREV_PORT_FILE")

        if [ "$MAPPED_PORT" != "$PREV_PORT" ]; then
          echo "Port changed, updating transmission..."
          ${pkgs.transmission_4}/bin/transmission-remote localhost:9091 \
            --port "$MAPPED_PORT" || echo "WARNING: Failed to update port"
          echo "$MAPPED_PORT" > "$PREV_PORT_FILE"
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
  #   9091  # Transmission
  #   5055  # Jellyseerr
  # ];
}
