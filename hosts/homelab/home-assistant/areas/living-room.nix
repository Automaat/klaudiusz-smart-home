{
  config,
  pkgs,
  lib,
  ...
}: let
  # Air purifier entity constant
  airPurifier = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
in {
  # ===========================================
  # Living Room
  # ===========================================
  automation = [
    # -----------------------------------------
    # Climate Control
    # -----------------------------------------
    {
      id = "living_room_temperature_morning";
      alias = "Living Room - Morning temperature";
      trigger = [
        {
          platform = "time";
          at = "06:00:00";
        }
      ];
      action = [
        {
          service = "climate.set_temperature";
          target.entity_id = "climate.livingroom_thermostat";
          data.temperature = 21;
        }
      ];
    }

    {
      id = "living_room_temperature_evening";
      alias = "Living Room - Evening temperature";
      trigger = [
        {
          platform = "time";
          at = "22:00:00";
        }
      ];
      action = [
        {
          service = "climate.set_temperature";
          target.entity_id = "climate.livingroom_thermostat";
          data.temperature = 18;
        }
      ];
    }

    # -----------------------------------------
    # TV Control
    # -----------------------------------------
    {
      id = "lg_c2_turn_on";
      alias = "TV - Turn on LG C2";
      trigger = [
        {
          platform = "webostv.turn_on";
          entity_id = "media_player.tv";
        }
      ];
      action = [
        {
          action = "wake_on_lan.send_magic_packet";
          data = {
            mac = "20:28:bc:69:b9:84";
            broadcast_address = "192.168.0.255";
          };
        }
      ];
    }

    # -----------------------------------------
    # Air Purifier
    # -----------------------------------------
    {
      id = "air_purifier_outdoor_mode_switch";
      alias = "Air Purifier - Outdoor mode switching";
      description = "Adjust purifier mode based on outdoor PM2.5 levels";
      trigger = [
        {
          platform = "state";
          entity_id = "sensor.airly_home_pm2_5";
        }
      ];
      condition = [
        {
          condition = "state";
          entity_id = airPurifier;
          state = "on";
        }
      ];
      action = [
        {
          choose = [
            {
              conditions = [
                {
                  condition = "numeric_state";
                  entity_id = "sensor.airly_home_pm2_5";
                  above = 75;
                }
              ];
              sequence = [
                {
                  action = "fan.set_preset_mode";
                  target.entity_id = airPurifier;
                  data.preset_mode = "Manual";
                }
                {
                  action = "fan.set_percentage";
                  target.entity_id = airPurifier;
                  data.percentage = 100;
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "numeric_state";
                  entity_id = "sensor.airly_home_pm2_5";
                  above = 50;
                  below = 75;
                }
              ];
              sequence = [
                {
                  action = "fan.set_preset_mode";
                  target.entity_id = airPurifier;
                  data.preset_mode = "Manual";
                }
                {
                  action = "fan.set_percentage";
                  target.entity_id = airPurifier;
                  data.percentage = 66;
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "numeric_state";
                  entity_id = "sensor.airly_home_pm2_5";
                  below = 15;
                }
              ];
              sequence = [
                {
                  action = "fan.set_preset_mode";
                  target.entity_id = airPurifier;
                  data.preset_mode = "Night";
                }
              ];
            }
          ];
          default = [
            {
              action = "fan.set_preset_mode";
              target.entity_id = airPurifier;
              data.preset_mode = "Manual";
            }
            {
              action = "fan.set_percentage";
              target.entity_id = airPurifier;
              data.percentage = 33;
            }
          ];
        }
      ];
      mode = "single";
    }

    {
      id = "air_purifier_indoor_boost";
      alias = "Air Purifier - Indoor quality boost";
      description = "Boost purification when indoor PM2.5 exceeds threshold";
      trigger = [
        {
          platform = "numeric_state";
          entity_id = "sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6";
          above = 25;
          "for".minutes = 5;
        }
      ];
      action = [
        {
          action = "fan.turn_on";
          target.entity_id = airPurifier;
        }
        {
          action = "fan.set_preset_mode";
          target.entity_id = airPurifier;
          data.preset_mode = "Manual";
        }
        {
          choose = [
            {
              conditions = [
                {
                  condition = "numeric_state";
                  entity_id = "sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6";
                  above = 50;
                }
              ];
              sequence = [
                {
                  action = "fan.set_percentage";
                  target.entity_id = airPurifier;
                  data.percentage = 100;
                }
              ];
            }
          ];
          default = [
            {
              action = "fan.set_percentage";
              target.entity_id = airPurifier;
              data.percentage = 66;
            }
          ];
        }
      ];
      mode = "single";
    }

    {
      id = "air_purifier_sleep_mode";
      alias = "Air Purifier - Adaptive sleep mode";
      description = "Manual 66% if outdoor PM2.5 >75, else Night mode during sleep hours";
      trigger = [
        {
          platform = "time";
          at = "21:00:00";
        }
        {
          platform = "state";
          entity_id = "sensor.airly_home_pm2_5";
        }
      ];
      condition = [
        {
          condition = "time";
          after = "21:00:00";
          before = "07:00:00";
        }
      ];
      action = [
        {
          choose = [
            {
              conditions = [
                {
                  condition = "numeric_state";
                  entity_id = "sensor.airly_home_pm2_5";
                  above = 75;
                }
              ];
              sequence = [
                {
                  action = "fan.set_preset_mode";
                  target.entity_id = airPurifier;
                  data.preset_mode = "Manual";
                }
                {
                  action = "fan.set_percentage";
                  target.entity_id = airPurifier;
                  data.percentage = 66;
                }
              ];
            }
          ];
          default = [
            {
              action = "fan.set_preset_mode";
              target.entity_id = airPurifier;
              data.preset_mode = "Night";
            }
          ];
        }
      ];
      mode = "single";
    }

    {
      id = "air_purifier_ventilation_reminder";
      alias = "Air Purifier - Ventilation safety reminder";
      description = "TTS reminder when outdoor AQ is better than indoor";
      trigger = [
        {
          platform = "time";
          at = "07:00:00";
        }
        {
          platform = "time";
          at = "21:00:00";
        }
      ];
      condition = [
        {
          condition = "state";
          entity_id = "binary_sensor.safe_to_ventilate_living_room";
          state = "on";
        }
      ];
      action = [
        {
          action = "tts.speak";
          target.entity_id = "tts.piper";
          data = {
            media_player_entity_id = "media_player.home_assistant_voice_0a5def_media_player";
            message = "Możesz otworzyć okno w salonie, powietrze na zewnątrz lepsze niż w środku. PM2.5 zewnątrz {{ states('sensor.airly_home_pm2_5') }}, wewnątrz {{ states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') }} mikrogramów.";
          };
        }
      ];
      mode = "single";
    }

    {
      id = "air_purifier_away_mode";
      alias = "Air Purifier - Away mode optimization";
      description = "Adjust operation based on outdoor AQ during away mode";
      trigger = [
        {
          platform = "state";
          entity_id = "input_boolean.away_mode";
          to = "on";
        }
      ];
      action = [
        {
          choose = [
            {
              conditions = [
                {
                  condition = "numeric_state";
                  entity_id = "sensor.airly_home_pm2_5";
                  below = 25;
                }
              ];
              sequence = [
                {
                  action = "fan.turn_off";
                  target.entity_id = airPurifier;
                }
              ];
            }
            {
              conditions = [
                {
                  condition = "numeric_state";
                  entity_id = "sensor.airly_home_pm2_5";
                  above = 50;
                }
              ];
              sequence = [
                {
                  action = "fan.turn_on";
                  target.entity_id = airPurifier;
                }
                {
                  action = "fan.set_preset_mode";
                  target.entity_id = airPurifier;
                  data.preset_mode = "Manual";
                }
                {
                  action = "fan.set_percentage";
                  target.entity_id = airPurifier;
                  data.percentage = 66;
                }
              ];
            }
          ];
          default = [
            {
              action = "fan.set_preset_mode";
              target.entity_id = airPurifier;
              data.preset_mode = "Manual";
            }
            {
              action = "fan.set_percentage";
              target.entity_id = airPurifier;
              data.percentage = 33;
            }
          ];
        }
      ];
      mode = "single";
    }

    {
      id = "air_purifier_filter_replacement_todoist";
      alias = "Air Purifier - Filter replacement Todoist (Living Room)";
      description = "Create Todoist task when filter needs replacement";
      trigger = [
        {
          platform = "numeric_state";
          entity_id = "sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3";
          below = 20;
        }
      ];
      condition = [
        {
          condition = "template";
          value_template = "{{ states('input_datetime.last_filter_task_living_room') == 'unknown' or (now() - as_datetime(states('input_datetime.last_filter_task_living_room'))).days >= 30 }}";
        }
      ];
      action = [
        {
          action = "todoist.new_task";
          data = {
            content = "Wymień filtr HEPA oczyszczacza (Salon) - {{ states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') }}% pozostało";
            "project" = "Home";
            priority = 3;
            due_date_string = "za 2 tygodnie";
            due_date_lang = "pl";
            labels = "dom,konserwacja";
            description = "Filtr zużyty w {{ 100 - states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') | int }}%. Aktualny czas pracy: {{ states('sensor.zhimi_de_334622045_mb3_filter_used_time_p_4_5') }}h";
          };
        }
        {
          action = "input_datetime.set_datetime";
          target.entity_id = "input_datetime.last_filter_task_living_room";
          data.datetime = "{{ now().isoformat() }}";
        }
      ];
      mode = "single";
    }

    {
      id = "air_purifier_filter_tts_alert";
      alias = "Air Purifier - Filter TTS alert";
      description = "Voice alert for critical filter levels";
      trigger = [
        {
          platform = "numeric_state";
          entity_id = "sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3";
          below = 10;
        }
      ];
      action = [
        {
          action = "tts.speak";
          target.entity_id = "tts.piper";
          data = {
            media_player_entity_id = "media_player.home_assistant_voice_0a5def_media_player";
            message = "Uwaga! Filtr oczyszczacza powietrza wymaga wymiany. Pozostało tylko {{ states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') }} procent żywotności.";
          };
        }
      ];
      mode = "single";
    }

    {
      id = "air_purifier_antibacterial_auto";
      alias = "Air Purifier - Antibacterial auto run";
      description = "Automatic weekly antibacterial filter activation (high power run)";
      trigger = [
        {
          platform = "time";
          at = "03:00:00";
        }
      ];
      condition = [
        {
          condition = "time";
          weekday = ["sun"];
        }
      ];
      action = [
        {
          action = "fan.turn_on";
          target.entity_id = airPurifier;
        }
        {
          action = "fan.set_preset_mode";
          target.entity_id = airPurifier;
          data.preset_mode = "Manual";
        }
        {
          action = "fan.set_percentage";
          target.entity_id = airPurifier;
          data.percentage = 100;
        }
        {
          delay.hours = 2;
        }
        {
          action = "input_datetime.set_datetime";
          target.entity_id = "input_datetime.last_antibacterial_run";
          data.datetime = "{{ now().isoformat() }}";
        }
      ];
      mode = "single";
    }

    {
      id = "air_purifier_daily_start";
      alias = "Air Purifier - Daily auto-start";
      description = "Ensure purifier runs during occupied hours";
      trigger = [
        {
          platform = "time";
          at = "07:00:00";
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
          action = "fan.turn_on";
          target.entity_id = airPurifier;
        }
        {
          action = "fan.set_preset_mode";
          target.entity_id = airPurifier;
          data.preset_mode = "Manual";
        }
        {
          action = "fan.set_percentage";
          target.entity_id = airPurifier;
          data.percentage = 33;
        }
      ];
      mode = "single";
    }
  ];
}
