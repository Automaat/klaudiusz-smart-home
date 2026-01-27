{
  config,
  pkgs,
  lib,
  ...
}: let
  adaptiveLightingSwitches = [
    "switch.adaptive_lighting_hallway_lights"
    "switch.adaptive_lighting_kitchen_lights"
    "switch.adaptive_lighting_bathroom_lights"
  ];
  adaptiveLightingSleepModeSwitches = [
    "switch.adaptive_lighting_sleep_mode_hallway_lights"
    "switch.adaptive_lighting_sleep_mode_kitchen_lights"
    "switch.adaptive_lighting_sleep_mode_bathroom_lights"
  ];
in {
  # ===========================================
  # System & Task Management
  # ===========================================
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
          service = "frontend.set_theme";
          data = {
            name = "Catppuccin Latte";
          };
        }
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
    # Adaptive Lighting
    # -----------------------------------------
    {
      id = "sleep_mode_force_hallway_lights_off";
      alias = "System - Force hallway lights off at sleep mode";
      description = "Ensure hallway lights turn off when sleep mode activates, unless presence detected";
      trigger = [
        {
          platform = "state";
          entity_id = "input_boolean.sleep_mode";
          to = "on";
        }
      ];
      condition = [
        {
          condition = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_fac2_presence_sensor_2";
          state = "off";
          for = "00:00:10";
        }
        {
          condition = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_fac2_presence_sensor_3";
          state = "off";
          for = "00:00:10";
        }
      ];
      action = [
        {
          service = "light.turn_off";
          target.entity_id = [
            "light.hue_essential_spot_3_2" # h-1
            "light.hue_essential_spot_5" # h-2
            "light.hue_essential_spot_4_2" # h-3
            "light.hue_essential_spot_1_2" # h-4
            "light.hue_essential_spot_2_2" # h-5
          ];
          data = {
            transition = 2;
          };
        }
      ];
      mode = "single";
    }

    {
      id = "adaptive_lighting_enable_sleep_mode";
      alias = "Adaptive Lighting - Enable sleep mode on sleep";
      description = "Enable sleep mode on all adaptive lighting switches when sleep mode is activated";
      trigger = [
        {
          platform = "state";
          entity_id = "input_boolean.sleep_mode";
          to = "on";
          for = "00:01:00";
        }
      ];
      action = [
        {
          action = "switch.turn_on";
          target.entity_id = adaptiveLightingSleepModeSwitches;
        }
      ];
    }

    {
      id = "adaptive_lighting_disable_sleep_mode_manual";
      alias = "Adaptive Lighting - Disable sleep mode on wake";
      description = "Disable sleep mode on all adaptive lighting switches when sleep mode is deactivated";
      trigger = [
        {
          platform = "state";
          entity_id = "input_boolean.sleep_mode";
          to = "off";
        }
      ];
      action = [
        {
          action = "switch.turn_off";
          target.entity_id = adaptiveLightingSleepModeSwitches;
        }
      ];
    }

    {
      id = "adaptive_lighting_disable_sleep_mode_sunrise";
      alias = "Adaptive Lighting - Disable sleep mode on sunrise";
      trigger = [
        {
          platform = "sun";
          event = "sunrise";
        }
      ];
      action = [
        {
          action = "input_boolean.turn_off";
          target.entity_id = "input_boolean.sleep_mode";
        }
        {
          action = "switch.turn_off";
          target.entity_id = adaptiveLightingSleepModeSwitches;
        }
      ];
    }

    {
      id = "adaptive_lighting_enable_sleep_mode_23_00";
      alias = "Adaptive Lighting - Enable sleep mode at 23:00";
      description = "Enable sleep mode at 23:00";
      trigger = [
        {
          platform = "time";
          at = "23:00:00";
        }
      ];
      action = [
        {
          action = "input_boolean.turn_on";
          target.entity_id = "input_boolean.sleep_mode";
        }
      ];
    }

    # -----------------------------------------
    # Stuck Light Detection
    # -----------------------------------------
    {
      id = "hallway_lights_stuck_alert";
      alias = "Alert - Hallway lights stuck on during sleep";
      description = "Notify when hallway lights stay on >5min during sleep mode without presence";
      trigger = [
        {
          platform = "state";
          entity_id = [
            "light.hue_essential_spot_3_2"
            "light.hue_essential_spot_5"
          ];
          to = "on";
          for = "00:05:00";
        }
      ];
      condition = [
        {
          condition = "state";
          entity_id = "input_boolean.sleep_mode";
          state = "on";
        }
        {
          condition = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_fac2_presence_sensor_2";
          state = "off";
          for = "00:01:00";
        }
      ];
      action = [
        {
          service = "persistent_notification.create";
          data = {
            title = "Hallway Lights Stuck";
            message = "Zone 2 lights on >5min during sleep without presence. Check automation logs.";
            notification_id = "hallway_lights_stuck";
          };
        }
        {
          service = "light.turn_off";
          target.entity_id = [
            "light.hue_essential_spot_3_2"
            "light.hue_essential_spot_5"
          ];
        }
      ];
      mode = "single";
    }

    # -----------------------------------------
    # Leaving Home
    # -----------------------------------------
    {
      id = "leaving_home";
      alias = "System - Leaving home";
      description = "Turn off all lights, TV, and smart plugs when leaving home via button or manual toggle.";
      trigger = [
        # Manual toggle
        {
          platform = "state";
          entity_id = "input_boolean.away_mode";
          to = "on";
        }
        # Physical button (single press)
        {
          platform = "event";
          event_type = "zha_event";
          event_data = {
            device_ieee = "54:ef:44:10:00:ec:31:6a";
            command = "single";
          };
        }
      ];
      action = [
        # Ensure away mode is active for all triggers (button + manual)
        {
          action = "input_boolean.turn_on";
          target.entity_id = "input_boolean.away_mode";
        }
        # Turn off all lights
        {
          action = "light.turn_off";
          target.entity_id = "all";
        }
        # Turn off TV
        {
          action = "media_player.turn_off";
          target.entity_id = "media_player.tv";
        }
        # Turn off smart plugs
        {
          action = "switch.turn_off";
          target.entity_id = [
            "switch.sonoff_plug"
            "switch.sonoff_plug_2"
          ];
        }
      ];
      mode = "single";
    }
  ];
}
