{config, ...}: {
  # ===========================================
  # Grafana Configuration
  # ===========================================
  # Accessible on local network (192.168.0.241:3000) and Tailscale
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0"; # Bind to all interfaces (Tailscale can access)
        http_port = 3000;
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{${config.sops.secrets.grafana-admin-password.path}}";
      };
    };
    provision = {
      enable = true;

      # Datasources
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          isDefault = true;
          uid = "prometheus"; # Explicit UID for dashboard references
        }
      ];

      # Dashboard Provisioning
      dashboards.settings.providers = [
        {
          name = "Infrastructure";
          disableDeletion = true; # Prevent GUI deletion
          options = {
            path = ./dashboards/infrastructure;
            foldersFromFilesStructure = true;
          };
        }
        {
          name = "Smart Home";
          disableDeletion = true;
          options = {
            path = ./dashboards/smart-home;
            foldersFromFilesStructure = true;
          };
        }
        {
          name = "Services";
          disableDeletion = true;
          options = {
            path = ./dashboards/services;
            foldersFromFilesStructure = true;
          };
        }
      ];
    };
  };

  # Grafana waits for sops-nix secrets via sops.secrets.<name>.restartUnits
  # (configured in sops section of main config)
}
