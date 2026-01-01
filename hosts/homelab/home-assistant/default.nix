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
    url = "https://github.com/hacs/integration/releases/download/2.0.1/hacs.zip";
    hash = "sha256-eKTdksAKEU07y9pbHmTBl1d8L25eP/Y4VlYLubQRDmo=";
    stripRoot = false;
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

      # Zigbee
      # "zha" # Zigbee Home Automation (disabled - using Zigbee2MQTT)

      # Devices
      "mqtt" # MQTT for Zigbee2MQTT
      # "esphome"        # ESPHome devices
      # "hue"            # Philips Hue
      # "cast"           # Google Cast
    ];

    extraPackages = ps:
      with ps; [
        psycopg2 # PostgreSQL adapter for recorder
        aiogithubapi # Required by HACS
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

      # MQTT (for Zigbee2MQTT)
      mqtt = {
        broker = "127.0.0.1";
        port = 1883;
        username = "homeassistant";
        password = "!secret mqtt_password";
      };
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
  ];

  # ===========================================
  # Home Assistant Secrets & HACS
  # ===========================================
  # Write secrets.yaml and create HACS symlink before HA starts
  # File ownership set by tmpfiles.rules above (avoids chown in VM tests)
  # HACS symlink created after Nix-managed preStart removes /nix/store symlinks
  systemd.services.home-assistant.preStart = lib.mkAfter ''
    cat > /var/lib/hass/secrets.yaml <<EOF
    telegram_bot_token: "123456789:ABCdefGHIjklMNOpqrsTUVwxyz-DUMMY"
    telegram_chat_id: "123456789"
    mqtt_password: $(cat ${config.sops.secrets."mosquitto-ha-password".path})
    EOF

    # Create HACS symlink (release zip extracts to root)
    ln -sfn ${hacsSource} /var/lib/hass/custom_components/hacs
  '';

  # ===========================================
  # Zigbee USB Device
  # ===========================================
  # Add zigbee2mqtt user to dialout group for serial port access
  users.users.zigbee2mqtt.extraGroups = ["dialout"];

  # Create persistent /dev/zigbee symlink for Connect ZBT-2
  # Espressif ESP32 (Nabu Casa ZBT-2: 303a:831a)
  # Auto-start Zigbee2MQTT when dongle appears
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="831a", SYMLINK+="zigbee", TAG+="systemd", ENV{SYSTEMD_WANTS}="zigbee2mqtt.service"
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
  # MQTT Broker (Mosquitto)
  # ===========================================
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        port = 1883;
        users = {
          homeassistant = {
            acl = ["readwrite #"];
            hashedPasswordFile = config.sops.secrets."mosquitto-ha-password".path;
          };
        };
      }
    ];
  };

  # ===========================================
  # Zigbee2MQTT
  # ===========================================
  services.zigbee2mqtt = {
    enable = true;
    settings = {
      homeassistant.enabled = true; # Enable auto-discovery
      permit_join = false;
      serial = {
        port = "/dev/zigbee";
        # Let zigbee2mqtt auto-detect adapter type
      };
      mqtt = {
        server = "mqtt://localhost:1883";
        user = "homeassistant";
        # Password injected via environment variable
      };
      frontend = {
        port = 8080;
        host = "0.0.0.0"; # Local network access
        auth_token = "!secret zigbee2mqtt_frontend_token";
      };
    };
  };

  # Zigbee2MQTT systemd service configuration
  systemd.services.zigbee2mqtt = {
    # Ensure proper startup order
    after = ["mosquitto.service"];
    requires = ["mosquitto.service"];

    # Inject MQTT password via environment variable at runtime
    # Create secret.yaml for frontend auth token
    # Note: preStart runs as zigbee2mqtt user, use serviceConfig for root access
    serviceConfig = {
      RuntimeDirectory = "zigbee2mqtt";
      EnvironmentFile = "-/run/zigbee2mqtt/env"; # - prefix makes optional
      # Run preStart as root to read secrets (+ prefix)
      ExecStartPre = lib.mkBefore [
        ("+" + (pkgs.writeShellScript "zigbee2mqtt-setup-secrets" ''
          mkdir -p /run/zigbee2mqtt
          echo "ZIGBEE2MQTT_CONFIG_MQTT_PASSWORD=$(cat ${config.sops.secrets."mosquitto-ha-password".path})" > /run/zigbee2mqtt/env
          chown zigbee2mqtt:zigbee2mqtt /run/zigbee2mqtt/env

          # Create secret.yaml in data directory for frontend auth
          cat > ${config.services.zigbee2mqtt.dataDir}/secret.yaml <<EOF
          zigbee2mqtt_frontend_token: $(cat ${config.sops.secrets."zigbee2mqtt-frontend-token".path})
          EOF
          chown zigbee2mqtt:zigbee2mqtt ${config.services.zigbee2mqtt.dataDir}/secret.yaml
          chmod 600 ${config.services.zigbee2mqtt.dataDir}/secret.yaml
        ''))
      ];
    };
  };
}
