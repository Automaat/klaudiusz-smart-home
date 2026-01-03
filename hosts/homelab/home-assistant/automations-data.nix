# Nix-managed automations data
# Imported by both automations.nix (for HA config) and default.nix (for YAML generation)
[
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
  # Kitchen
  # -----------------------------------------
  {
    id = "kitchen_presence_lights_on";
    alias = "Kitchen - Turn on lights on presence";
    trigger = [
      {
        platform = "state";
        entity_id = "binary_sensor.presence_kitchen";
        to = "on";
      }
    ];
    action = [
      {
        service = "light.turn_on";
        target.entity_id = "light.kitchen";
      }
    ];
  }

  {
    id = "kitchen_presence_lights_off";
    alias = "Kitchen - Turn off lights on clear";
    trigger = [
      {
        platform = "state";
        entity_id = "binary_sensor.presence_kitchen";
        to = "off";
      }
    ];
    action = [
      {
        service = "light.turn_off";
        target.entity_id = "light.kitchen";
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
]
