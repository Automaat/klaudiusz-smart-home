{
  config,
  pkgs,
  lib,
  ...
}: {
  # ===========================================
  # Hallway
  # ===========================================
  automation = [
    # Presence Sensor 3 → h-3, h-4, h-5
    {
      id = "hallway_presence_3_lights_on";
      alias = "Hallway - Turn on lights zone 1 (sensor 3) on presence";
      mode = "restart";
      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_fac2_presence_sensor_3";
          to = "on";
        }
      ];
      condition = [
        {
          condition = "state";
          entity_id = "input_boolean.away_mode";
          state = "off";
        }
      ];
      action = [
        {
          delay = "00:00:02";
        }
        {
          choose = [
            {
              conditions = [
                {
                  condition = "state";
                  entity_id = "binary_sensor.presence_sensor_fp2_fac2_presence_sensor_3";
                  state = "on";
                }
              ];
              sequence = [
                {
                  service = "adaptive_lighting.apply";
                  data = {
                    entity_id = "switch.adaptive_lighting_hallway_lights";
                    lights = [
                      "light.hue_essential_spot_4_2" # h-3
                      "light.hue_essential_spot_1_2" # h-4
                      "light.hue_essential_spot_2_2" # h-5
                    ];
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
      id = "hallway_presence_3_lights_off";
      alias = "Hallway - Turn off lights zone 1 (sensor 3) on clear";
      mode = "restart";
      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_fac2_presence_sensor_3";
          to = "off";
          for = "00:00:05";
        }
      ];
      action = [
        {
          service = "adaptive_lighting.set_manual_control";
          data = {
            entity_id = "switch.adaptive_lighting_hallway_lights";
            lights = [
              "light.hue_essential_spot_4_2" # h-3
              "light.hue_essential_spot_1_2" # h-4
              "light.hue_essential_spot_2_2" # h-5
            ];
            manual_control = true;
          };
        }
        {
          service = "light.turn_off";
          target.entity_id = [
            "light.hue_essential_spot_4_2" # h-3
            "light.hue_essential_spot_1_2" # h-4
            "light.hue_essential_spot_2_2" # h-5
          ];
          data = {
            transition = 1;
          };
        }
      ];
    }

    # Presence Sensor 2 → h-1, h-2
    {
      id = "hallway_presence_2_lights_on";
      alias = "Hallway - Turn on lights zone 2 on presence";
      mode = "restart";
      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_fac2_presence_sensor_2";
          to = "on";
        }
      ];
      condition = [
        {
          condition = "state";
          entity_id = "input_boolean.away_mode";
          state = "off";
        }
      ];
      action = [
        {
          delay = "00:00:02";
        }
        {
          choose = [
            {
              conditions = [
                {
                  condition = "state";
                  entity_id = "binary_sensor.presence_sensor_fp2_fac2_presence_sensor_2";
                  state = "on";
                }
              ];
              sequence = [
                {
                  service = "adaptive_lighting.apply";
                  data = {
                    entity_id = "switch.adaptive_lighting_hallway_lights";
                    lights = [
                      "light.hue_essential_spot_3_2" # h-1
                      "light.hue_essential_spot_5" # h-2
                    ];
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
      id = "hallway_presence_2_lights_off";
      alias = "Hallway - Turn off lights zone 2 on clear";
      mode = "restart";
      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_fac2_presence_sensor_2";
          to = "off";
          for = "00:00:05";
        }
      ];
      action = [
        {
          service = "adaptive_lighting.set_manual_control";
          data = {
            entity_id = "switch.adaptive_lighting_hallway_lights";
            lights = [
              "light.hue_essential_spot_3_2" # h-1
              "light.hue_essential_spot_5" # h-2
            ];
            manual_control = true;
          };
        }
        {
          service = "light.turn_off";
          target.entity_id = [
            "light.hue_essential_spot_3_2" # h-1
            "light.hue_essential_spot_5" # h-2
          ];
          data = {
            transition = 1;
          };
        }
      ];
    }
  ];
}
