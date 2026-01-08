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
  ];
}
