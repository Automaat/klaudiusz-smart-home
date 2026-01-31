{
  config,
  pkgs,
  lib,
  ...
}: let
  # Air purifier entity constant
  airPurifier = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
in {
  services.home-assistant.config = {
    # ===========================================
    # Polish Voice Command Intents
    # ===========================================
    intent_script = {
      # -----------------------------------------
      # Lights
      # -----------------------------------------
      TurnOnLight = {
        speech.text = "Włączam {{ slots.get('name', slots.area) }}";
        action = [
          {
            service = "light.turn_on";
            target.area_id = "{{ area_id(slots.get('name', slots.area)) }}";
          }
        ];
      };

      TurnOffLight = {
        speech.text = "Wyłączam {{ slots.get('name', slots.area) }}";
        action = [
          {
            service = "light.turn_off";
            target.area_id = "{{ area_id(slots.get('name', slots.area)) }}";
          }
        ];
      };

      TurnOffAllLights = {
        speech.text = "Wyłączam wszystkie światła";
        action = [
          {
            service = "light.turn_off";
            target.entity_id = "all";
          }
        ];
      };

      TurnOnKitchenLight = {
        speech.text = "Włączam światło w kuchni";
        action = [
          {
            service = "light.turn_on";
            target.entity_id = "light.kitchen";
          }
        ];
      };

      TurnOffKitchenLight = {
        speech.text = "Wyłączam światło w kuchni";
        action = [
          {
            service = "light.turn_off";
            target.entity_id = "light.kitchen";
          }
        ];
      };

      SetBrightness = {
        speech.text = "Ustawiam jasność {{ slots.get('name', slots.area) }} na {{ slots.brightness }} procent";
        action = [
          {
            service = "light.turn_on";
            target.area_id = "{{ area_id(slots.get('name', slots.area)) }}";
            data.brightness_pct = "{{ slots.brightness }}";
          }
        ];
      };

      # -----------------------------------------
      # Scenes
      # -----------------------------------------
      ActivateScene = {
        speech.text = "Włączam scenę {{ slots.name }}";
        action = [
          {
            service = "scene.turn_on";
            target.entity_id = "scene.{{ slots.name | lower | replace(' ', '_') }}";
          }
        ];
      };

      # -----------------------------------------
      # Climate (Placeholder - configure after device setup)
      # -----------------------------------------
      # SetTemperature = {
      #   speech.text = "Ustawiam temperaturę na {{ slots.temperature }} stopni";
      #   action = [
      #     {
      #       service = "climate.set_temperature";
      #       target.entity_id = "climate.your_thermostat_here";
      #       data.temperature = "{{ slots.temperature }}";
      #     }
      #   ];
      # };
      #
      # GetTemperature = {
      #   speech.text = "Temperatura w {{ slots.area }} wynosi {{ states('sensor.temperature_' + slots.area | lower | replace(' ', '_')) }} stopni";
      # };

      # -----------------------------------------
      # Covers / Blinds
      # -----------------------------------------
      OpenCover = {
        speech.text = "Otwieram {{ slots.get('name', slots.area) }}";
        action = [
          {
            service = "cover.open_cover";
            target.area_id = "{{ area_id(slots.get('name', slots.area)) }}";
          }
        ];
      };

      CloseCover = {
        speech.text = "Zamykam {{ slots.get('name', slots.area) }}";
        action = [
          {
            service = "cover.close_cover";
            target.area_id = "{{ area_id(slots.get('name', slots.area)) }}";
          }
        ];
      };

      # -----------------------------------------
      # Media
      # -----------------------------------------
      TurnOnMedia = {
        speech.text = "Włączam {{ slots.get('name', slots.area) }}";
        action = [
          {
            service = "media_player.turn_on";
            target.area_id = "{{ area_id(slots.get('name', slots.area)) }}";
          }
        ];
      };

      TurnOffMedia = {
        speech.text = "Wyłączam {{ slots.get('name', slots.area) }}";
        action = [
          {
            service = "media_player.turn_off";
            target.area_id = "{{ area_id(slots.get('name', slots.area)) }}";
          }
        ];
      };

      PauseMedia = {
        speech.text = "Pauzuję";
        action = [
          {
            service = "media_player.media_pause";
            target.entity_id = "all";
          }
        ];
      };

      PlayMedia = {
        speech.text = "Wznawiam";
        action = [
          {
            service = "media_player.media_play";
            target.entity_id = "all";
          }
        ];
      };

      # -----------------------------------------
      # Info / Status
      # -----------------------------------------
      WhatTime = {
        speech.text = "Jest godzina {{ now().strftime('%H:%M') }}";
      };

      WhatDate = {
        speech.text = "Dzisiaj jest {{ now().strftime('%A, %d %B %Y') }}";
      };

      # -----------------------------------------
      # Shopping List (Todoist)
      # Override built-in HassShoppingListAddItem to use Todoist
      # -----------------------------------------
      HassShoppingListAddItem = {
        speech.text = "Dodaję {{ item }} do listy zakupów";
        action = [
          {
            service = "todo.add_item";
            target.entity_id = "todo.shopping";
            data.item = "{{ item }}";
          }
        ];
      };

      # -----------------------------------------
      # Air Purifier
      # -----------------------------------------
      TurnOnAirPurifier = {
        speech.text = "Włączam oczyszczacz powietrza w salonie";
        action = [
          {
            action = "fan.turn_on";
            target.entity_id = airPurifier;
          }
        ];
      };

      TurnOffAirPurifier = {
        speech.text = "Wyłączam oczyszczacz powietrza";
        action = [
          {
            action = "fan.turn_off";
            target.entity_id = airPurifier;
          }
        ];
      };

      SetAirPurifierNight = {
        speech.text = "Ustawiam oczyszczacz w tryb nocny";
        action = [
          {
            action = "fan.set_preset_mode";
            target.entity_id = airPurifier;
            data.preset_mode = "Night";
          }
        ];
      };

      SetAirPurifierAuto = {
        speech.text = "Ustawiam oczyszczacz w tryb automatyczny";
        action = [
          {
            action = "fan.set_preset_mode";
            target.entity_id = airPurifier;
            data.preset_mode = "Auto";
          }
        ];
      };

      GetAirQuality = {
        speech.text = ''
          Jakość powietrza w salonie: wewnątrz {{ states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') }} mikrogramów PM2.5,
          na zewnątrz {{ states('sensor.airly_home_pm2_5') }} mikrogramów.
          {{ 'Możesz otworzyć okno.' if is_state('binary_sensor.safe_to_ventilate_living_room', 'on') else 'Lepiej zostaw okna zamknięte.' }}
        '';
      };

      GetFilterStatus = {
        speech.text = "Filtr oczyszczacza zużyty w {{ 100 - states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') | int }} procentach. Pozostało {{ states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') }} procent żywotności.";
      };

      TriggerAntibacterial = {
        speech.text = "Uruchamiam tryb antybakteryjny oczyszczacza na 2 godziny";
        action = [
          {
            action = "fan.turn_on";
            target.entity_id = airPurifier;
          }
          {
            action = "fan.set_preset_mode";
            target.entity_id = airPurifier;
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
      };

      # -----------------------------------------
      # Scripts (Placeholder - no devices yet)
      # -----------------------------------------
      # MovieMode = {
      #   speech.text = "Włączam tryb filmowy";
      #   action = [];
      # };

      # -----------------------------------------
      # Claude AI Brain
      # -----------------------------------------
      AskClaude = {
        action = [
          {
            action = "claude_brain.ask";
            data.query = "{{ query }}";
          }
          {delay.seconds = 3;}
        ];
        speech.text = "{{ states('input_text.claude_response') }}";
      };

      ConfirmClaude = {
        action = [
          {
            condition = "state";
            entity_id = "input_boolean.claude_awaiting_confirmation";
            state = "on";
          }
          {
            action = "claude_brain.confirm";
          }
          {delay.seconds = 2;}
        ];
        speech.text = "{{ states('input_text.claude_response') }}";
      };

      CancelClaude = {
        action = [
          {
            condition = "state";
            entity_id = "input_boolean.claude_awaiting_confirmation";
            state = "on";
          }
          {
            action = "claude_brain.cancel";
          }
          {delay.seconds = 1;}
        ];
        speech.text = "{{ states('input_text.claude_response') }}";
      };
    };

    # ===========================================
    # Custom Sentences (Polish)
    # ===========================================
    # These define what phrases trigger which intents
    # Place additional sentences in custom_sentences/pl/*.yaml
  };
}
