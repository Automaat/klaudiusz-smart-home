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
      # Allow Tailscale traffic
      trustedInterfaces = ["tailscale0"];
      # Allow Tailscale UDP port
      allowedUDPPorts = [config.services.tailscale.port];
    };
  };

  # ===========================================
  # Locale & Time
  # ===========================================
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "pl_PL.UTF-8";
  console.keyMap = "pl";

  # ===========================================
  # Users
  # ===========================================
  users.users.admin = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "dialout"]; # dialout for Zigbee USB
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINWvJJYnZUGjjsz4AucVipikJcvDxtthgcG/DWL0OXwv skalskimarcin33@gmail.com"
    ];
  };

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
      "100.64.0.0/10" # Tailscale subnet
    ];
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
        branches.main.name = "main";
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

    exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = ["systemd"];
      openFirewall = false;
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
        # Token managed by sops-nix (secrets/secrets.yaml: home-assistant-prometheus-token)
        # Create token in HA: Settings > People > Admin > Security > Long-lived access tokens
        bearer_token_file = config.sops.secrets."home-assistant-prometheus-token".path;
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
        admin_password = config.sops.secrets."grafana-admin-password".path;
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
    };
  };

  # ===========================================
  # Systemd Service Hardening
  # ===========================================
  systemd.services = {
    home-assistant.serviceConfig = {
      # Allow connecting to PostgreSQL via socket
      SupplementaryGroups = ["postgres"];
      Restart = "on-failure";
      RestartSec = "10";
      WatchdogSec = "300";
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
  ];
}
