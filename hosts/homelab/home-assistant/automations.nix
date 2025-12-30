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
