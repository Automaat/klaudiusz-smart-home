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
    # Presence Sensor 1 → h-3, h-4, h-5
    {
      id = "hallway_presence_1_lights_on";
      alias = "Hallway - Turn on lights zone 1 on presence";
      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_fac2_presence_sensor_1";
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
              condition = "sun";
              before = "sunrise";
            }
          ];
        }
      ];
      action = [
        {
          service = "light.turn_on";
          target.entity_id = [
            "light.hue_essential_spot_4_2" # h-3
            "light.hue_essential_spot_1_2" # h-4
            "light.hue_essential_spot_2_2" # h-5
          ];
        }
      ];
    }

    {
      id = "hallway_presence_1_lights_off";
      alias = "Hallway - Turn off lights zone 1 on clear";
      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_fac2_presence_sensor_1";
          to = "off";
        }
      ];
      action = [
        {
          service = "light.turn_off";
          target.entity_id = [
            "light.hue_essential_spot_4_2" # h-3
            "light.hue_essential_spot_1_2" # h-4
            "light.hue_essential_spot_2_2" # h-5
          ];
        }
      ];
    }

    # Presence Sensor 2 → h-1, h-2, h-3
    {
      id = "hallway_presence_2_lights_on";
      alias = "Hallway - Turn on lights zone 2 on presence";
      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_fac2_presence_sensor_2";
          to = "on";
        }
      ];
      action = [
        {
          service = "light.turn_on";
          target.entity_id = [
            "light.hue_essential_spot_3_2" # h-1
            "light.hue_essential_spot_5" # h-2
            "light.hue_essential_spot_4_2" # h-3
          ];
        }
      ];
    }

    {
      id = "hallway_presence_2_lights_off";
      alias = "Hallway - Turn off lights zone 2 on clear";
      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_sensor_fp2_fac2_presence_sensor_2";
          to = "off";
        }
      ];
      action = [
        {
          service = "light.turn_off";
          target.entity_id = [
            "light.hue_essential_spot_3_2" # h-1
            "light.hue_essential_spot_5" # h-2
            "light.hue_essential_spot_4_2" # h-3
          ];
        }
      ];
    }
  ];
}
