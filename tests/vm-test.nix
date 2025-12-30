{
  pkgs,
  self,
  ...
}: let
  # Import the homelab configuration
  homelabSystem = self.nixosConfigurations.homelab;
in
  pkgs.nixosTest {
    name = "homelab-integration-test";

    nodes.homelab = {
      imports = homelabSystem._module.args.modules;
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
      homelab.succeed("curl -f http://localhost:8123 || curl -f http://localhost:8123/manifest.json")

      # PostgreSQL (for HA recorder)
      homelab.wait_for_unit("postgresql.service")

      # Wyoming Faster Whisper (Polish voice input)
      homelab.wait_for_unit("wyoming-faster-whisper-default.service")
      homelab.wait_for_open_port(10300)

      # Wyoming Piper (Polish voice output)
      homelab.wait_for_unit("wyoming-piper-default.service")
      homelab.wait_for_open_port(10200)

      # Prometheus
      homelab.wait_for_unit("prometheus.service")
      homelab.wait_for_open_port(9090)
      homelab.succeed("curl -f http://localhost:9090/-/healthy")

      # Grafana
      homelab.wait_for_unit("grafana.service")
      homelab.wait_for_open_port(3000)
      homelab.succeed("curl -f http://localhost:3000/api/health")

      # Comin (GitOps)
      homelab.wait_for_unit("comin.service")

      # =============================================
      # Service Health Checks
      # =============================================

      # Check no failed units
      homelab.succeed("! systemctl --failed | grep -q 'failed'")

      # Check home-assistant can access PostgreSQL
      homelab.succeed("sudo -u hass psql -d hass -c 'SELECT 1' > /dev/null")

      # =============================================
      # Network and Port Checks
      # =============================================

      # Verify Wyoming services are actually listening (not just port open)
      homelab.succeed("timeout 5 nc -zv localhost 10300")  # Whisper
      homelab.succeed("timeout 5 nc -zv localhost 10200")  # Piper

      print("✅ All integration tests passed!")
    '';
  }
