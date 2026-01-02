homelab.start()
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
    homelab.wait_for_open_port(3000)
    homelab.succeed("curl -f http://localhost:3000/api/health")
except Exception as e:
    print(f"Grafana failed: {e}")
    print(homelab.succeed("journalctl -u grafana.service -n 50 --no-pager"))
    print(homelab.succeed("systemctl status grafana.service --no-pager"))
    raise

# Comin (GitOps)
homelab.wait_for_unit("comin.service")

# =============================================
# Service Health Checks
# =============================================

# Check no failed units (print them first for debugging)
print(homelab.succeed("systemctl list-units --state=failed --no-legend"))
homelab.succeed("[ $(systemctl list-units --state=failed --no-legend | wc -l) -eq 0 ]")

# Check home-assistant can access PostgreSQL
homelab.succeed("sudo -u hass psql -d hass -c 'SELECT 1' > /dev/null")

# =============================================
# Home Assistant Log Validation
# =============================================

# Check for missing Python module errors (from service start to catch early errors)
homelab.fail("journalctl -u home-assistant --since '5 minutes ago' | grep -i 'ModuleNotFoundError'")

# Check for integration loading failures
homelab.fail("journalctl -u home-assistant --since '5 minutes ago' | grep -i 'Error occurred loading flow for integration'")

# Check for UnknownHandler exceptions (failed integration loads)
homelab.fail("journalctl -u home-assistant --since '5 minutes ago' | grep -i 'homeassistant.data_entry_flow.UnknownHandler'")

# =============================================
# Explicit Python Dependencies Validation
# =============================================

# Explicitly test that custom packages can be imported in HA's environment
# This catches missing transitive dependencies before they cause runtime errors
print("Testing explicit Python imports in HA environment...")
homelab.succeed("""
  set -e

  # Get the Python executable that HA is using
  HA_PYTHON=$(systemctl show -p ExecStart home-assistant.service | grep -oP '/nix/store/[^/]+/bin/python[0-9.]*' | head -1)
  echo "=========================================="
  echo "Python executable: $HA_PYTHON"
  echo "Python version: $($HA_PYTHON --version)"
  echo "=========================================="
  echo ""

  # Test each custom package with detailed error output
  # Save errors to file for better debugging
  for pkg in ibeacon_ble ha_silabs_firmware_client; do
    echo "Testing import: $pkg"
    $HA_PYTHON -c "
import sys
import traceback
try:
    __import__('$pkg')
    print('✓ Successfully imported $pkg')
except Exception as e:
    print('=' * 60)
    print('IMPORT FAILED: $pkg')
    print('=' * 60)
    print('Error:', str(e))
    print()
    print('Full traceback:')
    traceback.print_exc()
    print()
    print('Python path:')
    for p in sys.path:
        print('  ', p)
    print('=' * 60)
    sys.exit(1)
"
    if [ $? -ne 0 ]; then
      echo "FATAL: Import test failed for $pkg"
      exit 1
    fi
  done

  echo ""
  echo "=========================================="
  echo "✓ All custom packages imported successfully"
  echo "=========================================="
""")

print("✅ All integration tests passed!")
