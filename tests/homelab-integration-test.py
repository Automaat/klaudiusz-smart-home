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

# Loki (Log Aggregation)
try:
    homelab.wait_for_unit("loki.service")
    homelab.wait_for_open_port(3100)

    # Note: /ready endpoint waits for compactor (10m in VM) - skip, check metrics instead
    # Check Loki metrics endpoint (validates internal components running)
    homelab.succeed("curl -sf http://localhost:3100/metrics > /dev/null")

    # Check Loki can accept log pushes (query API for label names)
    # Empty response is OK - just validates API is responding
    homelab.succeed("curl -f http://localhost:3100/loki/api/v1/labels")

    print("✅ Loki service healthy")

except Exception as e:
    print(f"Loki failed: {e}")
    print(homelab.succeed("journalctl -u loki.service -n 100 --no-pager"))
    print(homelab.succeed("systemctl status loki.service --no-pager"))
    raise

# Promtail (Log Shipper)
try:
    homelab.wait_for_unit("promtail.service")
    homelab.wait_for_open_port(9080)

    # Check Promtail ready endpoint
    homelab.succeed("curl -f http://localhost:9080/ready")

    # Check Promtail metrics (validates scrape configs loaded)
    homelab.succeed("curl -sf http://localhost:9080/metrics > /dev/null")

    print("✅ Promtail service healthy")

except Exception as e:
    print(f"Promtail failed: {e}")
    print(homelab.succeed("journalctl -u promtail.service -n 100 --no-pager"))
    print(homelab.succeed("systemctl status promtail.service --no-pager"))
    raise

# Grafana
try:
    homelab.wait_for_unit("grafana.service")
    homelab.wait_for_open_port(3000)
    homelab.succeed("curl -f http://localhost:3000/api/health")

    # Check Prometheus datasource is configured
    homelab.succeed("curl -f http://admin:test-password@localhost:3000/api/datasources/uid/prometheus")

    # Check Loki datasource is configured
    homelab.succeed("curl -f http://admin:test-password@localhost:3000/api/datasources/uid/loki")

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

# Paperless-ngx
try:
    homelab.wait_for_unit("paperless-scheduler.service")
    homelab.wait_for_unit("paperless-consumer.service")
    homelab.wait_for_unit("paperless-web.service")

    print("Paperless services started, checking port 28981...")
    print(homelab.succeed("ss -tlnp | grep 28981 || echo 'Port 28981 not open yet'"))

    # Wait for port with extended timeout (migrations can be slow)
    homelab.wait_for_open_port(28981)
    print("Port 28981 is open, checking HTTP endpoint...")

    # Check web UI responds
    homelab.succeed("curl -f http://localhost:28981/")

    print("✅ Paperless-ngx services healthy")

except Exception as e:
    print(f"❌ Paperless-ngx failed: {e}")
    print("\n=== Paperless Web Service Status ===")
    print(homelab.succeed("systemctl status paperless-web.service --no-pager"))
    print("\n=== Paperless Web Service Logs (last 100 lines) ===")
    print(homelab.succeed("journalctl -u paperless-web.service -n 100 --no-pager"))
    print("\n=== Port Status ===")
    print(homelab.succeed("ss -tlnp | grep 28981 || echo 'Port 28981 not open'"))
    print("\n=== PostgreSQL Status ===")
    print(homelab.succeed("systemctl status postgresql.service --no-pager"))
    print("\n=== Paperless Database Connection Test ===")
    print(homelab.succeed("sudo -u paperless psql -d paperless -c 'SELECT 1' || echo 'Database connection failed'"))
    raise

# Comin (GitOps)
homelab.wait_for_unit("comin.service")

# Note: Cloudflared disabled in VM tests (requires real Cloudflare credentials)

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

# Filter out known expected errors in test environment
# These errors occur because test VM doesn't have real hardware/services
expected_errors = [
    "Error adding entity sensor.czajnik_temperatura",  # Kettle at 192.168.0.47 doesn't exist in VM
    "Command failed (with return code 2): jq",  # comin store.json doesn't exist in test
    "Theme Catppuccin Latte not found",  # Theme not installed in test environment
    "invalid_entity_id",  # Test environment doesn't have all entities
    "InfluxDB bucket is not accessible",  # InfluxDB token not configured in test
    "Error requesting homeassistant_alerts data",  # No internet in test VM
]

if log_errors:
    # Filter errors line by line
    filtered_errors = []
    for line in log_errors.split("\n"):
        if not any(expected in line for expected in expected_errors):
            filtered_errors.append(line)

    if filtered_errors:
        print("========================================")
        print("❌ Found unexpected ERROR/CRITICAL in logs:")
        print("========================================")
        print("\n".join(filtered_errors))
        print("========================================")
        raise Exception("Home Assistant logs contain unexpected ERROR/CRITICAL messages")

print("✅ No ERROR/CRITICAL messages found in logs")

# =============================================
# Python Dependencies Validation
# =============================================
# Custom packages are validated implicitly:
# - If HA starts without ModuleNotFoundError, packages imported successfully
# - HA logs are checked above for import errors
# - No need for explicit import test since HA already loaded them

print("✅ All integration tests passed!")
