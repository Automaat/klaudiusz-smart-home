{
  pkgs,
  self,
  comin,
  sops-nix,
  ...
}:
pkgs.testers.nixosTest {
  name = "homelab-integration-test";

  nodes.homelab = {lib, ...}: {
    # Import the homelab configuration with required modules
    imports = [
      comin.nixosModules.comin
      sops-nix.nixosModules.sops
      ../hosts/homelab
    ];

    # Override nixpkgs settings to use the test's pkgs instance
    # The test framework provides its own nixpkgs, so we force-override
    # both pkgs and config to avoid conflicts
    nixpkgs.pkgs = lib.mkForce pkgs;
    nixpkgs.config = lib.mkForce {};

    # Disable sops-nix for VM tests - use plaintext configs
    # Tests validate system builds & services start, not secret management
    sops.age.generateKey = lib.mkForce false;

    # Override InfluxDB secret owners (influxdb2 user exists but avoid evaluation issues)
    sops.secrets.influxdb-admin-token.owner = lib.mkForce "root";
    sops.secrets.influxdb-admin-password.owner = lib.mkForce "root";

    # Override Grafana to not use sops secret
    services.grafana.settings.security = lib.mkForce {
      admin_user = "admin";
      admin_password = "test-password";
    };

    # Override PostgreSQL settings for VM test (limited memory)
    services.postgresql.settings = lib.mkForce {
      shared_buffers = "128MB";
      effective_cache_size = "256MB";
      maintenance_work_mem = "64MB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "4MB";
      default_statistics_target = 100;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
      work_mem = "4MB";
      min_wal_size = "80MB";
      max_wal_size = "1GB";
      jit = "off"; # Disable JIT in VMs to reduce resource usage
    };

    # Disable Wyoming services (require external model downloads, no network in VM)
    services.wyoming.faster-whisper.servers.default.enable = lib.mkForce false;
    services.wyoming.piper.servers.default.enable = lib.mkForce false;

    # Run real InfluxDB init in VM tests (validates full integration)
    systemd.services.influxdb2-init = let
      cfg = config.sops.secrets;
    in {
      serviceConfig = {
        TimeoutStartSec = lib.mkForce "90s";
        # Disable LoadCredential in tests - read secrets directly
        LoadCredential = lib.mkForce [];
      };
      # Override script to use direct secret paths instead of LoadCredential
      script = lib.mkForce ''
        until influx ping &>/dev/null; do
          echo "Waiting for InfluxDB..."
          sleep 1
        done

        if [ -f /var/lib/influxdb2/.homeassistant-initialized ]; then
          echo "InfluxDB already initialized (marker file present)"
          exit 0
        fi

        if influx setup \
          --org homeassistant \
          --bucket home-assistant \
          --username admin \
          --password $(cat ${cfg.influxdb-admin-password.path}) \
          --token $(cat ${cfg.influxdb-admin-token.path}) \
          --retention 365d \
          --force; then
          touch /var/lib/influxdb2/.homeassistant-initialized
          echo "InfluxDB initialized for Home Assistant"
        else
          echo "InfluxDB initialization failed" >&2
          exit 1
        fi
      '';
    };

    # Override Grafana path-based secret waiting for VM tests
    # In tests, sops creates secrets during activation (before systemd units start)
    # so the path check is redundant and can cause timing issues
    systemd.paths.grafana-secret.enable = lib.mkForce false;
    systemd.services.grafana = {
      after = lib.mkForce [];
      requires = lib.mkForce [];
    };
  };

  testScript = builtins.readFile ./homelab-integration-test.py;
}
