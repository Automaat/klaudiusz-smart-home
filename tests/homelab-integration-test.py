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

    # Check Prometheus datasource is configured
    homelab.succeed("curl -f http://admin:test-password@localhost:3000/api/datasources/uid/prometheus")

    # Check dashboards are provisioned (expect at least 4 dashboards)
    dashboard_count = homelab.succeed(
        "curl -sf http://admin:test-password@localhost:3000/api/search | jq 'length'"
    ).strip()
    print(f"Grafana dashboards provisioned: {dashboard_count}")
    homelab.succeed(f"[ {dashboard_count} -ge 4 ]")

    # Check specific custom dashboard exists (service-health)
    homelab.succeed(
        "curl -f http://admin:test-password@localhost:3000/api/dashboards/uid/service-health"
    )

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
# Comprehensive Error/Critical Log Checks
# =============================================

# Use 5-minute window (consistent with ModuleNotFoundError, integration checks above)
# Note: HA logs ERROR/CRITICAL at journald priority 6 (info), not 3 (err)
# Must grep message content, not filter by --priority
print("Checking for ERROR/CRITICAL messages in last 5 minutes...")
log_errors = homelab.succeed("""
  journalctl -u home-assistant --since '5 minutes ago' --no-pager | grep -E ' (ERROR|CRITICAL) ' || true
""").strip()

if log_errors:
    print("========================================")
    print("❌ Found ERROR/CRITICAL in logs:")
    print("========================================")
    print(log_errors)
    print("========================================")
    raise Exception("Home Assistant logs contain ERROR/CRITICAL messages")

print("✅ No ERROR/CRITICAL messages found in logs")

# =============================================
# Python Dependencies Validation
# =============================================
# Custom packages are validated implicitly:
# - If HA starts without ModuleNotFoundError, packages imported successfully
# - HA logs are checked above for import errors
# - No need for explicit import test since HA already loaded them

print("✅ All integration tests passed!")
