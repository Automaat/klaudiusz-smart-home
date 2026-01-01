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
# Python Dependencies Validation
# =============================================

# Test that all custom Python packages can be imported
# This catches missing transitive dependencies early
print("Testing Python package imports...")
status, output = homelab.execute("""
  sudo -u hass /run/current-system/sw/bin/python3 -c '
import sys
import traceback

# Test custom packages declared in extraPackages
packages = [
    "ibeacon_ble",
    "ha_silabs_firmware_client",
]

errors = []
for pkg in packages:
    try:
        __import__(pkg)
        print(f"✓ {pkg} imported successfully")
    except Exception as e:
        print(f"✗ {pkg} FAILED:")
        print(f"  Error: {e}")
        traceback.print_exc()
        errors.append(pkg)

if errors:
    print(f"\\nFailed to import {len(errors)} package(s): {errors}")
    sys.exit(1)
else:
    print(f"\\n✓ All {len(packages)} packages imported successfully")
  '
""")
print(output)
if status != 0:
    raise Exception(f"Package import test failed with status {status}")

print("✅ All integration tests passed!")
