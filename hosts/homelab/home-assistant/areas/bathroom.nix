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
  ];
}
