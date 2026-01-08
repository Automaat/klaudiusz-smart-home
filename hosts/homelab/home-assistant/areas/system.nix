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
            media_player_entity_id = "media_player.home_assistant_voice_0a5def_media_player";
            message = "Zadanie dodane do listy";
          };
        }
      ];
    }

    # -----------------------------------------
    # Adaptive Lighting
    # -----------------------------------------
    {
      id = "adaptive_lighting_enable_sleep_mode";
      alias = "Adaptive Lighting - Enable sleep mode all";
      description = "Enable sleep mode on all adaptive lighting switches. Trigger manually via automation.trigger service";
      trigger = [];
      action = [
        {
          action = "adaptive_lighting.set_manual_control";
          target.entity_id = adaptiveLightingSwitches;
          data = {
            manual_control = false;
          };
        }
        {
          action = "adaptive_lighting.change_switch_settings";
          target.entity_id = adaptiveLightingSwitches;
          data = {
            use_defaults = "current";
            sleep_mode_switch = true;
          };
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
          action = "adaptive_lighting.change_switch_settings";
          target.entity_id = adaptiveLightingSwitches;
          data = {
            use_defaults = "current";
            sleep_mode_switch = false;
          };
        }
      ];
    }

    # -----------------------------------------
    # Leaving Home
    # -----------------------------------------
    {
      id = "leaving_home";
      alias = "System - Leaving home";
      description = "Turn off all lights, TV, and smart plugs when leaving home. Can be triggered via location change or manual toggle.";
      trigger = [
        # Location based
        {
          platform = "state";
          entity_id = "person.marcin";
          to = "not_home";
        }
        # Manual toggle
        {
          platform = "state";
          entity_id = "input_boolean.away_mode";
          to = "on";
        }
      ];
      action = [
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
