{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./home-assistant
    ./secrets.nix
  ];

  # ===========================================
  # System
  # ===========================================
  system.stateVersion = "24.11";
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # ===========================================
  # Boot (adjust for your hardware)
  # ===========================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network optimization (BBR for better Tailscale performance)
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # ===========================================
  # Networking
  # ===========================================
  networking = {
    hostName = "homelab";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        8123 # Home Assistant
      ];
      allowedUDPPorts = [
        config.services.tailscale.port # Tailscale
        5353 # mDNS (Avahi/Bonjour for HomeKit discovery)
      ];
      # Allow Tailscale traffic
      trustedInterfaces = ["tailscale0"];
    };
  };

  # ===========================================
  # Locale & Time
  # ===========================================
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "pl"; # Keep Polish keyboard layout

  # ===========================================
  # Users
  # ===========================================
  users.users.admin = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "dialout"]; # dialout for Zigbee USB
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMnlSO5YSaF10lrs9q4Z6QJ2LZp4oDHgZ5xR9VaaR+cX skalskimarcin33@gmail.com"
    ];
  };

  # ===========================================
  # Security
  # ===========================================
  security.sudo.wheelNeedsPassword = false;

  # ===========================================
  # SSH
  # ===========================================
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ===========================================
  # fail2ban - SSH Protection
  # ===========================================
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.0/8"
      "::1"
      "10.0.0.0/8" # Private network (Class A)
      "172.16.0.0/12" # Private network (Class B)
      "192.168.0.0/16" # Private network (Class C)
      "100.64.0.0/10" # Tailscale subnet
    ];
  };

  # ===========================================
  # Bluetooth
  # ===========================================
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # ===========================================
  # Avahi - mDNS/Bonjour for HomeKit Discovery
  # ===========================================
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Enable mDNS resolution
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      userServices = true;
    };
  };

  # ===========================================
  # Tailscale - Secure Remote Access
  # ===========================================
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  # ===========================================
  # GitOps with Comin
  # ===========================================
  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/Automaat/klaudiusz-smart-home.git";
        branches.main.name = "production"; # Only deploys when CI passes
      }
    ];
  };

  # ===========================================
  # Monitoring - Prometheus
  # ===========================================
  services.prometheus = {
    enable = true;
    port = 9090;
    retentionTime = "15d";
    checkConfig = false; # Disable check - bearer_token_file unavailable at build time

    exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = ["systemd"];
      openFirewall = false;
    };

    exporters.postgres = {
      enable = true;
      port = 9187;
      openFirewall = false;
      runAsLocalSuperUser = true; # Run as postgres user for socket auth
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{targets = ["localhost:9100"];}];
      }
      {
        job_name = "homeassistant";
        static_configs = [{targets = ["localhost:8123"];}];
        metrics_path = "/api/prometheus";
        bearer_token_file = config.sops.secrets."home-assistant-prometheus-token".path;
      }
      {
        job_name = "postgresql";
        static_configs = [{targets = ["localhost:9187"];}];
      }
    ];
  };

  # ===========================================
  # Monitoring - Grafana
  # ===========================================
  # Accessible via Tailscale only (not exposed on public network)
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0"; # Bind to all interfaces (Tailscale can access)
        http_port = 3000;
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{${config.sops.secrets.grafana-admin-password.path}}";
      };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          isDefault = true;
        }
      ];
    };
  };

  # Grafana waits for sops-nix secrets via sops.secrets.<name>.restartUnits
  # No additional systemd dependencies needed

  # ===========================================
  # PostgreSQL Database
  # ===========================================
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = ["hass"];
    ensureUsers = [
      {
        name = "hass";
        ensureDBOwnership = true;
      }
    ];
    # Explicit authentication - prevents setup hanging
    # https://nixos.wiki/wiki/PostgreSQL
    authentication = pkgs.lib.mkOverride 10 ''
      # Local socket connections (required for setup scripts)
      local all all trust
      # IPv4 local connections
      host all all 127.0.0.1/32 trust
      # IPv6 local connections
      host all all ::1/128 trust
    '';
    # Tuned for 16GB RAM, SSD, Intel Celeron N5095
    settings = {
      shared_buffers = "2GB"; # 25% of RAM for small systems
      effective_cache_size = "8GB"; # 50% of RAM
      maintenance_work_mem = "512MB"; # For VACUUM, etc.
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 1.1; # SSD optimization
      effective_io_concurrency = 200; # SSD
      work_mem = "32MB"; # Per operation
      min_wal_size = "1GB";
      max_wal_size = "4GB";
      jit = "on"; # Enable JIT compilation for complex queries
    };
  };

  # ===========================================
  # Systemd Service Hardening
  # ===========================================
  systemd.services = {
    home-assistant.serviceConfig = {
      # Allow connecting to PostgreSQL via socket
      SupplementaryGroups = ["postgres"];
      # Bluetooth capabilities auto-added by NixOS module for bluetooth components
      Restart = "on-failure";
      RestartSec = "10";
    };
    wyoming-faster-whisper-default.serviceConfig.Restart = "on-failure";
    wyoming-piper-default.serviceConfig.Restart = "on-failure";
  };

  # ===========================================
  # Log Rotation (journald)
  # ===========================================
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    SystemMaxFileSize=100M
    MaxRetentionSec=30day
  '';

  # ===========================================
  # Nix Store Maintenance
  # ===========================================
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings.auto-optimise-store = true;

  # ===========================================
  # SSD Optimization
  # ===========================================
  services.fstrim.enable = true; # Weekly TRIM for SSD health

  # ===========================================
  # zram - Compressed RAM swap
  # ===========================================
  zramSwap = {
    enable = true;
    memoryPercent = 25; # 4GB compressed swap from 16GB RAM
  };

  # ===========================================
  # USB devices (Zigbee dongle, etc.)
  # ===========================================
  services.udev.extraRules = ''
    # Zigbee dongles (SONOFF, ConBee, etc.)
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", MODE="0666"
    # Coral USB TPU (if using Frigate)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1a6e", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="18d1", MODE="0666"
    # Bluetooth USB devices (for HA Bluetooth management)
    # Match Bluetooth class (e0=Wireless, 01=RF, 01=Bluetooth) for any BT adapter
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{ID_USB_INTERFACES}=="*:e00101:*", MODE="0660", GROUP="dialout"
  '';

  # ===========================================
  # Packages
  # ===========================================
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
    jq
    lm_sensors # Temperature monitoring
    age # Age encryption for sops
  ];
}
