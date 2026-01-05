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
        condition = [
          {
            condition = "or";
            conditions = [
              {
                condition = "sun";
                after = "sunset";
              }
              {
                condition = "numeric_state";
                entity_id = "sensor.kitchen_light_power";
                below = 20;
              }
            ];
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
      # Bathroom
      # -----------------------------------------
      {
        id = "bathroom_morning_boost_start";
        alias = "Bathroom - Morning boost start";
        trigger = [
          {
            platform = "time";
            at = "06:00:00";
          }
        ];
        action = [
          {
            service = "climate.set_preset_mode";
            target.entity_id = "climate.thermostat_bathroom";
            data.preset_mode = "boost";
          }
          {
            service = "climate.set_temperature";
            target.entity_id = "climate.thermostat_bathroom";
            data.temperature = 24;
          }
        ];
      }

      {
        id = "bathroom_morning_boost_end";
        alias = "Bathroom - Morning boost end";
        trigger = [
          {
            platform = "time";
            at = "09:00:00";
          }
        ];
        action = [
          {
            service = "climate.set_preset_mode";
            target.entity_id = "climate.thermostat_bathroom";
            data.preset_mode = "eco";
          }
          {
            service = "climate.set_temperature";
            target.entity_id = "climate.thermostat_bathroom";
            data.temperature = 19;
          }
        ];
      }

      # -----------------------------------------
      # Bedroom
      # -----------------------------------------
      {
        id = "bedroom_morning_boost_start";
        alias = "Bedroom - Morning boost start";
        trigger = [
          {
            platform = "time";
            at = "06:00:00";
          }
        ];
        action = [
          {
            service = "climate.set_preset_mode";
            target.entity_id = "climate.thermostat_bedroom";
            data.preset_mode = "boost";
          }
          {
            service = "climate.set_temperature";
            target.entity_id = "climate.thermostat_bedroom";
            data.temperature = 22;
          }
        ];
      }

      {
        id = "bedroom_morning_boost_end";
        alias = "Bedroom - Morning boost end";
        trigger = [
          {
            platform = "time";
            at = "09:00:00";
          }
        ];
        action = [
          {
            service = "climate.set_preset_mode";
            target.entity_id = "climate.thermostat_bedroom";
            data.preset_mode = "eco";
          }
          {
            service = "climate.set_temperature";
            target.entity_id = "climate.thermostat_bedroom";
            data.temperature = 18;
          }
        ];
      }

      # -----------------------------------------
      # Living Room
      # -----------------------------------------
      {
        id = "living_room_temperature_morning";
        alias = "Living Room - Morning temperature";
        trigger = [
          {
            platform = "time";
            at = "06:00:00";
          }
        ];
        action = [
          {
            service = "climate.set_temperature";
            target.entity_id = "climate.livingroom_thermostat";
            data.temperature = 21;
          }
        ];
      }

      {
        id = "living_room_temperature_evening";
        alias = "Living Room - Evening temperature";
        trigger = [
          {
            platform = "time";
            at = "22:00:00";
          }
        ];
        action = [
          {
            service = "climate.set_temperature";
            target.entity_id = "climate.livingroom_thermostat";
            data.temperature = 18;
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
