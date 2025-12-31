{
  config,
  pkgs,
  lib,
  ...
}: let
  # ===========================================
  # HACS (Home Assistant Community Store)
  # ===========================================
  hacsSource = pkgs.fetchFromGitHub {
    owner = "hacs";
    repo = "integration";
    rev = "2.0.1";
    hash = "sha256-MENOK7tnblBKmCFncS0EFiA1oqQeK4OtQpEmjYF9gWQ=";
  };

  # ===========================================
  # Catppuccin Theme
  # ===========================================
  catppuccinTheme = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "home-assistant";
    rev = "v2.1.2";
    hash = "sha256-4knJI+3Bo+uRL+NAVt5JrI3PcsZjANozyXvRRR5aNjM=";
  };
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
      "met" # Weather
      "radio_browser" # Internet radio

      # Database
      "recorder" # PostgreSQL database

      # Voice
      "conversation"
      "intent_script"
      "wyoming"

      # Monitoring
      "prometheus" # Metrics export for Grafana
      "systemmonitor" # System resource monitoring
      "command_line" # Service health checks

      # Notifications
      # "telegram_bot" # Telegram notifications (disabled)

      # Devices (uncomment as needed)
      # "zha"            # Zigbee Home Automation
      # "mqtt"           # MQTT
      # "esphome"        # ESPHome devices
      # "hue"            # Philips Hue
      # "cast"           # Google Cast
    ];

    extraPackages = ps:
      with ps; [
        psycopg2 # PostgreSQL adapter for recorder
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
        # Coordinates (Warsaw example - change to your location)
        latitude = 52.2297;
        longitude = 21.0122;
        elevation = 100;
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
        };
      };

      # Telegram Bot (disabled)
      # telegram_bot = [
      #   {
      #     platform = "polling";
      #     api_key = "!secret telegram_bot_token";
      #     allowed_chat_ids = ["!secret telegram_chat_id"];
      #   }
      # ];

      # Telegram Notify (disabled)
      # notify = [
      #   {
      #     platform = "telegram";
      #     name = "telegram";
      #     chat_id = "!secret telegram_chat_id";
      #   }
      # ];
    };

    # Allow GUI automations and dashboard edits
    configWritable = true;
    lovelaceConfigWritable = true;
  };

  # ===========================================
  # HACS Installation
  # ===========================================
  systemd.tmpfiles.rules = [
    # Create parent directories first with correct ownership
    "d /var/lib/hass/custom_components 0755 hass hass -"
    "L+ /var/lib/hass/custom_components/hacs - - - - ${hacsSource}/custom_components/hacs"
    "L+ /var/lib/hass/themes - - - - ${catppuccinTheme}/themes"
    "d /var/lib/hass/blueprints 0755 hass hass -"
    # Create secrets.yaml with correct ownership (written by preStart)
    "f /var/lib/hass/secrets.yaml 0600 hass hass -"
  ];

  # ===========================================
  # Home Assistant Secrets
  # ===========================================
  # Write secrets.yaml before HA starts
  # File ownership set by tmpfiles.rules above (avoids chown in VM tests)
  systemd.services.home-assistant.preStart = lib.mkAfter ''
    cat > /var/lib/hass/secrets.yaml <<EOF
    telegram_bot_token: "123456789:ABCdefGHIjklMNOpqrsTUVwxyz-DUMMY"
    telegram_chat_id: "123456789"
    EOF
  '';

  # ===========================================
  # Polish Speech-to-Text (Whisper)
  # ===========================================
  services.wyoming.faster-whisper.servers.default = {
    enable = true;
    model = "small"; # Good Polish accuracy
    language = "pl"; # Force Polish
    device = "cpu";
    uri = "tcp://127.0.0.1:10300"; # Localhost only for security
  };

  # ===========================================
  # Polish Text-to-Speech (Piper)
  # ===========================================
  services.wyoming.piper.servers.default = {
    enable = true;
    voice = "pl_PL-darkman-medium";
    uri = "tcp://127.0.0.1:10200"; # Localhost only for security
  };

  # ===========================================
  # MQTT Broker (optional - uncomment if needed)
  # ===========================================
  # services.mosquitto = {
  #   enable = true;
  #   listeners = [{
  #     port = 1883;
  #     users = {
  #       homeassistant = {
  #         acl = [ "readwrite #" ];
  #         hashedPasswordFile = "/run/secrets/mosquitto-ha-password";
  #       };
  #     };
  #   }];
  # };

  # ===========================================
  # Zigbee2MQTT (optional - uncomment if needed)
  # ===========================================
  # services.zigbee2mqtt = {
  #   enable = true;
  #   settings = {
  #     homeassistant = true;
  #     permit_join = false;
  #     serial.port = "/dev/zigbee";
  #     mqtt = {
  #       server = "mqtt://localhost:1883";
  #       user = "homeassistant";
  #       password = "!secret mqtt_password";
  #     };
  #     frontend.port = 8080;
  #   };
  # };
}
