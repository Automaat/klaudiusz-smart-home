{config, lib, ...}: {
  # ===========================================
  # SOPS Secrets Management
  # ===========================================

  # Age key location
  # Using test key from repo for out-of-box setup
  # For production: generate machine key, update .sops.yaml, re-encrypt, change this path
  sops.age.keyFile = ../../tests/age-key.txt;

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
  };
}
