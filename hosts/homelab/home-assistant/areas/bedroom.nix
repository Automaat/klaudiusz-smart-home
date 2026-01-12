{
  config,
  pkgs,
  lib,
  ...
}: {
  # ===========================================
  # Bedroom
  # ===========================================
  automation = [
    {
      id = "bedroom_temperature_morning";
      alias = "Bedroom - Morning temperature";
      trigger = [
        {
          platform = "time";
          at = "06:00:00";
        }
      ];
      action = [
        {
          service = "climate.set_temperature";
          target.entity_id = "climate.bedroom_thermostat";
          data.temperature = 24;
        }
      ];
    }

    {
      id = "bedroom_temperature_day";
      alias = "Bedroom - Day temperature";
      trigger = [
        {
          platform = "time";
          at = "09:00:00";
        }
      ];
      action = [
        {
          service = "climate.set_temperature";
          target.entity_id = "climate.bedroom_thermostat";
          data.temperature = 18;
        }
      ];
    }

    {
      id = "bedroom_sleep_ventilation";
      alias = "Bedroom - Sleep ventilation reminder";
      trigger = [
        {
          platform = "time";
          at = "21:00:00";
        }
      ];
      condition = [
        {
          condition = "numeric_state";
          entity_id = "climate.bedroom_thermostat";
          attribute = "current_temperature";
          above = 18;
        }
        {
          condition = "or";
          conditions = [
            {
              condition = "template";
              value_template = "{{ state_attr('sensor.airly_home_ogolny_indeks_jakosci_powietrza', 'level') == 'high' }}";
            }
            {
              condition = "template";
              value_template = "{{ state_attr('sensor.airly_home_ogolny_indeks_jakosci_powietrza', 'level') == 'very_high' }}";
            }
          ];
        }
      ];
      action = [
        {
          action = "tts.speak";
          target.entity_id = "tts.piper";
          data = {
            media_player_entity_id = "media_player.tv";
            message = "Temperatura w sypialni {{ state_attr('climate.bedroom_thermostat', 'current_temperature') | round(0) }} stopni. Otwórz okno żeby wietrzyć przed snem";
          };
        }
      ];
      mode = "single";
    }
  ];
}
