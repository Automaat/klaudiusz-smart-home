{
  config,
  pkgs,
  lib,
  ...
}: let
  # Import Nix-managed automations from separate data file
  # (shared with default.nix for YAML generation)
  nixAutomations = import ./automations-data.nix;
in {
  services.home-assistant.config = {
    # ===========================================
    # Hybrid Automation Mode
    # ===========================================
    # Nix automations: automations/nix.yaml (regenerated on restart)
    # GUI automations: automations/*.yaml (persisted, editable via UI)
    # Override monitoring.nix automations (will be included via YAML files instead)
    automation = lib.mkForce "!include_dir_merge_list automations/";

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
