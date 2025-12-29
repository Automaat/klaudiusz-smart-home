{config, ...}: {
  # ===========================================
  # SOPS Secrets Management
  # ===========================================

  # Age key location (must be created manually on target machine)
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # Default secrets file
  sops.defaultSopsFile = ../../secrets/secrets.yaml;

  # Define secrets and their target paths
  sops.secrets = {
    # Grafana admin password
    "grafana-admin-password" = {
      owner = "grafana";
      mode = "0400";
    };

    # Home Assistant Prometheus token
    "home-assistant-prometheus-token" = {
      owner = "prometheus";
      mode = "0400";
      path = "/var/lib/prometheus2/ha-token";
    };
  };
}
