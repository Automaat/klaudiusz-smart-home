{
  config,
  pkgs,
  lib,
  ...
}: {
  services.home-assistant.config = {
    # ===========================================
    # Polish Voice Command Intents
    # ===========================================
    intent_script = {
      # -----------------------------------------
      # Lights
      # -----------------------------------------
      TurnOnLight = {
        speech.text = "Włączam {{ slots.name }}";
        action = [
          {
            service = "light.turn_on";
            target.entity_id = "light.{{ slots.name | lower | replace(' ', '_') }}";
          }
        ];
      };

      TurnOffLight = {
        speech.text = "Wyłączam {{ slots.name }}";
        action = [
          {
            service = "light.turn_off";
            target.entity_id = "light.{{ slots.name | lower | replace(' ', '_') }}";
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

      SetBrightness = {
        speech.text = "Ustawiam jasność {{ slots.name }} na {{ slots.brightness }} procent";
        action = [
          {
            service = "light.turn_on";
            target.entity_id = "light.{{ slots.name | lower | replace(' ', '_') }}";
            data.brightness_pct = "{{ slots.brightness }}";
          }
        ];
      };

      # -----------------------------------------
      # Scenes / Routines
      # -----------------------------------------
      GoodMorning = {
        speech.text = "Dzień dobry! Włączam poranny scenariusz.";
        action = [
          {
            service = "light.turn_on";
            target.entity_id = "light.salon";
            data = {
              brightness_pct = 80;
              color_temp_kelvin = 4000;
            };
          }
          # Add more actions as needed
        ];
      };

      GoodNight = {
        speech.text = "Dobranoc! Wyłączam wszystko.";
        action = [
          {
            service = "light.turn_off";
            target.entity_id = "all";
          }
          {
            service = "cover.close";
            target.entity_id = "all";
          }
          {
            service = "lock.lock";
            target.entity_id = "all";
          }
          {
            service = "media_player.turn_off";
            target.entity_id = "all";
          }
        ];
      };

      LeavingHome = {
        speech.text = "Do zobaczenia! Zabezpieczam dom.";
        action = [
          {
            service = "light.turn_off";
            target.entity_id = "all";
          }
          {
            service = "cover.close";
            target.entity_id = "all";
          }
          {
            service = "lock.lock";
            target.entity_id = "all";
          }
          {
            service = "climate.set_preset_mode";
            target.entity_id = "all";
            data.preset_mode = "away";
          }
        ];
      };

      ComingHome = {
        speech.text = "Witaj w domu!";
        action = [
          {
            service = "light.turn_on";
            target.entity_id = "light.przedpokoj";
          }
          {
            service = "climate.set_preset_mode";
            target.entity_id = "all";
            data.preset_mode = "home";
          }
        ];
      };

      # -----------------------------------------
      # Climate
      # -----------------------------------------
      SetTemperature = {
        speech.text = "Ustawiam temperaturę na {{ slots.temperature }} stopni";
        action = [
          {
            service = "climate.set_temperature";
            target.entity_id = "climate.thermostat";
            data.temperature = "{{ slots.temperature }}";
          }
        ];
      };

      GetTemperature = {
        speech.text = "Temperatura w {{ slots.area }} wynosi {{ states('sensor.temperature_' + slots.area | lower | replace(' ', '_')) }} stopni";
      };

      # -----------------------------------------
      # Covers / Blinds
      # -----------------------------------------
      OpenCover = {
        speech.text = "Otwieram {{ slots.name }}";
        action = [
          {
            service = "cover.open_cover";
            target.entity_id = "cover.{{ slots.name | lower | replace(' ', '_') }}";
          }
        ];
      };

      CloseCover = {
        speech.text = "Zamykam {{ slots.name }}";
        action = [
          {
            service = "cover.close_cover";
            target.entity_id = "cover.{{ slots.name | lower | replace(' ', '_') }}";
          }
        ];
      };

      # -----------------------------------------
      # Media
      # -----------------------------------------
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
      # Scripts
      # -----------------------------------------
      MovieMode = {
        speech.text = "Włączam tryb filmowy";
        action = [
          {
            service = "script.turn_on";
            target.entity_id = "script.movie_mode";
          }
        ];
      };
    };

    # ===========================================
    # Custom Sentences (Polish)
    # ===========================================
    # These define what phrases trigger which intents
    # Place additional sentences in custom_sentences/pl/*.yaml
  };
}
