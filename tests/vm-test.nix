{
  pkgs,
  self,
  comin,
  sops-nix,
  ...
}:
pkgs.testers.nixosTest {
  name = "homelab-integration-test";

  nodes.homelab = {
    config,
    lib,
    ...
  }: {
    # Import the homelab configuration with required modules
    imports = [
      comin.nixosModules.comin
      sops-nix.nixosModules.sops
      ../hosts/homelab
    ];

    # VM resource limits (paperless-ngx stack requires more memory)
    virtualisation.memorySize = 4096; # 4GB - needed for HA + PostgreSQL + Paperless + monitoring
    virtualisation.cores = 4; # Parallel processing for faster tests

    # Override nixpkgs settings to use the test's pkgs instance
    # The test framework provides its own nixpkgs, so we force-override
    # both pkgs and config to avoid conflicts
    nixpkgs.pkgs = lib.mkForce pkgs;
    nixpkgs.config = lib.mkForce {};

    # Disable sops-nix for VM tests - use plaintext configs
    # Tests validate system builds & services start, not secret management
    sops.age.generateKey = lib.mkForce false;

    # Override Grafana to not use sops secrets
    services.grafana.settings.security = lib.mkForce {
      admin_user = "admin";
      admin_password = "test-password";
    };
    services.grafana.provision.datasources = lib.mkForce {
      settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          isDefault = true;
          uid = "prometheus";
        }
        {
          name = "InfluxDB";
          type = "influxdb";
          url = "http://localhost:8086";
          isDefault = false;
          uid = "influxdb";
          jsonData = {
            version = "Flux";
            organization = "homeassistant";
            defaultBucket = "home-assistant";
          };
          secureJsonData = {
            token = "test-token";
          };
        }
        {
          name = "Loki";
          type = "loki";
          url = "http://localhost:3100";
          uid = "loki";
          jsonData = {
            maxLines = 1000;
          };
        }
      ];
    };

    # Override PostgreSQL settings for VM test (limited memory)
    services.postgresql.settings = lib.mkForce {
      shared_buffers = "256MB"; # Increased for paperless migrations
      effective_cache_size = "512MB"; # Increased for paperless migrations
      maintenance_work_mem = "128MB"; # Increased for paperless migrations
      checkpoint_completion_target = 0.9;
      wal_buffers = "8MB"; # Increased for paperless migrations
      default_statistics_target = 100;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
      work_mem = "8MB"; # Increased for paperless migrations
      min_wal_size = "80MB";
      max_wal_size = "1GB";
      jit = "off"; # Disable JIT in VMs to reduce resource usage
    };

    # Disable Wyoming services (require external model downloads, no network in VM)
    services.wyoming.faster-whisper.servers.default.enable = lib.mkForce false;
    services.wyoming.piper.servers.default.enable = lib.mkForce false;

    # Disable cloudflared in VM tests (external tunnel, requires real Cloudflare credentials)
    services.cloudflared.enable = lib.mkForce false;

    # Disable avahi-alias service in VM tests (mDNS conflicts in isolated VM network)
    systemd.services.avahi-alias-homeassistant.enable = lib.mkForce false;

    # Disable CrowdSec firewall bouncer in VM tests (iptables/nftables not available in VM)
    services.crowdsec-firewall-bouncer.enable = lib.mkForce false;

    # Override Paperless-ngx to use test credentials (no sops paths)
    services.paperless = {
      passwordFile = lib.mkForce (builtins.toFile "paperless-password" "test-password");
      settings.PAPERLESS_SECRET_KEY_FILE = lib.mkForce (builtins.toFile "paperless-secret" "test-secret-key-do-not-use-in-production");
    };

    # Run InfluxDB init in VM tests with hardcoded credentials
    systemd.services.influxdb2-init = {
      serviceConfig = {
        TimeoutStartSec = lib.mkForce "90s";
        # Disable LoadCredential in tests - use hardcoded values
        LoadCredential = lib.mkForce [];
      };
      # Override script with inline test credentials (no sops paths)
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
          --password test-password \
          --token test-token \
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

    # Override Promtail hardening for VM tests (namespace features not available)
    systemd.services.promtail.serviceConfig = {
      # Disable namespace features causing "status=226/NAMESPACE" failure
      PrivateTmp = lib.mkForce false;
      PrivateDevices = lib.mkForce false;
      PrivateMounts = lib.mkForce false;
      ProtectHome = lib.mkForce false;
      ProtectSystem = lib.mkForce false;
      ProtectKernelTunables = lib.mkForce false;
      ProtectKernelModules = lib.mkForce false;
      ProtectControlGroups = lib.mkForce false;
      RestrictAddressFamilies = lib.mkForce [];
      RestrictNamespaces = lib.mkForce false;
      LockPersonality = lib.mkForce false;
      MemoryDenyWriteExecute = lib.mkForce false;
      RestrictRealtime = lib.mkForce false;
      RestrictSUIDSGID = lib.mkForce false;
      SystemCallArchitectures = lib.mkForce "";
      MountFlags = lib.mkForce "";
    };
  };

  testScript = builtins.readFile ./homelab-integration-test.py;
}
