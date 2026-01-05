{...}: {
  services.home-assistant = {
    # Add rest component for RESTful integrations
    extraComponents = [
      "rest"
      "command_line"
    ];

    config = {
      # ===========================================
      # Fellow Stagg EKG Pro Kettle
      # ===========================================
      # HTTP API: http://192.168.0.47/cli?cmd={state,heaton,heatoff}
      # Response format: key=value text (not JSON)
      #   mode=S_Off / S_On
      #   tempr=23.201085 C

      # Command line sensors for kettle state
      # Uses curl + grep to parse text response
      command_line = [
        {
          sensor = [
            {
              name = "Czajnik Temperatura";
              unique_id = "fellow_kettle_temperature";
              command = "curl -s --max-time 5 'http://192.168.0.47/cli?cmd=state' | grep 'tempr=' | cut -d= -f2 | cut -d' ' -f1";
              unit_of_measurement = "°C";
              device_class = "temperature";
              scan_interval = 30;
            }
            {
              name = "Czajnik Stan";
              unique_id = "fellow_kettle_mode";
              command = "curl -s --max-time 5 'http://192.168.0.47/cli?cmd=state' | grep 'mode=' | cut -d= -f2";
              scan_interval = 30;
            }
          ];
        }
      ];

      # REST commands for kettle control
      rest_command = {
        kettle_heaton = {
          url = "http://192.168.0.47/cli?cmd=heaton";
          method = "get";
          timeout = 5;
        };
        kettle_heatoff = {
          url = "http://192.168.0.47/cli?cmd=heatoff";
          method = "get";
          timeout = 5;
        };
      };

      # Template switch combining REST commands + sensor state
      # Modern template syntax (2026.6+)
      template = [
        {
          switch = [
            {
              name = "Czajnik";
              unique_id = "fellow_kettle_switch";
              # Check actual heating mode from API
              state = "{{ states('sensor.czajnik_stan') == 'S_On' }}";
              turn_on = [
                {action = "rest_command.kettle_heaton";}
              ];
              turn_off = [
                {action = "rest_command.kettle_heatoff";}
              ];
            }
          ];
        }
      ];
    };
  };
}
