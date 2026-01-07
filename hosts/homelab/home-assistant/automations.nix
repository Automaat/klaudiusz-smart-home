{
  config,
  pkgs,
  lib,
  ...
}: {
  services.home-assistant.config = {
    # ===========================================
    # Core Automations (managed in Nix)
    # ===========================================
    # Simple/experimental automations can be created in GUI

    automation = [
      # -----------------------------------------
      # Startup
      # -----------------------------------------
      {
        id = "startup_notification";
        alias = "System - Startup notification";
        trigger = [
          {
            platform = "homeassistant";
            event = "start";
          }
        ];
        action = [
          {
            service = "persistent_notification.create";
            data = {
              title = "Home Assistant";
              message = "System started at {{ now().strftime('%H:%M') }}";
            };
          }
          # {
          #   action = "notify.send_message";
          #   target.entity_id = "notify.klaudiusz_smart_home_system";
          #   data = {
          #     message = "✅ Home Assistant started at {{ now().strftime('%H:%M') }}";
          #   };
          # }
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
      # Task Management (Todoist)
      # -----------------------------------------
      {
        id = "todoist_task_added_confirmation";
        alias = "Todoist - Task added confirmation";
        trigger = [
          {
            platform = "state";
            entity_id = "todo.inbox";
          }
        ];
        condition = [
          {
            condition = "template";
            value_template = "{{ trigger.to_state.state | int > trigger.from_state.state | int }}";
          }
        ];
        action = [
          {
            service = "tts.speak";
            target.entity_id = "tts.piper";
            data = {
              message = "Zadanie dodane do listy";
            };
          }
        ];
      }

      # -----------------------------------------
      # Kitchen
      # -----------------------------------------
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

      # -----------------------------------------
      # Bathroom
      # -----------------------------------------
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

      # -----------------------------------------
      # Bedroom
      # -----------------------------------------
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

      # -----------------------------------------
      # Living Room
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
      # Mode Management (Placeholder - no devices yet)
      # -----------------------------------------
      # {
      #   id = "disable_sleep_mode_morning";
      #   alias = "Tryb nocny - Wyłącz rano";
      #   trigger = [{
      #     platform = "time";
      #     at = "07:00:00";
      #   }];
      #   condition = [{
      #     condition = "state";
      #     entity_id = "input_boolean.sleep_mode";
      #     state = "on";
      #   }];
      #   action = [{
      #     service = "input_boolean.turn_off";
      #     target.entity_id = "input_boolean.sleep_mode";
      #   }];
      # }

      # -----------------------------------------
      # Air Purifier (Phase 3)
      # -----------------------------------------
      {
        id = "air_purifier_outdoor_mode_switch";
        alias = "Air Purifier - Outdoor mode switching";
        description = "Adjust purifier mode based on outdoor PM2.5 levels";
        trigger = [
          {
            platform = "state";
            entity_id = "sensor.aleje_pm2_5";
          }
        ];
        condition = [
          {
            condition = "state";
            entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
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
                    entity_id = "sensor.aleje_pm2_5";
                    above = 75;
                  }
                ];
                sequence = [
                  {
                    action = "fan.set_preset_mode";
                    target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
                    data.preset_mode = "Auto";
                  }
                ];
              }
              {
                conditions = [
                  {
                    condition = "numeric_state";
                    entity_id = "sensor.aleje_pm2_5";
                    below = 15;
                  }
                ];
                sequence = [
                  {
                    action = "fan.set_preset_mode";
                    target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
                    data.preset_mode = "Night";
                  }
                ];
              }
            ];
            default = [
              {
                action = "fan.set_preset_mode";
                target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
                data.preset_mode = "Auto";
              }
            ];
          }
        ];
        mode = "restart";
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
            target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
          }
          {
            action = "fan.set_preset_mode";
            target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
            data.preset_mode = "Auto";
          }
        ];
        mode = "single";
      }

      {
        id = "air_purifier_sleep_mode";
        alias = "Air Purifier - Adaptive sleep mode";
        description = "Auto if outdoor PM2.5 >75, else Night mode during sleep hours";
        trigger = [
          {
            platform = "time";
            at = "21:00:00";
          }
          {
            platform = "state";
            entity_id = "sensor.aleje_pm2_5";
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
                    entity_id = "sensor.aleje_pm2_5";
                    above = 75;
                  }
                ];
                sequence = [
                  {
                    action = "fan.set_preset_mode";
                    target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
                    data.preset_mode = "Auto";
                  }
                ];
              }
            ];
            default = [
              {
                action = "fan.set_preset_mode";
                target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
                data.preset_mode = "Night";
              }
            ];
          }
        ];
        mode = "restart";
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
              media_player_entity_id = "media_player.vlc_telnet";
              message = "Możesz otworzyć okno w salonie, powietrze na zewnątrz lepsze niż w środku. PM2.5 zewnątrz {{ states('sensor.aleje_pm2_5') }}, wewnątrz {{ states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') }} mikrogramów.";
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
                    entity_id = "sensor.aleje_pm2_5";
                    below = 25;
                  }
                ];
                sequence = [
                  {
                    action = "fan.turn_off";
                    target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
                  }
                ];
              }
              {
                conditions = [
                  {
                    condition = "numeric_state";
                    entity_id = "sensor.aleje_pm2_5";
                    above = 50;
                  }
                ];
                sequence = [
                  {
                    action = "fan.set_preset_mode";
                    target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
                    data.preset_mode = "Auto";
                  }
                ];
              }
            ];
            default = [
              {
                action = "fan.set_preset_mode";
                target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
                data.preset_mode = "Night";
              }
            ];
          }
        ];
        mode = "restart";
      }

      {
        id = "air_purifier_filter_replacement_todoist";
        alias = "Air Purifier - Filter replacement Todoist";
        description = "Create Todoist task when filter needs replacement";
        trigger = [
          {
            platform = "numeric_state";
            entity_id = "sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3";
            below = 20;
          }
          {
            platform = "event";
            event_type = "filter_eof";
            event_data.entity_id = "event.zhimi_de_334622045_mb3_filter_eof_e_9_1";
          }
        ];
        action = [
          {
            action = "todoist.new_task";
            data = {
              content = "Wymień filtr HEPA oczyszczacza powietrza ({{ states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') }}% pozostało)";
              project = "Dom";
              priority = 3;
              due_date_string = "za 2 tygodnie";
              due_date_lang = "pl";
              labels = "dom,konserwacja";
              description = ''Filtr zużyty w {{ 100 - states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') | int }}%.

Link do filtra: https://allegro.pl/xiaomi-air-purifier-3h-filter
Aktualny czas pracy: {{ states('sensor.zhimi_de_334622045_mb3_filter_used_time_p_4_5') }}h'';
            };
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
              media_player_entity_id = "media_player.vlc_telnet";
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
            platform = "time_pattern";
            hours = "3";
            minutes = "0";
          }
        ];
        condition = [
          {
            condition = "time";
            weekday = ["sun"];
          }
          {
            condition = "template";
            value_template = "{{ (now() - as_datetime(states('input_datetime.last_antibacterial_run'))).days >= 7 }}";
          }
        ];
        action = [
          {
            action = "fan.turn_on";
            target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
          }
          {
            action = "fan.set_preset_mode";
            target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
            data.preset_mode = "Auto";
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
            target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
          }
          {
            action = "fan.set_preset_mode";
            target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
            data.preset_mode = "Auto";
          }
        ];
        mode = "single";
      }
    ];

    # ===========================================
    # Template Sensors
    # ===========================================
    template = [
      # -----------------------------------------
      # Air Quality Monitoring
      # -----------------------------------------
      {
        sensor = [
          {
            name = "PM2.5 Outdoor vs Indoor (Living Room)";
            unique_id = "pm25_outdoor_indoor_diff_living_room";
            state = "{{ states('sensor.aleje_pm2_5') | float(999) - states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') | float(50) }}";
            unit_of_measurement = "µg/m³";
          }
          {
            name = "Air Purifier Recommended Mode";
            unique_id = "air_purifier_recommended_mode";
            # Thresholds based on air quality impact:
            # - Indoor < 5 µg/m³: night mode (very clean, quiet operation)
            # - Outdoor > 75 or indoor > 50: auto mode (heavy pollution)
            # - Outdoor > 25 or indoor > 15: auto mode (moderate pollution)
            # WHO guidelines: 0-12 good, 12-35 moderate, 35-55 unhealthy for sensitive groups
            state = ''
              {% set outdoor = states('sensor.aleje_pm2_5') | float(999) %}
              {% set indoor = states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') | float(50) %}
              {% if indoor < 5 %}night
              {% elif outdoor > 75 or indoor > 50 %}auto
              {% elif outdoor > 25 or indoor > 15 %}auto
              {% else %}auto{% endif %}
            '';
          }
          {
            name = "Air Purifier Filter Urgency";
            unique_id = "air_purifier_filter_urgency";
            state = ''
              {% set life = states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') | int(100) %}
              {% if life < 5 %}critical
              {% elif life < 10 %}urgent
              {% elif life < 20 %}soon
              {% else %}normal{% endif %}
            '';
            icon = ''
              {% set urgency = states(this.entity_id) %}
              {% if urgency == 'critical' %}mdi:air-filter-remove
              {% elif urgency == 'urgent' %}mdi:air-filter-alert
              {% elif urgency == 'soon' %}mdi:air-filter
              {% else %}mdi:air-filter{% endif %}
            '';
          }
        ];
        binary_sensor = [
          {
            name = "Safe to Ventilate (Living Room)";
            unique_id = "safe_to_ventilate_living_room";
            # Ventilation considered safe when:
            # - Outdoor PM2.5 < 15 µg/m³ (good/upper-moderate boundary per WHO)
            # - Outdoor air cleaner than indoor air
            # Threshold 15 µg/m³ balances health protection with practical ventilation opportunities
            state = "{{ states('sensor.aleje_pm2_5') | float(999) < 15 and states('sensor.aleje_pm2_5') | float(999) < states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') | float(50) }}";
            device_class = "safety";
          }
          {
            name = "Antibacterial Filter Run Due";
            unique_id = "antibacterial_run_due";
            # Antibacterial filter maintenance recommended every 7 days
            # Tracks time since last high-power run for filter sterilization
            state = "{{ (now() - as_datetime(states('input_datetime.last_antibacterial_run'))).days > 7 }}";
            device_class = "problem";
          }
        ];
      }
    ];

    # ===========================================
    # Input Helpers
    # ===========================================
    input_boolean = {
      away_mode = {
        name = "Tryb poza domem";
        icon = "mdi:home-export-outline";
      };
      guest_mode = {
        name = "Tryb gościa";
        icon = "mdi:account-group";
      };
      sleep_mode = {
        name = "Tryb nocny";
        icon = "mdi:sleep";
      };
      high_pollution_mode = {
        name = "High Pollution Mode";
        icon = "mdi:alert-circle";
      };
    };

    input_datetime = {
      last_antibacterial_run = {
        name = "Last Antibacterial Filter Run";
        has_date = true;
        has_time = true;
      };
    };

    input_number = {
      default_brightness = {
        name = "Domyślna jasność";
        min = 0;
        max = 100;
        step = 5;
        unit_of_measurement = "%";
        icon = "mdi:brightness-6";
      };
    };

    # ===========================================
    # Scripts (callable from automations/voice)
    # ===========================================
    script = {
      all_off = {
        alias = "Wyłącz wszystko";
        sequence = [
          {
            service = "light.turn_off";
            target.entity_id = "all";
          }
          {
            service = "media_player.turn_off";
            target.entity_id = "all";
          }
          {
            service = "fan.turn_off";
            target.entity_id = "all";
          }
        ];
        icon = "mdi:power";
      };
    };
  };
}
