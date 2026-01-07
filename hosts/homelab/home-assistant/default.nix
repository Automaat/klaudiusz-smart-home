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
  # Better Thermostat
  # ===========================================
  betterThermostatSource = pkgs.fetchFromGitHub {
    owner = "KartoffelToby";
    repo = "better_thermostat";
    # renovate: datasource=github-tags depName=KartoffelToby/better_thermostat
    rev = "1.7.0";
    hash = "sha256-rE14iKAXo3hecK3bQ9MLcOtnZviwjOpYKGlIc4+uCfw=";
  };

  # ===========================================
  # Bubble Card
  # ===========================================
  bubbleCardSource = pkgs.fetchFromGitHub {
    owner = "Clooos";
    repo = "Bubble-Card";
    # renovate: datasource=github-tags depName=Clooos/Bubble-Card
    rev = "v3.1.0-rc.2";
    hash = "sha256-WGe8XAJFYrFxp4KkXefK5ImAnRtgKH9ZhbEC74QRPVY=";
  };

  # ===========================================
  # Mushroom Cards
  # ===========================================
  mushroomCardSource = pkgs.fetchFromGitHub {
    owner = "piitaya";
    repo = "lovelace-mushroom";
    # renovate: datasource=github-tags depName=piitaya/lovelace-mushroom
    rev = "v5.0.9";
    hash = "sha256-E2JHURCRAupP1cKPMA99cBkWnXjDu6uow4hJosqfeHs=";
  };

  # ===========================================
  # Mini Graph Card
  # ===========================================
  miniGraphCardSource = pkgs.fetchFromGitHub {
    owner = "kalkih";
    repo = "mini-graph-card";
    # renovate: datasource=github-tags depName=kalkih/mini-graph-card
    rev = "v0.13.0";
    hash = "sha256-flZfOVY0/xZOL1ZktRGQhRyGAZronLAjpM0zFpc+X1U=";
  };

  # ===========================================
  # Button Card
  # ===========================================
  buttonCardSource = pkgs.fetchFromGitHub {
    owner = "custom-cards";
    repo = "button-card";
    # renovate: datasource=github-tags depName=custom-cards/button-card
    rev = "v7.0.1";
    hash = "sha256-UJ9DzoT0XAWTxUXtnfOrpd0MQihBw9LY7QI0TXEbUNk=";
  };

  # ===========================================
  # card-mod
  # ===========================================
  cardModSource = pkgs.fetchFromGitHub {
    owner = "thomasloven";
    repo = "lovelace-card-mod";
    # renovate: datasource=github-tags depName=thomasloven/lovelace-card-mod
    rev = "14";
    hash = "sha256-w2ky3jSHRbIaTzl0b0aJq4pzuCNUV8GqYsI2U/eoGfs=";
  };

  # ===========================================
  # auto-entities
  # ===========================================
  autoEntitiesSource = pkgs.fetchFromGitHub {
    owner = "thomasloven";
    repo = "lovelace-auto-entities";
    # renovate: datasource=github-tags depName=thomasloven/lovelace-auto-entities
    rev = "v1.16.1";
    hash = "sha256-yMqf4LA/fBTIrrYwacUTb2fL758ZB1k471vdsHAiOj8=";
  };

  # ===========================================
  # Adaptive Lighting
  # ===========================================
  adaptiveLightingSource = pkgs.fetchFromGitHub {
    owner = "basnijholt";
    repo = "adaptive-lighting";
    # renovate: datasource=github-tags depName=basnijholt/adaptive-lighting
    rev = "v1.29.0";
    hash = "sha256-v10Mrc/sSB09mC0UHMhjoEnPhj5S3tISmMcPQrPHPq8=";
  };

  # ===========================================
  # Watchman
  # ===========================================
  watchmanSource = pkgs.fetchFromGitHub {
    owner = "dummylabs";
    repo = "thewatchman";
    # renovate: datasource=github-tags depName=dummylabs/thewatchman
    rev = "v0.6.5";
    hash = "sha256-qMsCkUf8G9oGWHTg1w2j8T5cvmAtk5bmeXEMXRXuOCk=";
  };

  # ===========================================
  # Powercalc
  # ===========================================
  powercalcSource = pkgs.fetchFromGitHub {
    owner = "bramstroker";
    repo = "homeassistant-powercalc";
    # renovate: datasource=github-tags depName=bramstroker/homeassistant-powercalc
    rev = "v1.20.1";
    hash = "sha256-LzXLsKFBDC/Lcdv62kAiQeyc/fu/eH6ukV76jwSb/Es=";
  };

  # ===========================================
  # Custom Conversation (Fallback Agent)
  # ===========================================
  customConversationSource = pkgs.fetchFromGitHub {
    owner = "michelle-avery";
    repo = "custom-conversation";
    # renovate: datasource=github-tags depName=michelle-avery/custom-conversation
    rev = "1.4.0";
    hash = "sha256-y1vOb/hTMMd1iiYazkiKCUT1pBghvtMMwrcrKgs9U1w=";
  };

  # ===========================================
  # Xiaomi Home (Official by Xiaomi)
  # ===========================================
  xiaomiHomeSource = pkgs.fetchFromGitHub {
    owner = "XiaoMi";
    repo = "ha_xiaomi_home";
    # renovate: datasource=github-tags depName=XiaoMi/ha_xiaomi_home
    rev = "v0.4.6";
    hash = "sha256-YvQ9Fzk+WAIqtYyv6j2terPfR3bLer6GgcK1GBdpctg=";
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
    ./kettle.nix
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
      "influxdb" # InfluxDB time-series for Grafana

      # Voice
      "conversation"
      "intent_script"
      "wyoming"

      # Monitoring
      "prometheus" # Metrics export for Grafana
      "command_line" # Service health checks

      # Notifications
      "telegram_bot" # Telegram notifications

      # Task Management
      "todoist" # Todo list integration

      # Zigbee
      "zha" # Zigbee Home Automation

      # Devices
      "hue" # Philips Hue Bridge
      "hue_ble" # Philips Hue Bluetooth (autodiscovered)
      "esphome" # ESPHome devices (Voice Preview Edition)
      "webostv" # LG WebOS TV
      "wake_on_lan" # Wake on LAN for TV power-on
      "homekit_controller" # Aqara FP2 presence sensor
      "homekit" # HomeKit Bridge (expose HA entities to Apple Home)
      "apple_tv" # Apple TV / AirPlay devices
      "cast" # Google Cast / Chromecast
      "xiaomi_ble" # Xiaomi Bluetooth devices
    ];

    extraPackages = ps: let
      customPkgs = mkCustomPythonPackages ps;
    in
      with ps; [
        psycopg2 # PostgreSQL adapter for recorder
        aiogithubapi # Required by HACS
        prettytable # Required by Watchman
        customPkgs.ibeacon-ble # iBeacon integration
        pyatv # Apple TV integration
        pychromecast # Google Cast integration
        zlib-ng # Fast compression for aiohttp (prevents performance warning)

        # Xiaomi Home integration (custom component)
        paho-mqtt # MQTT client for Xiaomi Home
        construct # Binary data parser
        numpy # Numerical computing
        cryptography # Encryption support
        psutil # System utilities

        # Xiaomi BLE integration
        xiaomi-ble # Xiaomi Bluetooth parser
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

      # InfluxDB integration for Grafana dashboards
      influxdb = {
        api_version = 2;
        host = "localhost";
        port = 8086;
        ssl = false;
        organization = "homeassistant";
        bucket = "home-assistant";
        token = "!secret influxdb_token";
        max_retries = 3;
        precision = "s";
      };

      # Wake on LAN (required for send_magic_packet service)
      wake_on_lan = {};

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
    path = [pkgs.jq pkgs.curl]; # Required for command_line sensor commands (jq, curl)

    preStart = lib.mkAfter ''
      cat > /var/lib/hass/secrets.yaml <<EOF
      telegram_bot_token: "123456789:ABCdefGHIjklMNOpqrsTUVwxyz-DUMMY"
      telegram_chat_id: "123456789"
      influxdb_token: "$(cat ${config.sops.secrets.influxdb-admin-token.path})"
      EOF

      # Create HACS symlink (release zip extracts to root)
      ln -sfn ${hacsSource} /var/lib/hass/custom_components/hacs

      # Create Better Thermostat symlink (component is in custom_components/better_thermostat)
      ln -sfn ${betterThermostatSource}/custom_components/better_thermostat /var/lib/hass/custom_components/better_thermostat

      # Create Bubble Card symlink (frontend card in www/community)
      mkdir -p /var/lib/hass/www/community
      ln -sfn ${bubbleCardSource}/dist /var/lib/hass/www/community/bubble-card

      # Create custom card symlinks (dashboard cards)
      ln -sfn ${mushroomCardSource} /var/lib/hass/www/community/mushroom
      ln -sfn ${miniGraphCardSource}/dist /var/lib/hass/www/community/mini-graph-card
      ln -sfn ${buttonCardSource}/dist /var/lib/hass/www/community/button-card
      ln -sfn ${cardModSource} /var/lib/hass/www/community/card-mod
      ln -sfn ${autoEntitiesSource} /var/lib/hass/www/community/auto-entities

      # Create Adaptive Lighting symlink
      ln -sfn ${adaptiveLightingSource}/custom_components/adaptive_lighting /var/lib/hass/custom_components/adaptive_lighting

      # Create Watchman symlink
      ln -sfn ${watchmanSource}/custom_components/watchman /var/lib/hass/custom_components/watchman

      # Create Powercalc symlink
      ln -sfn ${powercalcSource}/custom_components/powercalc /var/lib/hass/custom_components/powercalc

      # Create Custom Conversation symlink
      ln -sfn ${customConversationSource}/custom_components/custom_conversation /var/lib/hass/custom_components/custom_conversation

      # Create Xiaomi Home symlink
      ln -sfn ${xiaomiHomeSource}/custom_components/xiaomi_home /var/lib/hass/custom_components/xiaomi_home
    '';

    # Force derivation update when HA config changes
    # Hash of imported config files ensures Comin detects changes
    environment.HA_CONFIG_HASH = builtins.hashString "sha256" (
      builtins.readFile ./intents.nix
      + builtins.readFile ./automations.nix
      + builtins.readFile ./monitoring.nix
      + builtins.readFile ./kettle.nix
    );

    # Allow USB device access for Bluetooth adapter management
    # bluetooth_auto_recovery accesses /dev/bus/usb/NNN/DDD to reset USB devices
    # Using char-usb_device allows all USB devices (systemd doesn't support path wildcards)
    serviceConfig.DeviceAllow = lib.mkAfter ["char-usb_device rw"];

    # Allow promtail (in hass group) to read log files and /var/lib/hass contents
    # StateDirectory manages /var/lib/hass with specified permissions
    serviceConfig.StateDirectory = "hass";
    # 0750 = owner: rwx, group: r-x, others: ---
    serviceConfig.StateDirectoryMode = lib.mkForce "0750";
  };

  # ===========================================
  # Zigbee USB Device (ZHA)
  # ===========================================
  # User groups configured in users.nix (dialout for serial access)

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
    model = "small"; # Better accuracy for Polish
    language = "pl"; # Force Polish
    device = "cpu";
    uri = "tcp://127.0.0.1:10300"; # Localhost only for security
    beamSize = 5; # Higher quality transcription
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
