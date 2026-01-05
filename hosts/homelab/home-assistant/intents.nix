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
      # -----------------------------------------
      AddToShoppingList = {
        speech.text = "Dodaję {{ slots.item }} do listy zakupów";
        action = [
          {
            service = "todo.add_item";
            target.entity_id = "todo.shopping";
            data.item = "{{ slots.item }}";
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
    };

    # ===========================================
    # Custom Sentences (Polish)
    # ===========================================
    # These define what phrases trigger which intents
    # Place additional sentences in custom_sentences/pl/*.yaml
  };
}
