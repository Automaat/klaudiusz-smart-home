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

    # Use dummy secrets for testing (encrypted with test key)
    sops.defaultSopsFile = lib.mkForce ./secrets.yaml;
    sops.age.keyFile = lib.mkForce "/var/lib/sops-nix/test-key.txt";
    sops.age.generateKey = lib.mkForce false;

    # Create test key file at boot (before sops activation)
    system.activationScripts.createTestKey = lib.stringAfter ["etc"] ''
      mkdir -p /var/lib/sops-nix
      cat > /var/lib/sops-nix/test-key.txt <<'EOF'
      ${builtins.readFile ./age-key.txt}
      EOF
      chmod 600 /var/lib/sops-nix/test-key.txt
    '';

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
  };

  testScript = ''
    # Start the machine
    homelab.start()

    # Wait for systemd to be ready
    homelab.wait_for_unit("multi-user.target")

    # =============================================
    # Critical Service Checks
    # =============================================

    # Home Assistant
    homelab.wait_for_unit("home-assistant.service")
    homelab.wait_for_open_port(8123)
    homelab.succeed("curl -f http://localhost:8123/manifest.json")

    # PostgreSQL (for HA recorder)
    homelab.wait_for_unit("postgresql.service")

    # Prometheus
    homelab.wait_for_unit("prometheus.service")
    homelab.wait_for_open_port(9090)
    homelab.succeed("curl -f http://localhost:9090/-/healthy")

    # Grafana
    try:
        homelab.wait_for_unit("grafana.service")
    except Exception as e:
        print(f"Grafana service failed to start: {e}")
        print(homelab.succeed("journalctl -u grafana.service -n 50 --no-pager"))
        raise
    homelab.wait_for_open_port(3000)
    homelab.succeed("curl -f http://localhost:3000/api/health")

    # Comin (GitOps)
    homelab.wait_for_unit("comin.service")

    # =============================================
    # Service Health Checks
    # =============================================

    # Check no failed units
    homelab.succeed("[ $(systemctl list-units --state=failed --no-legend | wc -l) -eq 0 ]")

    # Check home-assistant can access PostgreSQL
    homelab.succeed("sudo -u hass psql -d hass -c 'SELECT 1' > /dev/null")

    # =============================================
    # Home Assistant Log Validation
    # =============================================

    # Check for missing Python module errors (exclude known missing packages)
    # ibeacon_ble and ha_silabs_firmware_client not in nixpkgs, errors are non-fatal
    homelab.fail("journalctl -u home-assistant -n 200 | grep -i 'ModuleNotFoundError' | grep -v 'ibeacon_ble' | grep -v 'ha_silabs_firmware_client'")

    # Check for integration loading failures (exclude known issues)
    homelab.fail("journalctl -u home-assistant -n 200 | grep -i 'Error occurred loading flow for integration' | grep -v 'ibeacon' | grep -v 'homeassistant_connect_zbt2'")

    # Check for UnknownHandler exceptions (exclude known issues)
    homelab.fail("journalctl -u home-assistant -n 200 | grep -i 'homeassistant.data_entry_flow.UnknownHandler' | grep -v 'ibeacon' | grep -v 'homeassistant_connect_zbt2'")

    print("✅ All integration tests passed!")
  '';
}
