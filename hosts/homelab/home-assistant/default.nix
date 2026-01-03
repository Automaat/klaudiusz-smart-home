{
  config,
  pkgs,
  lib,
  ...
}: let
  # ===========================================
  # HACS (Home Assistant Community Store)
  # ===========================================
  hacsSource = pkgs.fetchzip {
    url = "https://github.com/hacs/integration/releases/download/2.0.5/hacs.zip";
    hash = "sha256-iMomioxH7Iydy+bzJDbZxt6BX31UkCvqhXrxYFQV8Gw=";
    stripRoot = false;
  };

  # ===========================================
  # Catppuccin Theme
  # ===========================================
  catppuccinTheme = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "home-assistant";
    # renovate: datasource=github-tags depName=catppuccin/home-assistant
    rev = "v2.1.2";
    hash = "sha256-4knJI+3Bo+uRL+NAVt5JrI3PcsZjANozyXvRRR5aNjM=";
  };

  # ===========================================
  # Custom Python Packages
  # ===========================================
  # Function that builds custom packages with HA's Python environment
  mkCustomPythonPackages = python3Packages: import ./python-packages.nix {inherit pkgs lib python3Packages;};
in {
  imports = [
    ./intents.nix
    ./automations.nix
    ./monitoring.nix
  ];

  # ===========================================
  # Home Assistant
  # ===========================================
  services.home-assistant = {
    enable = true;

    extraComponents = [
      # Core
      "default_config"
      "zeroconf" # mDNS/Bonjour for device discovery (HomeKit, etc.)
      "met" # Weather
      "gios" # Polish air quality (GIOŚ)
      "radio_browser" # Internet radio

      # Database
      "recorder" # PostgreSQL database

      # Voice
      "conversation"
      "intent_script"
      "wyoming"

      # Monitoring
      "prometheus" # Metrics export for Grafana
      "command_line" # Service health checks

      # Notifications
      "telegram_bot" # Telegram notifications

      # Zigbee
      "zha" # Zigbee Home Automation

      # Devices
      "hue" # Philips Hue Bridge
      "esphome" # ESPHome devices (Voice Preview Edition)
      "webostv" # LG WebOS TV
      "wake_on_lan" # Wake on LAN for TV power-on
      "homekit_controller" # Aqara FP2 presence sensor
      # "cast"           # Google Cast
    ];

    extraPackages = ps: let
      customPkgs = mkCustomPythonPackages ps;
    in
      with ps; [
        psycopg2 # PostgreSQL adapter for recorder
        aiogithubapi # Required by HACS
        customPkgs.ibeacon-ble # iBeacon integration
      ];

    config = {
      # default_config includes bluetooth integration
      default_config = {};

      homeassistant = {
        name = "Dom";
        unit_system = "metric";
        currency = "PLN";
        country = "PL";
        language = "pl";
        time_zone = "Europe/Warsaw";
        latitude = 50.083;
        longitude = 19.891;
        elevation = 210;
      };

      # Enable conversation for voice commands
      conversation = {};

      # Frontend with themes
      frontend.themes = "!include_dir_merge_named themes/";

      # Database recorder (PostgreSQL)
      recorder = {
        db_url = "postgresql://@/hass";
        purge_keep_days = 30;
        commit_interval = 1;

        exclude = {
          domains = [
            "updater"
          ];
          entities = [
            "sensor.last_boot"
            "sensor.date"
            "sensor.time"
          ];
          entity_globs = [
            "sensor.uptime"
            "sensor.*_latest_version"
          ];
          event_types = [
            "call_service"
          ];
        };
      };

      # HTTP config (for reverse proxy if needed)
      http = {
        server_port = 8123;
        # Uncomment for reverse proxy
        # use_x_forwarded_for = true;
        # trusted_proxies = [ "127.0.0.1" "::1" ];
      };

      # Logger
      logger = {
        default = "info";
        logs = {
          "homeassistant.components.intent_script" = "debug";
          "homeassistant.components.assist_pipeline" = "debug";
          "homeassistant.components.wyoming" = "debug";
          "homeassistant.components.conversation" = "debug";
        };
      };

      # ZHA (Zigbee Home Automation)
      zha = {
        database_path = "/var/lib/hass/zigbee.db";
      };

      # Telegram integration - configured via UI (see docs/manual-config/telegram.md)
      # Entity: notify.klaudiusz_smart_home_system (use with notify.send_message action)
    };

    # Allow GUI automations and dashboard edits
    configWritable = true;
    lovelaceConfigWritable = true;
  };

  # ===========================================
  # Additional Themes & Directories
  # ===========================================
  systemd.tmpfiles.rules = [
    # HACS symlink managed by customComponents above
    "L+ /var/lib/hass/themes - - - - ${catppuccinTheme}/themes"
    "d /var/lib/hass/blueprints 0755 hass hass -"
    # Create secrets.yaml with correct ownership (written by preStart)
    "f /var/lib/hass/secrets.yaml 0600 hass hass -"
    # Polish custom sentences
    "L+ /var/lib/hass/custom_sentences - - - - ${../../../custom_sentences}"
    # Comin deployment state tracking (monitoring.nix sensors)
    "f /var/lib/hass/.comin_last_success_uuid 0600 hass hass -"
    "f /var/lib/hass/.comin_last_failed_uuid 0600 hass hass -"
    "f /var/lib/hass/.comin_last_success_uuid.lock 0600 hass hass -"
    "f /var/lib/hass/.comin_last_failed_uuid.lock 0600 hass hass -"
  ];

  # ===========================================
  # Home Assistant Secrets & HACS
  # ===========================================
  # Write secrets.yaml and create HACS symlink before HA starts
  # File ownership set by tmpfiles.rules above (avoids chown in VM tests)
  # HACS symlink created after Nix-managed preStart removes /nix/store symlinks
  systemd.services.home-assistant = {
    preStart = lib.mkAfter ''
      cat > /var/lib/hass/secrets.yaml <<EOF
      telegram_bot_token: "123456789:ABCdefGHIjklMNOpqrsTUVwxyz-DUMMY"
      telegram_chat_id: "123456789"
      EOF

      # Create HACS symlink (release zip extracts to root)
      ln -sfn ${hacsSource} /var/lib/hass/custom_components/hacs
    '';

    # Force derivation update when HA config changes
    # Hash of imported config files ensures Comin detects changes
    environment.HA_CONFIG_HASH = builtins.hashString "sha256" (
      builtins.readFile ./intents.nix
      + builtins.readFile ./automations.nix
      + builtins.readFile ./monitoring.nix
    );
  };

  # ===========================================
  # Zigbee USB Device (ZHA)
  # ===========================================
  # Add hass user to dialout group for serial port access
  users.users.hass.extraGroups = ["dialout"];

  # Create persistent /dev/zigbee symlink for Connect ZBT-2
  # Espressif ESP32 (Nabu Casa ZBT-2: 303a:831a)
  # Auto-start Home Assistant when dongle appears
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="831a", SYMLINK+="zigbee", TAG+="systemd", ENV{SYSTEMD_WANTS}="home-assistant.service"
  '';

  # ===========================================
  # Polish Speech-to-Text (Whisper)
  # ===========================================
  services.wyoming.faster-whisper.servers.default = {
    enable = true;
    model = "base"; # Balanced speed/accuracy for Polish
    language = "pl"; # Force Polish
    device = "cpu";
    uri = "tcp://127.0.0.1:10300"; # Localhost only for security
    beamSize = 3; # Balance quality/performance
    extraArgs = [
      "--compute-type"
      "int8" # CPU-compatible quantization (N5095 lacks AVX512 for int8_float16)
    ];
  };

  # ===========================================
  # Polish Text-to-Speech (Piper)
  # ===========================================
  services.wyoming.piper.servers.default = {
    enable = true;
    voice = "pl_PL-darkman-medium";
    uri = "tcp://127.0.0.1:10200"; # Localhost only for security
  };
}
