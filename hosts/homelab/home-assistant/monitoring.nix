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
        sensor = {
          name = "comin_last_deployment_uuid";
          unique_id = "comin_last_deployment_uuid";
          command = "jq -r '.deployments[0]|select(.error_msg==\"\")|.uuid//\"none\"' /var/lib/comin/store.json";
          scan_interval = 30;
        };
      }
      {
        sensor = {
          name = "comin_last_deployment_time";
          unique_id = "comin_last_deployment_time";
          command = "jq -r '.deployments[0]|select(.error_msg==\"\")|.ended_at//\"none\"' /var/lib/comin/store.json";
          scan_interval = 30;
        };
      }
      {
        sensor = {
          name = "comin_last_failed_uuid";
          unique_id = "comin_last_failed_uuid";
          command = "jq -r '.deployments[0]|if .error_msg==\"\" then \"none\" else .uuid end' /var/lib/comin/store.json";
          scan_interval = 30;
        };
      }
      {
        sensor = {
          name = "comin_last_failed_time";
          unique_id = "comin_last_failed_time";
          command = "jq -r '.deployments[0]|if .error_msg==\"\" then \"none\" else (.ended_at//\"none\") end' /var/lib/comin/store.json";
          scan_interval = 30;
        };
      }
    ];

    # ===========================================
    # Alert Automations
    # ===========================================
    automation = [
      # -----------------------------------------
      # System health alerts moved to Grafana (uses Prometheus node_exporter)
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

      # -----------------------------------------
      # Grafana Systemd Service Alerts
      # -----------------------------------------
      # Receives webhook from Grafana alerts and forwards to Telegram
      {
        id = "grafana_systemd_alert_webhook";
        alias = "Alert - Grafana systemd service alert";
        trigger = [
          {
            platform = "webhook";
            allowed_methods = ["POST"];
            local_only = true;
            webhook_id = "grafana_systemd_alerts";
          }
        ];
        action = [
          {
            action = "notify.send_message";
            target.entity_id = "notify.klaudiusz_smart_home_system";
            data = {
              message = ''
                🚨 {{ trigger.json.status | upper }}
                {% for alert in trigger.json.alerts %}
                {{ alert.labels.severity | upper }}: {{ alert.annotations.summary }}
                {{ alert.annotations.description }}
                {% endfor %}
              '';
            };
          }
        ];
      }
    ];
  };
}
