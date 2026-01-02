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
        speech.text = "Włączam {{ slots.name if slots.name is defined else slots.area }}";
        action = [
          {
            service = "light.turn_on";
            target.entity_id = "light.{{ (slots.name if slots.name is defined else slots.area) | lower | replace(' ', '_') }}";
          }
        ];
      };

      TurnOffLight = {
        speech.text = "Wyłączam {{ slots.name if slots.name is defined else slots.area }}";
        action = [
          {
            service = "light.turn_off";
            target.entity_id = "light.{{ (slots.name if slots.name is defined else slots.area) | lower | replace(' ', '_') }}";
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
        speech.text = "Ustawiam jasność {{ slots.name if slots.name is defined else slots.area }} na {{ slots.brightness }} procent";
        action = [
          {
            service = "light.turn_on";
            target.entity_id = "light.{{ (slots.name if slots.name is defined else slots.area) | lower | replace(' ', '_') }}";
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
        speech.text = "Otwieram {{ slots.name if slots.name is defined else slots.area }}";
        action = [
          {
            service = "cover.open_cover";
            target.entity_id = "cover.{{ (slots.name if slots.name is defined else slots.area) | lower | replace(' ', '_') }}";
          }
        ];
      };

      CloseCover = {
        speech.text = "Zamykam {{ slots.name if slots.name is defined else slots.area }}";
        action = [
          {
            service = "cover.close_cover";
            target.entity_id = "cover.{{ (slots.name if slots.name is defined else slots.area) | lower | replace(' ', '_') }}";
          }
        ];
      };

      # -----------------------------------------
      # Media
      # -----------------------------------------
      TurnOnMedia = {
        speech.text = "Włączam {{ slots.name if slots.name is defined else slots.area }}";
        action = [
          {
            service = "media_player.turn_on";
            target.entity_id = "media_player.{{ (slots.name if slots.name is defined else slots.area) | lower | replace(' ', '_') }}";
          }
        ];
      };

      TurnOffMedia = {
        speech.text = "Wyłączam {{ slots.name if slots.name is defined else slots.area }}";
        action = [
          {
            service = "media_player.turn_off";
            target.entity_id = "media_player.{{ (slots.name if slots.name is defined else slots.area) | lower | replace(' ', '_') }}";
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
      # Scripts (Placeholder - no devices yet)
      # -----------------------------------------
      # MovieMode = {
      #   speech.text = "Włączam tryb filmowy";
      #   action = [];
      # };
    };

    # ===========================================
    # Custom Sentences (Polish)
    # ===========================================
    # These define what phrases trigger which intents
    # Place additional sentences in custom_sentences/pl/*.yaml
  };
}
