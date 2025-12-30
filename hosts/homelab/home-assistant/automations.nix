{
  config,
  pkgs,
  lib,
  ...
}: {
  services.home-assistant.config = {
    # ===========================================
    # Core Automations (managed in Nix)
    # ===========================================
    # Simple/experimental automations can be created in GUI

    automation = [
      # -----------------------------------------
      # Startup
      # -----------------------------------------
      {
        id = "startup_notification";
        alias = "System - Startup notification";
        trigger = [
          {
            platform = "homeassistant";
            event = "start";
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "Home Assistant";
              message = "System uruchomiony o {{ now().strftime('%H:%M') }}";
            };
          }
          {
            service = "notify.telegram";
            data = {
              message = "🟢 Home Assistant uruchomiony o {{ now().strftime('%H:%M') }}";
            };
          }
        ];
      }

      # -----------------------------------------
      # System Health Monitoring
      # -----------------------------------------
      {
        id = "alert_high_cpu";
        alias = "Health - High CPU usage";
        mode = "single";
        trigger = [
          {
            platform = "numeric_state";
            entity_id = "sensor.processor_use";
            above = 80;
            "for" = {
              minutes = 2;
            };
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ (as_timestamp(now()) - as_timestamp(state_attr('automation.health_high_cpu_usage', 'last_triggered') | default(0))) > 300 }}";
          }
        ];
        action = [
          {
            service = "notify.telegram";
            data = {
              message = "⚠️ Wysokie użycie CPU: {{ states('sensor.processor_use') }}%";
            };
          }
        ];
      }

      {
        id = "alert_high_memory";
        alias = "Health - High memory usage";
        mode = "single";
        trigger = [
          {
            platform = "numeric_state";
            entity_id = "sensor.memory_use_percent";
            above = 85;
            "for" = {
              minutes = 2;
            };
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ (as_timestamp(now()) - as_timestamp(state_attr('automation.health_high_memory_usage', 'last_triggered') | default(0))) > 300 }}";
          }
        ];
        action = [
          {
            service = "notify.telegram";
            data = {
              message = "⚠️ Wysokie użycie pamięci: {{ states('sensor.memory_use_percent') }}%";
            };
          }
        ];
      }

      {
        id = "alert_disk_full";
        alias = "Health - Disk space low";
        mode = "single";
        trigger = [
          {
            platform = "numeric_state";
            entity_id = "sensor.disk_use_percent";
            above = 85;
            "for" = {
              minutes = 5;
            };
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ (as_timestamp(now()) - as_timestamp(state_attr('automation.health_disk_space_low', 'last_triggered') | default(0))) > 1800 }}";
          }
        ];
        action = [
          {
            service = "notify.telegram";
            data = {
              message = "⚠️ Mało miejsca na dysku: {{ states('sensor.disk_use_percent') }}% ({{ states('sensor.disk_free') }} GB wolne)";
            };
          }
        ];
      }

      {
        id = "alert_high_temperature";
        alias = "Health - High CPU temperature";
        mode = "single";
        trigger = [
          {
            platform = "numeric_state";
            entity_id = "sensor.processor_temperature";
            above = 75;
            "for" = {
              minutes = 2;
            };
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ (as_timestamp(now()) - as_timestamp(state_attr('automation.health_high_cpu_temperature', 'last_triggered') | default(0))) > 300 }}";
          }
        ];
        action = [
          {
            service = "notify.telegram";
            data = {
              message = "🔥 Wysoka temperatura CPU: {{ states('sensor.processor_temperature') }}°C";
            };
          }
        ];
      }

      # -----------------------------------------
      # Mode Management (Placeholder - no devices yet)
      # -----------------------------------------
      # {
      #   id = "disable_sleep_mode_morning";
      #   alias = "Tryb nocny - Wyłącz rano";
      #   trigger = [{
      #     platform = "time";
      #     at = "07:00:00";
      #   }];
      #   condition = [{
      #     condition = "state";
      #     entity_id = "input_boolean.sleep_mode";
      #     state = "on";
      #   }];
      #   action = [{
      #     service = "input_boolean.turn_off";
      #     target.entity_id = "input_boolean.sleep_mode";
      #   }];
      # }
    ];

    # ===========================================
    # Input Helpers
    # ===========================================
    input_boolean = {
      away_mode = {
        name = "Tryb poza domem";
        icon = "mdi:home-export-outline";
      };
      guest_mode = {
        name = "Tryb gościa";
        icon = "mdi:account-group";
      };
      sleep_mode = {
        name = "Tryb nocny";
        icon = "mdi:sleep";
      };
    };

    input_number = {
      default_brightness = {
        name = "Domyślna jasność";
        min = 0;
        max = 100;
        step = 5;
        unit_of_measurement = "%";
        icon = "mdi:brightness-6";
      };
    };

    # ===========================================
    # Scripts (callable from automations/voice)
    # ===========================================
    script = {
      all_off = {
        alias = "Wyłącz wszystko";
        sequence = [
          {
            service = "light.turn_off";
            target.entity_id = "all";
          }
          {
            service = "media_player.turn_off";
            target.entity_id = "all";
          }
          {
            service = "fan.turn_off";
            target.entity_id = "all";
          }
        ];
        icon = "mdi:power";
      };
    };
  };
}
