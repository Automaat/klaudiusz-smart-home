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
      mode = "restart";
      triggers = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_b63f_presence_sensor_2";
          to = "on";
        }
      ];
      actions = [
        {
          delay = "00:00:02";
        }
        {
          choose = [
            # Person-aware: use preference when not guest_mode
            {
              conditions = [
                {
                  condition = "state";
                  entity_id = "binary_sensor.presence_sensor_fp2_b63f_presence_sensor_2";
                  state = "on";
                }
                {
                  condition = "state";
                  entity_id = "input_boolean.guest_mode";
                  state = "off";
                }
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
              sequence = [
                {
                  service = "switch.turn_off";
                  target.entity_id = "switch.adaptive_lighting_adapt_brightness_kitchen_lights";
                }
                {
                  service = "light.turn_on";
                  target.entity_id = "light.kitchen";
                  data = {
                    brightness_pct = "{{ states('sensor.active_brightness_preference_kitchen') | int }}";
                  };
                }
                {
                  service = "adaptive_lighting.set_manual_control";
                  data = {
                    entity_id = "switch.adaptive_lighting_kitchen_lights";
                    lights = ["light.kitchen"];
                    manual_control = false;
                  };
                }
              ];
            }
            # Fallback: guest_mode on, use default
            {
              conditions = [
                {
                  condition = "state";
                  entity_id = "binary_sensor.presence_sensor_fp2_b63f_presence_sensor_2";
                  state = "on";
                }
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
              sequence = [
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
          ];
        }
      ];
    }

    {
      id = "kitchen_presence_lights_off";
      alias = "Kitchen - Turn off lights on clear";
      triggers = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_b63f_presence_sensor_2";
          to = "off";
        }
      ];
      actions = [
        {
          delay = "00:00:20";
        }
        {
          condition = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_b63f_presence_sensor_2";
          state = "off";
        }
        {
          service = "adaptive_lighting.set_manual_control";
          data = {
            entity_id = "switch.adaptive_lighting_kitchen_lights";
            lights = ["light.kitchen"];
            manual_control = true;
          };
        }
        {
          service = "light.turn_off";
          target.entity_id = "light.kitchen";
        }
        {
          service = "switch.turn_on";
          target.entity_id = "switch.adaptive_lighting_adapt_brightness_kitchen_lights";
        }
      ];
    }
  ];
}
