{
  config,
  lib,
  ...
}: let
  # Cloudflare Tunnel ID (must match hosts/homelab/default.nix)
  cloudflareTunnelId = "c0350983-f7b9-4770-ac96-34b8a5184c91";
in {
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
  # User/group memberships configured in users.nix
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

    # Deepgram API key (Speech-to-Text)
    "deepgram-api-key" = {
      owner = "hass";
      mode = "0400";
      restartUnits = ["home-assistant.service"];
    };

    # InfluxDB admin token (API authentication)
    # Group: influxdb-readers (hass + grafana)
    "influxdb-admin-token" = {
      group = "influxdb-readers";
      mode = "0440";
      restartUnits = ["influxdb2.service" "grafana.service" "home-assistant.service"];
    };

    # InfluxDB admin password (user authentication, separate for independent rotation)
    "influxdb-admin-password" = {
      owner = "influxdb2";
      mode = "0400";
      restartUnits = ["influxdb2.service"];
    };

    # Cloudflared tunnel credentials (root-owned, service has access)
    "cloudflared/credentials" = {
      mode = "0400";
      restartUnits = ["cloudflared-tunnel-${cloudflareTunnelId}.service"];
    };

    # ProtonVPN WireGuard config
    "protonvpn-wg-conf" = {
      format = "binary";
      sopsFile = ../../secrets/protonvpn-wg.conf;
      mode = "0400";
      restartUnits = ["transmission-port-forwarding.service"];
    };
  };
}
