{
  config,
  pkgs,
  lib,
  ...
}: {
  services.home-assistant.config = {
    # ===========================================
    # Prometheus Metrics Export
    # ===========================================
    prometheus = {
      namespace = "ha";
      filter = {
        include_domains = ["sensor" "binary_sensor" "light" "switch" "climate" "automation"];
      };
    };

    # ===========================================
    # System Monitor Integration
    # ===========================================
    # System Monitor configured via UI (see docs/manual-config.md)
    # Creates entities: sensor.processor_use, sensor.memory_use_percent, etc.

    # ===========================================
    # Template Sensors (Modern Syntax)
    # ===========================================
    template = [
      {
        sensor = [
          {
            name = "Home Assistant Status";
            unique_id = "home_assistant_status";
            state = "{{ 'active' }}";
            icon = "mdi:home-assistant";
          }
        ];
      }
    ];

    # ===========================================
    # Command Line Sensors - Comin Deployment Tracking
    # ===========================================
    # Service health monitored via Prometheus node_exporter systemd collector
    # Comin deployment info read from /var/lib/comin/store.json
    command_line = [
      # -----------------------------------------
      # Comin Deployment Detection
      # -----------------------------------------
      {
        platform = "sensor";
        name = "comin_last_deployment_uuid";
        unique_id = "comin_last_deployment_uuid";
        command = "jq -r '.deployments[0]|select(.error_msg==\"\")|.uuid//\"none\"' /var/lib/comin/store.json";
        scan_interval = 30;
      }
      {
        platform = "sensor";
        name = "comin_last_deployment_time";
        unique_id = "comin_last_deployment_time";
        command = "jq -r '.deployments[0]|select(.error_msg==\"\")|.ended_at//\"none\"' /var/lib/comin/store.json";
        device_class = "timestamp";
        scan_interval = 30;
      }
      {
        platform = "sensor";
        name = "comin_last_failed_uuid";
        unique_id = "comin_last_failed_uuid";
        command = "jq -r '.deployments[0]|if .error_msg==\"\" then \"none\" else .uuid end' /var/lib/comin/store.json";
        scan_interval = 30;
      }
      {
        platform = "sensor";
        name = "comin_last_failed_time";
        unique_id = "comin_last_failed_time";
        command = "jq -r '.deployments[0]|select(.error_msg!=\"\")|.ended_at//\"none\"' /var/lib/comin/store.json";
        device_class = "timestamp";
        scan_interval = 30;
      }
    ];

    # ===========================================
    # Alert Automations
    # ===========================================
    automation = [
      # -----------------------------------------
      # Disk Space Critical Alert
      # -----------------------------------------
      {
        id = "alert_disk_space_critical";
        alias = "Alert - Disk space critical";
        trigger = [
          {
            platform = "numeric_state";
            entity_id = "sensor.system_monitor_disk_use";
            above = 90;
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "⚠️ Krytyczny poziom dysku";
              message = "Użycie dysku: {{ states('sensor.system_monitor_disk_use') }}%";
            };
          }
          {
            action = "notify.send_message";
            target.entity_id = "notify.klaudiusz_smart_home_system";
            data = {
              message = "🚨 Critical disk space alert\nUsage: {{ states('sensor.system_monitor_disk_use') }}%";
            };
          }
        ];
      }

      # -----------------------------------------
      # Disk Space Warning Alert
      # -----------------------------------------
      {
        id = "alert_disk_space_warning";
        alias = "Alert - Disk space warning";
        trigger = [
          {
            platform = "numeric_state";
            entity_id = "sensor.system_monitor_disk_use";
            above = 80;
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "⚠️ Ostrzeżenie - Dysk";
              message = "Użycie dysku: {{ states('sensor.system_monitor_disk_use') }}%";
            };
          }
          {
            action = "notify.send_message";
            target.entity_id = "notify.klaudiusz_smart_home_system";
            data = {
              message = "⚠️ Disk space warning\nUsage: {{ states('sensor.system_monitor_disk_use') }}%";
            };
          }
        ];
      }

      # -----------------------------------------
      # High Memory Usage Alert
      # -----------------------------------------
      {
        id = "alert_memory_high";
        alias = "Alert - High memory usage";
        trigger = [
          {
            platform = "numeric_state";
            entity_id = "sensor.system_monitor_memory_use";
            above = 90;
            for.minutes = 5;
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "⚠️ Wysokie użycie RAM";
              message = "Pamięć RAM: {{ states('sensor.system_monitor_memory_use') }}%";
            };
          }
          {
            action = "notify.send_message";
            target.entity_id = "notify.klaudiusz_smart_home_system";
            data = {
              message = "🟠 High memory usage\nRAM: {{ states('sensor.system_monitor_memory_use') }}%";
            };
          }
        ];
      }

      # -----------------------------------------
      # Service health alerts moved to Grafana (uses Prometheus node_exporter)
      # -----------------------------------------

      # -----------------------------------------
      # Comin Deployment Notifications
      # -----------------------------------------
      # Deployments trigger HA restart, so detect "startup after recent deployment"
      # instead of sensor state changes (sensor already has new value at startup)
      {
        id = "notify_comin_deployment_success";
        alias = "Alert - Comin deployment successful";
        trigger = [
          {
            platform = "homeassistant";
            event = "start";
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = ''
              {% set deploy_time = states('sensor.comin_last_deployment_time') %}
              {% if deploy_time not in ['none', 'unknown', 'unavailable'] %}
                {{ (now() - as_datetime(deploy_time)).total_seconds() < 120 }}
              {% else %}
                false
              {% endif %}
            '';
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "✅ Aktualizacja zakończona";
              message = "🚀 Comin pomyślnie wdrożył zmiany o {{ now().strftime('%H:%M') }} 🎉";
            };
          }
          {
            action = "notify.send_message";
            target.entity_id = "notify.klaudiusz_smart_home_system";
            data = {
              message = "✅ Deployment successful\n🚀 Comin deployed changes at {{ now().strftime('%H:%M') }}";
            };
          }
        ];
      }

      {
        id = "notify_comin_deployment_failed";
        alias = "Alert - Comin deployment failed";
        trigger = [
          {
            platform = "homeassistant";
            event = "start";
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = ''
              {% set fail_time = states('sensor.comin_last_failed_time') %}
              {% if fail_time not in ['none', 'unknown', 'unavailable'] %}
                {{ (now() - as_datetime(fail_time)).total_seconds() < 120 }}
              {% else %}
                false
              {% endif %}
            '';
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "❌ Aktualizacja nieudana";
              message = "🔥 Comin nie mógł wdrożyć zmian. Sprawdź journalctl -u comin 🔍";
            };
          }
          {
            action = "notify.send_message";
            target.entity_id = "notify.klaudiusz_smart_home_system";
            data = {
              message = "❌ Deployment failed\n🔥 Comin could not deploy changes. Check journalctl -u comin";
            };
          }
        ];
      }
    ];
  };
}
