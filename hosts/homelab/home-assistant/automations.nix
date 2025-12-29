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
      # Mode Management
      # -----------------------------------------
      {
        id = "disable_sleep_mode_morning";
        alias = "Tryb nocny - Wyłącz rano";
        trigger = [
          {
            platform = "time";
            at = "07:00:00";
          }
        ];
        condition = [
          {
            condition = "state";
            entity_id = "input_boolean.sleep_mode";
            state = "on";
          }
        ];
        action = [
          {
            service = "input_boolean.turn_off";
            target.entity_id = "input_boolean.sleep_mode";
          }
          {
            service = "persistent_notification.create";
            data = {
              title = "Tryb nocny";
              message = "Tryb nocny został wyłączony automatycznie";
            };
          }
        ];
      }

      {
        id = "guest_mode_disable_automations";
        alias = "Tryb gościa - Wyłącz automatykę";
        description = "Przykład: tryb gościa może zmieniać zachowanie automatyzacji";
        trigger = [
          {
            platform = "state";
            entity_id = "input_boolean.guest_mode";
            to = "on";
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "Tryb gościa";
              message = "Tryb gościa włączony - niektóre automatyzacje mogą być ograniczone";
            };
          }
        ];
      }

      {
        id = "guest_mode_notify_off";
        alias = "Tryb gościa - Powiadomienie wyłączenia";
        trigger = [
          {
            platform = "state";
            entity_id = "input_boolean.guest_mode";
            to = "off";
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "Tryb gościa";
              message = "Tryb gościa wyłączony - przywrócono normalną automatykę";
            };
          }
        ];
      }

      {
        id = "set_default_brightness";
        alias = "Jasność - Ustaw domyślną przy starcie";
        trigger = [
          {
            platform = "homeassistant";
            event = "start";
          }
        ];
        action = [
          {
            service = "input_number.set_value";
            target.entity_id = "input_number.default_brightness";
            data.value = 80;
          }
        ];
      }
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
            target.entity_id = "all";
          }
          {
            service = "cover.close_cover";
            target.entity_id = "all";
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
