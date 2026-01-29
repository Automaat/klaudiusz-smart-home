{
  config,
  pkgs,
  lib,
  ...
}: {
  # ===========================================
  # Office Automations
  # ===========================================
  automation = [
    # -----------------------------------------
    # Zoom Meeting Smart Plug Control
    # -----------------------------------------
    {
      id = "zoom_meeting_smart_plug";
      alias = "Office - Zoom meeting smart plug control";
      description = "Turn on/off office smart plug based on Zoom meeting state via webhook";
      mode = "restart"; # Debounce: restart automation if webhook fires during delay
      trigger = [
        {
          platform = "webhook";
          webhook_id = "zoom_meeting_7cca0951_0a49_4bdc_a8d3_cc46ea7d8980";
          allowed_methods = ["POST"];
          local_only = true;
        }
      ];
      action = [
        {
          delay = "00:00:05"; # Wait 5s - cancelled if new webhook arrives
        }
        {
          choose = [
            # Meeting started → turn on
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.json.state == 'started' }}";
                }
              ];
              sequence = [
                {
                  action = "switch.turn_on";
                  target.entity_id = "switch.sonoff_plug";
                }
              ];
            }
            # Meeting ended → turn off
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.json.state == 'ended' }}";
                }
              ];
              sequence = [
                {
                  action = "switch.turn_off";
                  target.entity_id = "switch.sonoff_plug";
                }
              ];
            }
          ];
          default = [
            {
              action = "logbook.log";
              data = {
                name = "Office - Zoom webhook invalid state";
                message = "Received unexpected Zoom webhook payload: {{ trigger.json | tojson }}";
              };
            }
          ];
        }
      ];
    }

    # -----------------------------------------
    # Desk Charger Battery Control
    # -----------------------------------------
    {
      id = "desk_charger_battery_control";
      alias = "Office - Desk charger battery control";
      description = "Control desk charger based on iPhone and AirPods case battery levels";
      trigger = [
        {
          platform = "webhook";
          webhook_id = "desk_charger_battery_a8f3c901_4d2a_4b18_9f7e_8d3c4e7a6b12";
          allowed_methods = ["POST"];
          local_only = true;
        }
      ];
      action = [
        {
          choose = [
            # Start charging: iPhone < 50% OR AirPods case < 20%
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.json.iphone_battery is defined and trigger.json.airpods_battery is defined and trigger.json.iphone_battery is number and trigger.json.airpods_battery is number }}";
                }
                {
                  condition = "template";
                  value_template = "{{ trigger.json.iphone_battery < 50 or trigger.json.airpods_battery < 20 }}";
                }
              ];
              sequence = [
                {
                  action = "switch.turn_on";
                  target.entity_id = "switch.sonoff_plug_3";
                }
                {
                  action = "logbook.log";
                  data = {
                    name = "Office - Desk charger ON";
                    message = "Started charging: iPhone {{ trigger.json.iphone_battery }}%, AirPods case {{ trigger.json.airpods_battery }}%";
                  };
                }
              ];
            }
            # Stop charging: BOTH iPhone >= 80% AND AirPods case >= 80%
            {
              conditions = [
                {
                  condition = "template";
                  value_template = "{{ trigger.json.iphone_battery is defined and trigger.json.airpods_battery is defined and trigger.json.iphone_battery is number and trigger.json.airpods_battery is number }}";
                }
                {
                  condition = "template";
                  value_template = "{{ trigger.json.iphone_battery >= 80 and trigger.json.airpods_battery >= 80 }}";
                }
              ];
              sequence = [
                {
                  action = "switch.turn_off";
                  target.entity_id = "switch.sonoff_plug_3";
                }
                {
                  action = "logbook.log";
                  data = {
                    name = "Office - Desk charger OFF";
                    message = "Stopped charging: iPhone {{ trigger.json.iphone_battery }}%, AirPods case {{ trigger.json.airpods_battery }}%";
                  };
                }
              ];
            }
          ];
          default = [
            {
              action = "logbook.log";
              data = {
                name = "Office - Desk charger webhook";
                message = ''
                  {% if trigger.json.iphone_battery is not defined or trigger.json.airpods_battery is not defined or trigger.json.iphone_battery is not number or trigger.json.airpods_battery is not number %}
                  Invalid payload: missing or non-numeric battery fields - {{ trigger.json | tojson }}
                  {% else %}
                  Battery levels in hysteresis zone: iPhone {{ trigger.json.iphone_battery }}%, AirPods case {{ trigger.json.airpods_battery }}%
                  {% endif %}
                '';
              };
            }
          ];
        }
      ];
    }
  ];
}
