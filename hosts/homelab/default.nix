{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./home-assistant
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
        10200 # Piper TTS
        10300 # Whisper STT
        3000 # Grafana
      ];
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
      # Add your SSH public key here
      # "ssh-ed25519 AAAA..."
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
        bearer_token_file = "/var/lib/prometheus2/ha-token";
      }
    ];
  };

  # ===========================================
  # Monitoring - Grafana
  # ===========================================
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
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
  # Systemd Service Hardening
  # ===========================================
  systemd.services = {
    home-assistant.serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10";
      WatchdogSec = "300";
    };
    wyoming-faster-whisper-default.serviceConfig.Restart = "on-failure";
    wyoming-piper-default.serviceConfig.Restart = "on-failure";
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
  ];
}
