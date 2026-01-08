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
  ];
}
