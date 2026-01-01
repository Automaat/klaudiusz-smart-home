{
  config,
  lib,
  ...
}: {
  # ===========================================
  # SOPS Secrets Management
  # ===========================================

  # Age key auto-generation (VM tests override with lib.mkForce)
  # First install: run scripts/setup-secrets.sh to generate key + encrypt secrets
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.generateKey = true;

  # Default secrets file
  sops.defaultSopsFile = ../../secrets/secrets.yaml;

  # Define secrets and their target paths
  sops.secrets = {
    # Grafana admin password
    "grafana-admin-password" = {
      owner = "grafana";
      mode = "0400";
      restartUnits = ["grafana.service"];
    };

    # Home Assistant Prometheus token
    "home-assistant-prometheus-token" = {
      owner = "prometheus";
      mode = "0400";
      restartUnits = ["prometheus.service"];
    };

    # Telegram bot token
    "telegram-bot-token" = {
      owner = "hass";
      mode = "0400";
      restartUnits = ["home-assistant.service"];
    };

    # Telegram chat ID
    "telegram-chat-id" = {
      owner = "hass";
      mode = "0400";
      restartUnits = ["home-assistant.service"];
    };

    # MQTT password for Home Assistant/Zigbee2MQTT
    "mosquitto-ha-password" = {
      owner = "mosquitto";
      group = "hass";
      mode = "0440";
      restartUnits = ["mosquitto.service" "zigbee2mqtt.service" "home-assistant.service"];
    };

    # Zigbee2MQTT frontend authentication token
    "zigbee2mqtt-frontend-token" = {
      owner = "zigbee2mqtt";
      mode = "0400";
      restartUnits = ["zigbee2mqtt.service"];
    };
  };
}
