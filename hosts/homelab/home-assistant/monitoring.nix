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
    # Tracks CPU, RAM, disk usage, etc.
    sensor = [
      # -----------------------------------------
      # System Resources
      # -----------------------------------------
      {
        platform = "systemmonitor";
        resources = [
          "disk_use_percent_/"
          "memory_use_percent"
          "processor_use"
          "processor_temperature"
          "load_1m"
          "load_5m"
          "load_15m"
        ];
      }

      # -----------------------------------------
      # Service Health - Template Sensors
      # -----------------------------------------
      {
        platform = "template";
        sensors = {
          home_assistant_status = {
            friendly_name = "Home Assistant Status";
            value_template = "{{ 'active' }}";
            icon_template = "mdi:home-assistant";
          };

          whisper_status = {
            friendly_name = "Whisper STT Status";
            value_template = ''
              {% set status = states('binary_sensor.wyoming_whisper_health') %}
              {{ 'active' if status == 'on' else 'inactive' }}
            '';
            icon_template = ''
              {% set status = states('binary_sensor.wyoming_whisper_health') %}
              {{ 'mdi:microphone' if status == 'on' else 'mdi:microphone-off' }}
            '';
          };

          piper_status = {
            friendly_name = "Piper TTS Status";
            value_template = ''
              {% set status = states('binary_sensor.wyoming_piper_health') %}
              {{ 'active' if status == 'on' else 'inactive' }}
            '';
            icon_template = ''
              {% set status = states('binary_sensor.wyoming_piper_health') %}
              {{ 'mdi:speaker' if status == 'on' else 'mdi:speaker-off' }}
            '';
          };

          tailscale_status = {
            friendly_name = "Tailscale Status";
            value_template = ''
              {% set status = states('binary_sensor.tailscale_health') %}
              {{ 'connected' if status == 'on' else 'disconnected' }}
            '';
            icon_template = ''
              {% set status = states('binary_sensor.tailscale_health') %}
              {{ 'mdi:shield-check' if status == 'on' else 'mdi:shield-off' }}
            '';
          };
        };
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
            entity_id = "sensor.disk_use_percent";
            above = 90;
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "⚠️ Krytyczny poziom dysku";
              message = "Użycie dysku: {{ states('sensor.disk_use_percent') }}%";
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
            entity_id = "sensor.disk_use_percent";
            above = 80;
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "⚠️ Ostrzeżenie - Dysk";
              message = "Użycie dysku: {{ states('sensor.disk_use_percent') }}%";
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
            entity_id = "sensor.memory_use_percent";
            above = 90;
            for.minutes = 5;
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "⚠️ Wysokie użycie RAM";
              message = "Pamięć RAM: {{ states('sensor.memory_use_percent') }}%";
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
            to = "false";
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
            to = "false";
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
            to = "false";
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
    ];
  };
}
