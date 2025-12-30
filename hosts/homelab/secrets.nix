{config, lib, ...}: {
  # ===========================================
  # SOPS Secrets Management
  # ===========================================

  # Age key location
  # For initial setup, using test key from repo (bootstrap mode)
  # TODO: Generate machine-specific key and update .sops.yaml
  sops.age.keyFile = lib.mkDefault "/var/lib/sops-nix/key.txt";

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
