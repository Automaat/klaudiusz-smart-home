{
  config,
  pkgs,
  lib,
  ...
}: {
  # ===========================================
  # Bathroom
  # ===========================================
  automation = [
    # === Thermal Automations ===
    {
      id = "bathroom_morning_boost_start";
      alias = "Bathroom - Morning boost start";
      trigger = [
        {
          platform = "time";
          at = "06:00:00";
        }
      ];
      action = [
        {
          service = "climate.set_temperature";
          target.entity_id = "climate.bathroom_thermostat";
          data.temperature = 24;
        }
      ];
    }

    {
      id = "bathroom_morning_boost_end";
      alias = "Bathroom - Morning boost end";
      trigger = [
        {
          platform = "time";
          at = "09:00:00";
        }
      ];
      action = [
        {
          service = "climate.set_temperature";
          target.entity_id = "climate.bathroom_thermostat";
          data.temperature = 19;
        }
      ];
    }

    # === Presence-Based Lighting ===
    {
      id = "bathroom_presence_lights_on";
      alias = "Bathroom - Turn on lights on presence";
      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_sensor_presence";
          to = "on";
        }
      ];
      condition = [
        {
          condition = "state";
          entity_id = "input_boolean.away_mode";
          state = "off";
        }
        {
          condition = "state";
          entity_id = "binary_sensor.presence_sensor_presence";
          state = "on";
        }
      ];
      action = [
        {
          service = "adaptive_lighting.apply";
          data = {
            entity_id = "switch.adaptive_lighting_bathroom_lights";
            lights = ["light.bathroom"];
            turn_on_lights = true;
          };
        }
      ];
    }

    {
      id = "bathroom_presence_lights_off";
      alias = "Bathroom - Turn off lights on clear";
      mode = "restart";
      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_sensor_presence";
          to = "off";
          for = "00:00:05";
        }
      ];
      action = [
        {
          service = "light.turn_off";
          target.entity_id = "light.bathroom";
          data = {
            transition = 1;
          };
        }
      ];
    }
  ];
}
