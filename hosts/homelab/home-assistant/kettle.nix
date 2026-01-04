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

      # Command line sensor for kettle temperature
      # Uses curl + grep to parse text response
      sensor = [
        {
          platform = "command_line";
          name = "Czajnik Temperatura";
          unique_id = "fellow_kettle_temperature";
          command = "curl -s 'http://192.168.0.47/cli?cmd=state' | grep 'tempr=' | cut -d= -f2 | cut -d' ' -f1";
          unit_of_measurement = "°C";
          device_class = "temperature";
          scan_interval = 30;
        }
      ];

      # REST commands for kettle control
      rest_command = {
        kettle_heaton = {
          url = "http://192.168.0.47/cli?cmd=heaton";
          method = "get";
        };
        kettle_heatoff = {
          url = "http://192.168.0.47/cli?cmd=heatoff";
          method = "get";
        };
      };

      # Template switch combining REST commands + sensor state
      switch = [
        {
          platform = "template";
          switches = {
            czajnik = {
              friendly_name = "Czajnik";
              unique_id = "fellow_kettle_switch";
              # Check if temperature is rising (heating)
              # Note: Imperfect - kettle doesn't expose actual heating state via API
              value_template = "{{ states('sensor.czajnik_temperatura')|float(0) > 25 }}";
              turn_on = {
                service = "rest_command.kettle_heaton";
              };
              turn_off = {
                service = "rest_command.kettle_heatoff";
              };
            };
          };
        }
      ];
    };
  };
}
