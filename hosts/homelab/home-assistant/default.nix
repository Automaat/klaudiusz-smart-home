{ config, pkgs, lib, ... }:

let
  # ===========================================
  # HACS (Home Assistant Community Store)
  # ===========================================
  hacsSource = pkgs.fetchFromGitHub {
    owner = "hacs";
    repo = "integration";
    rev = "2.0.1";
    hash = "sha256-VIz77S23CW/82VRn1q41BfPdMpGmJq02Jil5H4mXJlU=";
  };
in
{
  imports = [
    ./intents.nix
    ./automations.nix
  ];

  # ===========================================
  # Home Assistant
  # ===========================================
  services.home-assistant = {
    enable = true;

    extraComponents = [
      # Core
      "default_config"
      "met"              # Weather
      "radio_browser"    # Internet radio

      # Voice
      "conversation"
      "intent_script"
      "wyoming"

      # Devices (uncomment as needed)
      # "zha"            # Zigbee Home Automation
      # "mqtt"           # MQTT
      # "esphome"        # ESPHome devices
      # "hue"            # Philips Hue
      # "cast"           # Google Cast
    ];

    config = {
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
    };

    # Allow GUI automations and dashboard edits
    configWritable = true;
    lovelaceConfigWritable = true;
  };

  # ===========================================
  # HACS Installation
  # ===========================================
  systemd.tmpfiles.rules = [
    "L+ /var/lib/hass/custom_components/hacs - - - - ${hacsSource}/custom_components/hacs"
  ];

  # ===========================================
  # Polish Speech-to-Text (Whisper)
  # ===========================================
  services.wyoming.faster-whisper.servers.default = {
    enable = true;
    model = "small";      # Good Polish accuracy
    language = "pl";      # Force Polish
    device = "cpu";
    uri = "tcp://0.0.0.0:10300";
  };

  # ===========================================
  # Polish Text-to-Speech (Piper)
  # ===========================================
  services.wyoming.piper.servers.default = {
    enable = true;
    voice = "pl_PL-darkman-medium";
    uri = "tcp://0.0.0.0:10200";
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
