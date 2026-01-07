{
  config,
  pkgs,
  lib,
  ...
}: {
  # ===========================================
  # Kitchen
  # ===========================================
  automation = [
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
          service = "adaptive_lighting.apply";
          data = {
            entity_id = "switch.adaptive_lighting_kitchen_lights";
            lights = ["light.kitchen"];
            turn_on_lights = true;
          };
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
  ];
}
