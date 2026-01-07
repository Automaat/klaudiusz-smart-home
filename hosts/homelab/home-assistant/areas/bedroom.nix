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
          data.temperature = 22;
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
          entity_id = "climate.thermostat_bedroom";
          attribute = "current_temperature";
          above = 18;
        }
        {
          condition = "or";
          conditions = [
            {
              condition = "state";
              entity_id = "sensor.aleje_pm2_5_index";
              state = "very_good";
            }
            {
              condition = "state";
              entity_id = "sensor.aleje_pm2_5_index";
              state = "good";
            }
          ];
        }
      ];
      action = [
        {
          choose = [
            {
              conditions = [
                {
                  condition = "state";
                  entity_id = "media_player.tv";
                  state = "playing";
                }
              ];
              sequence = [
                {
                  action = "media_player.media_pause";
                  target.entity_id = "media_player.tv";
                }
                {
                  delay.seconds = 1;
                }
                {
                  action = "tts.speak";
                  target.entity_id = "tts.piper";
                  data = {
                    media_player_entity_id = "media_player.tv";
                    message = "Temperatura w sypialni {{ state_attr('climate.thermostat_bedroom', 'current_temperature') | round(0) }} stopni. Otwórz okno żeby wietrzyć przed snem";
                  };
                }
                {
                  delay.seconds = 1;
                }
                {
                  action = "media_player.media_play";
                  target.entity_id = "media_player.tv";
                }
              ];
            }
          ];
          default = [
            {
              action = "tts.speak";
              target.entity_id = "tts.piper";
              data = {
                media_player_entity_id = "media_player.tv";
                message = "Temperatura w sypialni {{ state_attr('climate.thermostat_bedroom', 'current_temperature') | round(0) }} stopni. Otwórz okno żeby wietrzyć przed snem";
              };
            }
          ];
        }
      ];
      mode = "single";
    }
  ];
}
