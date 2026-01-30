{
  config,
  pkgs,
  lib,
  ...
}: {
  # ===========================================
  # Garderoba
  # ===========================================
  automation = [
    {
      id = "garderoba_motion_lights_on";
      alias = "Garderoba - Turn on lights on motion";
      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.motion_sensor";
          to = "on";
        }
      ];
      condition = [
        {
          condition = "state";
          entity_id = "binary_sensor.motion_sensor";
          state = "on";
        }
      ];
      action = [
        {
          service = "adaptive_lighting.apply";
          data = {
            entity_id = "switch.adaptive_lighting_garderoba_lights";
            lights = ["light.garderoba"];
            turn_on_lights = true;
          };
        }
      ];
    }

    {
      id = "garderoba_motion_lights_off";
      alias = "Garderoba - Turn off lights when clear";
      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.motion_sensor";
          to = "off";
        }
      ];
      action = [
        {
          service = "light.turn_off";
          target.entity_id = "light.garderoba";
        }
      ];
    }
  ];
}
