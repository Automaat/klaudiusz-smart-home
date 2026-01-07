{
  config,
  pkgs,
  lib,
  ...
}: {
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
}
