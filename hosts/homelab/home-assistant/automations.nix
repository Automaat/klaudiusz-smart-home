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
      # Motion Lights (example)
      # -----------------------------------------
      # {
      #   id = "motion_hallway_light";
      #   alias = "Światło - Korytarz przy ruchu";
      #   trigger = [{
      #     platform = "state";
      #     entity_id = "binary_sensor.motion_korytarz";
      #     to = "on";
      #   }];
      #   condition = [{
      #     condition = "sun";
      #     after = "sunset";
      #     before = "sunrise";
      #   }];
      #   action = [
      #     {
      #       service = "light.turn_on";
      #       target.entity_id = "light.korytarz";
      #       data.brightness_pct = 50;
      #     }
      #     { delay.minutes = 5; }
      #     {
      #       service = "light.turn_off";
      #       target.entity_id = "light.korytarz";
      #     }
      #   ];
      # }

      # -----------------------------------------
      # Security (example)
      # -----------------------------------------
      # {
      #   id = "security_motion_when_away";
      #   alias = "Bezpieczeństwo - Ruch gdy poza domem";
      #   trigger = [{
      #     platform = "state";
      #     entity_id = "binary_sensor.motion_salon";
      #     to = "on";
      #   }];
      #   condition = [{
      #     condition = "state";
      #     entity_id = "input_boolean.away_mode";
      #     state = "on";
      #   }];
      #   action = [{
      #     service = "notify.mobile_app";
      #     data = {
      #       title = "⚠️ Alert!";
      #       message = "Wykryto ruch w salonie!";
      #     };
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
      movie_mode = {
        alias = "Tryb filmowy";
        sequence = [
          {
            service = "light.turn_off";
            target.entity_id = "light.salon";
          }
          {
            service = "light.turn_on";
            target.entity_id = "light.tv_backlight";
            data.brightness_pct = 20;
          }
          {
            service = "cover.close_cover";
            target.entity_id = "cover.salon";
          }
        ];
        icon = "mdi:movie-open";
      };

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
