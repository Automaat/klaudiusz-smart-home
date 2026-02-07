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

    # -----------------------------------------
    # Sleep Mode - Auto (Person Tracking)
    # -----------------------------------------
    # NOTE: Disabled until person tracking sensors updated
    # {
    #   id = "sleep_mode_auto_enable";
    #   alias = "Bedroom - Enable sleep mode when both in bed";
    #   trigger = [
    #     { platform = "state"; entity_id = "sensor.marcin_current_room"; to = "bedroom"; for = "00:05:00"; }
    #     { platform = "state"; entity_id = "sensor.ewa_current_room"; to = "bedroom"; for = "00:05:00"; }
    #   ];
    #   condition = [
    #     { condition = "state"; entity_id = "sensor.marcin_current_room"; state = "bedroom"; }
    #     { condition = "state"; entity_id = "sensor.ewa_current_room"; state = "bedroom"; }
    #     { condition = "time"; after = "21:00:00"; before = "06:00:00"; }
    #   ];
    #   action = [
    #     { service = "input_boolean.turn_on"; target.entity_id = "input_boolean.sleep_mode"; }
    #   ];
    #   mode = "single";
    # }
    #
    # {
    #   id = "sleep_mode_auto_disable";
    #   alias = "Bedroom - Disable sleep mode when anyone leaves";
    #   trigger = [
    #     { platform = "state"; entity_id = "sensor.marcin_current_room"; from = "bedroom"; }
    #     { platform = "state"; entity_id = "sensor.ewa_current_room"; from = "bedroom"; }
    #   ];
    #   condition = [
    #     { condition = "time"; after = "05:00:00"; before = "10:00:00"; }
    #   ];
    #   action = [
    #     { service = "input_boolean.turn_off"; target.entity_id = "input_boolean.sleep_mode"; }
    #   ];
    #   mode = "single";
    # }
  ];
}
