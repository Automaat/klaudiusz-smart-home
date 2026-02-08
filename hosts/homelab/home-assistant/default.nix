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
  # iOS Themes
  # ===========================================
  iosTheme = pkgs.fetchFromGitHub {
    owner = "basnijholt";
    repo = "lovelace-ios-themes";
    # renovate: datasource=github-tags depName=basnijholt/lovelace-ios-themes
    rev = "v3.0.1";
    hash = "sha256-b3AX714qJwJoju9USH2JjUeKp7izgk0p7wqJqvS7J7U=";
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
  mushroomCardSource = pkgs.runCommand "mushroom-card" {} ''
    mkdir -p $out
    ln -s ${pkgs.fetchurl {
      # renovate: datasource=github-releases depName=piitaya/lovelace-mushroom
      url = "https://github.com/piitaya/lovelace-mushroom/releases/download/v5.0.10/mushroom.js";
      hash = "sha256-RYCS5ne5Vr3Y2VyPeP3Y10fwSBAWDOS/gVSrm8qSLHk=";
    }} $out/mushroom.js
  '';

  # ===========================================
  # Mini Graph Card
  # ===========================================
  miniGraphCardSource = pkgs.runCommand "mini-graph-card" {} ''
    mkdir -p $out
    ln -s ${pkgs.fetchurl {
      # renovate: datasource=github-releases depName=kalkih/mini-graph-card
      url = "https://github.com/kalkih/mini-graph-card/releases/download/v0.13.0/mini-graph-card-bundle.js";
      hash = "sha256-TYuYbzzWk8D3dx0vVXQAi8OcRey0UK7AZ5BhUL4t+r0=";
    }} $out/mini-graph-card-bundle.js
  '';

  # ===========================================
  # Button Card
  # ===========================================
  buttonCardSource = pkgs.runCommand "button-card" {} ''
    mkdir -p $out
    ln -s ${pkgs.fetchurl {
      # renovate: datasource=github-releases depName=custom-cards/button-card
      url = "https://github.com/custom-cards/button-card/releases/download/v7.0.1/button-card.js";
      hash = "sha256-XW6cavygHoAUZT+la7XWqpJI2DLDT7lEp/LDYym8ItE=";
    }} $out/button-card.js
  '';

  # ===========================================
  # card-mod
  # ===========================================
  cardModSource = pkgs.fetchFromGitHub {
    owner = "thomasloven";
    repo = "lovelace-card-mod";
    # renovate: datasource=github-tags depName=thomasloven/lovelace-card-mod
    rev = "v4.2.0";
    hash = "sha256-Dvm2i8ll7Fyuw/+7+3a50HJAmWF4PoxnyPcWExP47e8=";
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
  # Hass Hue Icons
  # ===========================================
  hassHueIconsSource = pkgs.fetchFromGitHub {
    owner = "arallsopp";
    repo = "hass-hue-icons";
    # renovate: datasource=github-tags depName=arallsopp/hass-hue-icons
    rev = "v1.2.53";
    hash = "sha256-7ZkaZd4XkGbzb0MA4V/qXJDvSXDq2EsogtsvgJGxNCU=";
  };

  # ===========================================
  # Adaptive Lighting
  # ===========================================
  adaptiveLightingSource = pkgs.fetchFromGitHub {
    owner = "basnijholt";
    repo = "adaptive-lighting";
    # renovate: datasource=github-tags depName=basnijholt/adaptive-lighting
    rev = "v1.30.1";
    hash = "sha256-pmI0jZxIjSiA9P5+0hRCujHE53WprvkAo6jp/IOpJ88=";
  };

  # ===========================================
  # Watchman
  # ===========================================
  watchmanSource = pkgs.fetchFromGitHub {
    owner = "dummylabs";
    repo = "thewatchman";
    # renovate: datasource=github-tags depName=dummylabs/thewatchman
    rev = "v0.8.3";
    hash = "sha256-5BXIKh8uPKuxsLbxu0fUbuCR2LYOXk1HpOvrqehg0u0=";
  };

  # ===========================================
  # Powercalc
  # ===========================================
  powercalcSource = pkgs.fetchFromGitHub {
    owner = "bramstroker";
    repo = "homeassistant-powercalc";
    # renovate: datasource=github-tags depName=bramstroker/homeassistant-powercalc
    rev = "v1.20.3";
    hash = "sha256-z66VHJ/ZzQKvx4l00XGKvTBt9o4T+hv64oCGZNDRUng=";
  };

  # ===========================================
  # Custom Conversation (Fallback Agent)
  # ===========================================
  customConversationSource = pkgs.fetchFromGitHub {
    owner = "michelle-avery";
    repo = "custom-conversation";
    # renovate: datasource=github-tags depName=michelle-avery/custom-conversation
    rev = "1.5.0";
    hash = "sha256-h/ny6A8HTZ85s+wmcVyDdD/UHjwkuPQVkfUQDK6y0rk=";
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
  # History Explorer Card
  # ===========================================
  historyExplorerSource = pkgs.fetchFromGitHub {
    owner = "alexarch21";
    repo = "history-explorer-card";
    # renovate: datasource=github-tags depName=alexarch21/history-explorer-card
    rev = "v1.0.51";
    hash = "sha256-/bPFW6/vqL1aK30WOQxxRV3fuIk7FYnZA+l4ihHpToM=";
  };

  # ===========================================
  # Layout Card
  # ===========================================
  layoutCardSource = pkgs.fetchFromGitHub {
    owner = "thomasloven";
    repo = "lovelace-layout-card";
    # renovate: datasource=github-tags depName=thomasloven/lovelace-layout-card
    rev = "v2.4.7";
    hash = "sha256-xni9cTgv5rdpr+Oo4Zh/d/2ERMiqDiTFGAiXEnigqjc=";
  };

  # ===========================================
  # Mini Media Player
  # ===========================================
  miniMediaPlayerBundle = pkgs.runCommand "mini-media-player-bundle" {} ''
    mkdir -p $out
    ln -s ${pkgs.fetchurl {
      # renovate: datasource=github-releases depName=kalkih/mini-media-player
      url = "https://github.com/kalkih/mini-media-player/releases/download/v1.16.10/mini-media-player-bundle.js";
      hash = "sha256-m9OdXtiCLyGnVXm+hjb7iDJYA81Aa6WymI4LIKmfkiI=";
    }} $out/mini-media-player-bundle.js
  '';

  # ===========================================
  # OpenPlantbook Integration
  # ===========================================
  openPlantbookSource = pkgs.fetchFromGitHub {
    owner = "Olen";
    repo = "home-assistant-openplantbook";
    # renovate: datasource=github-tags depName=Olen/home-assistant-openplantbook
    rev = "v1.3.2";
    hash = "sha256-5AhVnn7umpJ7r68e7FCkaT6E9pG4bNOg1O32PWS5WrI=";
  };

  # ===========================================
  # Plant Component Integration
  # ===========================================
  plantComponentSource = pkgs.fetchFromGitHub {
    owner = "Olen";
    repo = "homeassistant-plant";
    # renovate: datasource=github-tags depName=Olen/homeassistant-plant
    rev = "v2026.2.0";
    hash = "sha256-a3fcl4xhH4itVBmwCTIde/+8m/Q8eS8jSxeaEcDhHwQ=";
  };

  # ===========================================
  # Flower Card
  # ===========================================
  flowerCardSource = pkgs.fetchFromGitHub {
    owner = "Olen";
    repo = "lovelace-flower-card";
    # renovate: datasource=github-tags depName=Olen/lovelace-flower-card
    rev = "v2026.1.1";
    hash = "sha256-X3bdYkdm72ptix69gTmJ3TS4cwAU6HTEUM+m5OmHN/c=";
  };

  # ===========================================
  # Custom ZHA Quirks
  # ===========================================
  customZHAQuirksSource = ./custom_zha_quirks;

  # ===========================================
  # Bermuda BLE Trilateration
  # ===========================================
  bermudaSource = pkgs.fetchFromGitHub {
    owner = "agittins";
    repo = "bermuda";
    # renovate: datasource=github-tags depName=agittins/bermuda
    rev = "v0.8.5";
    hash = "sha256-y5jD3iNPL99NUD3ae9FdXRlw3mvw4kxReZShc1zyPGM=";
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
    ./claude-brain.nix
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
      "airly" # Polish air quality (Airly)
      "radio_browser" # Internet radio
      "cloud" # Home Assistant Cloud (simplifies OAuth for SmartThings; alternative to public HTTPS URL)

      # Database
      "recorder" # PostgreSQL database
      "influxdb" # InfluxDB time-series for Grafana

      # Voice
      "conversation"
      "intent_script"
      "wyoming"
      "stt" # Speech-to-Text platform

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
      "smartthings" # Samsung SmartThings
      "wake_on_lan" # Wake on LAN for TV power-on
      "homekit_controller" # Aqara FP2 presence sensor
      "homekit" # HomeKit Bridge (expose HA entities to Apple Home)
      "apple_tv" # Apple TV / AirPlay devices
      "cast" # Google Cast / Chromecast
      "xiaomi_ble" # Xiaomi Bluetooth devices
      "roborock" # Roborock vacuum integration

      # BLE Tracking
      "bluetooth_adapters" # Required by Bermuda
      "device_tracker" # Required by Bermuda
      "private_ble_device" # iOS randomized MAC handling
    ];

    extraPackages = ps: let
      customPkgs = mkCustomPythonPackages ps;
    in
      with ps; [
        psycopg2 # PostgreSQL adapter for recorder
        aiogithubapi # Required by HACS
        prettytable # Required by Watchman
        customPkgs.ibeacon-ble # iBeacon integration
        customPkgs.kegtron-ble # Kegtron BLE integration
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

        # OpenPlantbook integration (custom component)
        customPkgs.openplantbook-sdk # OpenPlantbook SDK
        customPkgs.json-timeseries # JSON Time Series library
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
        latitude = 50.085196;
        longitude = 19.887609;
        elevation = 210;
        internal_url = "http://192.168.0.241:8123";
        external_url = "https://ha.mskalski.dev";
      };

      # Enable conversation for voice commands
      conversation = {};

      # Frontend with themes
      frontend = {
        themes = "!include_dir_merge_named themes/";
        extra_module_url = [
          "/local/community/hass-hue-icons/hass-hue-icons.js"
        ];
      };

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
        # Cloudflared proxy configuration
        use_x_forwarded_for = true;
        trusted_proxies = ["127.0.0.1" "::1"];
      };

      # Logger
      # Enable debug logging for automation monitoring dashboard
      # Storage impact: ~5-10 MB/day additional log volume
      logger = {
        default = "info";
        logs = {
          "homeassistant.components.automation" = "debug";
          "homeassistant.components.intent_script" = "debug";
          "homeassistant.components.assist_pipeline" = "debug";
          "homeassistant.components.wyoming" = "debug";
          "homeassistant.components.conversation" = "debug";
        };
      };

      # ZHA (Zigbee Home Automation)
      zha = {
        database_path = "/var/lib/hass/zigbee.db";
        custom_quirks_path = "/var/lib/hass/custom_zha_quirks";
        enable_quirks = true;
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

      # Airly integration - configured via UI (see docs/manual-config/airly.md)
      # API key from developer.airly.org, free tier: 1000 req/day

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
    # Themes directory
    "d /var/lib/hass/themes 0755 hass hass -"
    "L+ /var/lib/hass/themes/catppuccin - - - - ${catppuccinTheme}/themes"
    "L+ /var/lib/hass/themes/ios - - - - ${iosTheme}/themes"
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
      ln -sfn ${miniGraphCardSource} /var/lib/hass/www/community/mini-graph-card
      ln -sfn ${buttonCardSource} /var/lib/hass/www/community/button-card
      ln -sfn ${cardModSource} /var/lib/hass/www/community/card-mod
      ln -sfn ${autoEntitiesSource} /var/lib/hass/www/community/auto-entities
      ln -sfn ${hassHueIconsSource}/dist /var/lib/hass/www/community/hass-hue-icons
      ln -sfn ${historyExplorerSource} /var/lib/hass/www/community/history-explorer-card
      ln -sfn ${layoutCardSource} /var/lib/hass/www/community/layout-card
      ln -sfn ${miniMediaPlayerBundle} /var/lib/hass/www/community/mini-media-player

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

      # Create OpenPlantbook integration symlink
      ln -sfn ${openPlantbookSource}/custom_components/openplantbook /var/lib/hass/custom_components/openplantbook

      # Create Plant component symlink
      ln -sfn ${plantComponentSource}/custom_components/plant /var/lib/hass/custom_components/plant

      # Create Flower Card symlink
      ln -sfn ${flowerCardSource} /var/lib/hass/www/community/flower-card

      # Create custom ZHA quirks symlink (Aqara FP300 support)
      ln -sfn ${customZHAQuirksSource} /var/lib/hass/custom_zha_quirks

      # Create Claude Brain component symlink
      ln -sfn ${./custom_components/claude_brain} /var/lib/hass/custom_components/claude_brain

      # Create Bermuda BLE Trilateration symlink
      ln -sfn ${bermudaSource}/custom_components/bermuda /var/lib/hass/custom_components/bermuda
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
