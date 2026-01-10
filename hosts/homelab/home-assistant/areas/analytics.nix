{
  config,
  pkgs,
  lib,
  ...
}: {
  # ===========================================
  # Analytics & Efficiency Alerting
  # ===========================================
  # Phase 2: Real-time waste detection and alerting
  automation = [
    # -------------------------------------------
    # Light Waste Detection - Kitchen
    # -------------------------------------------
    {
      id = "analytics_kitchen_light_waste_alert";
      alias = "Analytics - Kitchen Light Waste Alert";
      description = "Alert when kitchen lights left on with room vacant >30min";

      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_kitchen";
          to = "off";
          "for" = {
            minutes = 30;
          };
        }
      ];

      condition = [
        {
          condition = "state";
          entity_id = "light.kitchen";
          state = "on";
        }
      ];

      action = [
        {
          action = "notify.telegram";
          data = {
            message = "⚡ Oszczędność: Światło w kuchni pali się od 30 min w pustym pomieszczeniu";
            title = "Light Waste Alert";
          };
        }
      ];

      mode = "single";
    }

    # -------------------------------------------
    # Climate Waste Detection - Living Room
    # -------------------------------------------
    {
      id = "analytics_livingroom_heating_waste_alert";
      alias = "Analytics - Living Room Heating Waste Alert";
      description = "Alert when living room heated while vacant >1h";

      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_livingroom";
          to = "off";
          "for" = {
            hours = 1;
          };
        }
      ];

      condition = [
        # Check if room is being heated (temp > 20°C)
        {
          condition = "numeric_state";
          entity_id = "climate.livingroom_thermostat";
          attribute = "current_temperature";
          above = 20;
        }
      ];

      action = [
        {
          action = "notify.telegram";
          data = {
            message = ''
              🔥 Oszczędność: Salon jest ogrzewany od >1h bez obecności
              Temperatura: {{ state_attr('climate.livingroom_thermostat', 'current_temperature') }}°C
            '';
            title = "Heating Waste Alert";
          };
        }
      ];

      mode = "single";
    }

    # -------------------------------------------
    # Daily Efficiency Summary
    # -------------------------------------------
    {
      id = "analytics_daily_efficiency_summary";
      alias = "Analytics - Daily Efficiency Summary";
      description = "Send daily summary of efficiency metrics at 10pm";

      trigger = [
        {
          platform = "time";
          at = "22:00:00";
        }
      ];

      action = [
        {
          action = "notify.telegram";
          data = {
            message = ''
              📊 Dzienne podsumowanie efektywności

              🏠 Salon:
              Obecność dzisiaj: {{ relative_time(states.binary_sensor.presence_livingroom.last_changed) }}
              Temperatura: {{ state_attr('climate.livingroom_thermostat', 'current_temperature') }}°C

              🍳 Kuchnia:
              Obecność dzisiaj: {{ relative_time(states.binary_sensor.presence_kitchen.last_changed) }}
              Światło: {{ states('light.kitchen') }}

              💡 Sprawdź szczegóły w Grafana:
              - Lighting Efficiency dashboard
              - Climate Efficiency dashboard
            '';
            title = "Daily Efficiency Report";
          };
        }
      ];

      mode = "single";
    }

    # -------------------------------------------
    # Vacant Room Auto-Shutoff - Kitchen Lights
    # -------------------------------------------
    {
      id = "analytics_kitchen_auto_shutoff";
      alias = "Analytics - Kitchen Auto Shutoff";
      description = "Auto turn off kitchen lights after 45min vacant (learning mode)";

      trigger = [
        {
          platform = "state";
          entity_id = "binary_sensor.presence_kitchen";
          to = "off";
          "for" = {
            minutes = 45;
          };
        }
      ];

      condition = [
        {
          condition = "state";
          entity_id = "light.kitchen";
          state = "on";
        }
        # Only during night hours when it's more likely forgotten
        {
          condition = "time";
          after = "22:00:00";
          before = "06:00:00";
        }
      ];

      action = [
        {
          action = "notify.telegram";
          data = {
            message = "💡 Automatyczne wyłączenie: światło w kuchni było zapalone 45 min w pustym pomieszczeniu";
            title = "Auto Shutoff";
          };
        }
        {
          action = "light.turn_off";
          target = {
            entity_id = "light.kitchen";
          };
        }
      ];

      mode = "single";
    }
  ];
}
