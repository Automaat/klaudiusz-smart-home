{
  config,
  pkgs,
  lib,
  ...
}: {
  services.home-assistant.config = {
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

          {
            name = "Whisper STT Status";
            unique_id = "whisper_status";
            state = ''
              {% set status = states('sensor.wyoming_whisper_health') %}
              {{ 'active' if status == 'on' else 'inactive' }}
            '';
            icon = ''
              {% set status = states('sensor.wyoming_whisper_health') %}
              {{ 'mdi:microphone' if status == 'on' else 'mdi:microphone-off' }}
            '';
          }

          {
            name = "Piper TTS Status";
            unique_id = "piper_status";
            state = ''
              {% set status = states('sensor.wyoming_piper_health') %}
              {{ 'active' if status == 'on' else 'inactive' }}
            '';
            icon = ''
              {% set status = states('sensor.wyoming_piper_health') %}
              {{ 'mdi:speaker' if status == 'on' else 'mdi:speaker-off' }}
            '';
          }

          {
            name = "Tailscale Status";
            unique_id = "tailscale_status";
            state = ''
              {% set status = states('sensor.tailscale_health') %}
              {{ 'connected' if status == 'on' else 'disconnected' }}
            '';
            icon = ''
              {% set status = states('sensor.tailscale_health') %}
              {{ 'mdi:shield-check' if status == 'on' else 'mdi:shield-off' }}
            '';
          }

          {
            name = "PostgreSQL Status";
            unique_id = "postgresql_status";
            state = ''
              {% set status = states('sensor.postgresql_health') %}
              {{ 'active' if status == 'on' else 'inactive' }}
            '';
            icon = ''
              {% set status = states('sensor.postgresql_health') %}
              {{ 'mdi:database' if status == 'on' else 'mdi:database-off' }}
            '';
          }
        ];
      }
    ];

    # ===========================================
    # Command Line Sensors for Service Status
    # ===========================================
    command_line = [
      {
        sensor = {
          name = "wyoming_whisper_health";
          command = "systemctl is-active wyoming-faster-whisper-default";
          value_template = "{{ value == 'active' }}";
          scan_interval = 60;
        };
      }
      {
        sensor = {
          name = "wyoming_piper_health";
          command = "systemctl is-active wyoming-piper-default";
          value_template = "{{ value == 'active' }}";
          scan_interval = 60;
        };
      }
      {
        sensor = {
          name = "tailscale_health";
          command = "systemctl is-active tailscaled";
          value_template = "{{ value == 'active' }}";
          scan_interval = 60;
        };
      }
      {
        sensor = {
          name = "fail2ban_health";
          command = "systemctl is-active fail2ban";
          value_template = "{{ value == 'active' }}";
          scan_interval = 60;
        };
      }
      {
        sensor = {
          name = "postgresql_health";
          command = "systemctl is-active postgresql";
          value_template = "{{ value == 'active' }}";
          scan_interval = 60;
        };
      }
      # -----------------------------------------
      # Comin Deployment Detection
      # -----------------------------------------
      # Sensors output deployment UUID which changes on each deployment
      # Automations trigger on state change (UUID change)
      {
        sensor = {
          name = "comin_last_deployment_uuid";
          unique_id = "comin_last_deployment_uuid";
          command = "jq -r '.deployments[0] | select(.status == \"done\" and .error_msg == \"\") | .uuid' /var/lib/comin/store.json 2>/dev/null || echo \"none\"";
          scan_interval = 30;
        };
      }
      {
        sensor = {
          name = "comin_last_failed_uuid";
          unique_id = "comin_last_failed_uuid";
          command = "jq -r '.deployments[0] | select(.status == \"done\" and .error_msg != \"\") | .uuid' /var/lib/comin/store.json 2>/dev/null || echo \"none\"";
          scan_interval = 30;
        };
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
        ];
      }

      # -----------------------------------------
      # Service Failure Alerts
      # -----------------------------------------
      {
        id = "alert_whisper_down";
        alias = "Alert - Whisper service down";
        trigger = [
          {
            platform = "state";
            entity_id = "sensor.wyoming_whisper_health";
            to = "False";
            for.minutes = 2;
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "⚠️ Usługa Whisper nie działa";
              message = "Sprawdź systemctl status wyoming-faster-whisper-default";
            };
          }
        ];
      }

      {
        id = "alert_piper_down";
        alias = "Alert - Piper service down";
        trigger = [
          {
            platform = "state";
            entity_id = "sensor.wyoming_piper_health";
            to = "False";
            for.minutes = 2;
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "⚠️ Usługa Piper nie działa";
              message = "Sprawdź systemctl status wyoming-piper-default";
            };
          }
        ];
      }

      {
        id = "alert_tailscale_down";
        alias = "Alert - Tailscale service down";
        trigger = [
          {
            platform = "state";
            entity_id = "sensor.tailscale_health";
            to = "False";
            for.minutes = 2;
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "⚠️ Tailscale nie działa";
              message = "Sprawdź systemctl status tailscaled";
            };
          }
        ];
      }

      {
        id = "alert_postgresql_down";
        alias = "Alert - PostgreSQL service down";
        trigger = [
          {
            platform = "state";
            entity_id = "sensor.postgresql_health";
            to = "False";
            for.minutes = 2;
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "⚠️ PostgreSQL nie działa";
              message = "Sprawdź systemctl status postgresql";
            };
          }
        ];
      }

      # -----------------------------------------
      # Comin Deployment Notifications
      # -----------------------------------------
      {
        id = "notify_comin_deployment_success";
        alias = "Alert - Comin deployment successful";
        trigger = [
          {
            platform = "state";
            entity_id = "sensor.comin_last_deployment_uuid";
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ trigger.to_state.state not in ['none', 'unknown', 'unavailable'] }}";
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
            platform = "state";
            entity_id = "sensor.comin_last_failed_uuid";
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ trigger.to_state.state not in ['none', 'unknown', 'unavailable'] }}";
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
