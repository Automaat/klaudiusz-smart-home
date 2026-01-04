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

    # InfluxDB admin token (API authentication)
    # Owner: hass (HA needs read access, Grafana accesses via systemd DynamicUser)
    "influxdb-admin-token" = {
      owner = "hass";
      mode = "0400";
      restartUnits = ["influxdb2.service" "grafana.service" "home-assistant.service"];
    };

    # InfluxDB admin password (user authentication, separate for independent rotation)
    "influxdb-admin-password" = {
      owner = "influxdb2";
      mode = "0400";
      restartUnits = ["influxdb2.service"];
    };
  };
}
