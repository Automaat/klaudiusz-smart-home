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
              message = "System started at {{ now().strftime('%H:%M') }}";
            };
          }
          # {
          #   action = "notify.send_message";
          #   target.entity_id = "notify.klaudiusz_smart_home_system";
          #   data = {
          #     message = "✅ Home Assistant started at {{ now().strftime('%H:%M') }}";
          #   };
          # }
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
            entity_id = "sensor.system_monitor_obciazenie_procesora";
            above = 80;
            "for" = {
              minutes = 2;
            };
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ (as_timestamp(now()) - as_timestamp(state_attr('automation.alert_high_cpu', 'last_triggered') | default(0))) > 300 }}";
          }
        ];
        action = [
          # {
          #   action = "notify.send_message";
          #   target.entity_id = "notify.klaudiusz_smart_home_system";
          #   data = {
          #     message = "🔴 High CPU usage: {{ states('sensor.system_monitor_obciazenie_procesora') }}%";
          #   };
          # }
        ];
      }

      {
        id = "alert_high_memory";
        alias = "Health - High memory usage";
        mode = "single";
        trigger = [
          {
            platform = "numeric_state";
            entity_id = "sensor.system_monitor_memory_use";
            above = 85;
            "for" = {
              minutes = 2;
            };
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ (as_timestamp(now()) - as_timestamp(state_attr('automation.alert_high_memory', 'last_triggered') | default(0))) > 300 }}";
          }
        ];
        action = [
          # {
          #   action = "notify.send_message";
          #   target.entity_id = "notify.klaudiusz_smart_home_system";
          #   data = {
          #     message = "🟠 High memory usage: {{ states('sensor.system_monitor_memory_use') }}%";
          #   };
          # }
        ];
      }

      {
        id = "alert_disk_full";
        alias = "Health - Disk space low";
        mode = "single";
        trigger = [
          {
            platform = "numeric_state";
            entity_id = "sensor.system_monitor_disk_use";
            above = 85;
            "for" = {
              minutes = 5;
            };
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ (as_timestamp(now()) - as_timestamp(state_attr('automation.alert_disk_full', 'last_triggered') | default(0))) > 1800 }}";
          }
        ];
        action = [
          # {
          #   action = "notify.send_message";
          #   target.entity_id = "notify.klaudiusz_smart_home_system";
          #   data = {
          #     message = "💾 Low disk space: {{ states('sensor.system_monitor_disk_use') }}% used";
          #   };
          # }
        ];
      }

      {
        id = "alert_high_temperature";
        alias = "Health - High CPU temperature";
        mode = "single";
        trigger = [
          {
            platform = "numeric_state";
            entity_id = "sensor.system_monitor_temperatura_procesora";
            above = 75;
            "for" = {
              minutes = 2;
            };
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ (as_timestamp(now()) - as_timestamp(state_attr('automation.alert_high_temperature', 'last_triggered') | default(0))) > 300 }}";
          }
        ];
        action = [
          # {
          #   action = "notify.send_message";
          #   target.entity_id = "notify.klaudiusz_smart_home_system";
          #   data = {
          #     message = "🔥 High CPU temperature: {{ states('sensor.system_monitor_temperatura_procesora') }}°C";
          #   };
          # }
        ];
      }

      # -----------------------------------------
      # TV Control
      # -----------------------------------------
      {
        id = "lg_c2_turn_on";
        alias = "TV - Turn on LG C2";
        trigger = [
          {
            platform = "webostv.turn_on";
            entity_id = "media_player.tv";
          }
        ];
        action = [
          {
            service = "wake_on_lan.send_magic_packet";
            data = {
              mac = "20:28:bc:69:b9:84";
              broadcast_address = "192.168.0.255";
            };
          }
        ];
      }

      # -----------------------------------------
      # Task Management (Todoist)
      # -----------------------------------------
      {
        id = "todoist_task_added_confirmation";
        alias = "Todoist - Task added confirmation";
        trigger = [
          {
            platform = "state";
            entity_id = "todo.inbox";
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ trigger.to_state.state | int > trigger.from_state.state | int }}";
          }
        ];
        action = [
          {
            service = "tts.speak";
            target.entity_id = "tts.piper";
            data = {
              message = "Zadanie dodane do listy";
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
