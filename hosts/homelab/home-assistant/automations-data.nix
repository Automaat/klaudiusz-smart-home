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
  # Monitoring Alerts (from monitoring.nix)
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

  {
    id = "alert_memory_high";
    alias = "Alert - High memory usage";
    trigger = [
      {
        platform = "numeric_state";
        entity_id = "sensor.system_monitor_memory_use";
        above = 90;
        "for".minutes = 5;
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

  {
    id = "alert_whisper_down";
    alias = "Alert - Whisper service down";
    trigger = [
      {
        platform = "state";
        entity_id = "sensor.wyoming_whisper_health";
        to = "False";
        "for".minutes = 2;
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
        "for".minutes = 2;
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
        "for".minutes = 2;
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
        "for".minutes = 2;
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
