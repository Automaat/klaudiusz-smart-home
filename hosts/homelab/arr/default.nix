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

    # VPN (disabled for testing)
    # vpn.enable = false;  # Enable later for privacy
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
