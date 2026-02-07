{
  config,
  pkgs,
  lib,
  ...
}: {
  # ===========================================
  # Template Sensors
  # ===========================================
  template = [
    # -----------------------------------------
    # Debugging
    # -----------------------------------------
    {
      sensor = [
        {
          name = "Hallway Zone 2 Debug State";
          unique_id = "hallway_zone_2_debug_state";
          state = ''
            {% set p = states('binary_sensor.presence_sensor_fp2_fac2_presence_sensor_2') %}
            {% set l1 = states('light.hue_essential_spot_3_2') %}
            {% set l2 = states('light.hue_essential_spot_5') %}
            {% set sleep = states('input_boolean.sleep_mode') %}
            {% set al = states('switch.adaptive_lighting_hallway_lights') %}
            {% set al_sleep = states('switch.adaptive_lighting_sleep_mode_hallway_lights') %}
            {{ p }}/{{ l1 }}/{{ l2 }}/sl:{{ sleep }}/al:{{ al }}/als:{{ al_sleep }}
          '';
          attributes = {
            presence = "{{ states('binary_sensor.presence_sensor_fp2_fac2_presence_sensor_2') }}";
            light_h1 = "{{ states('light.hue_essential_spot_3_2') }}";
            light_h2 = "{{ states('light.hue_essential_spot_5') }}";
            brightness_h1 = "{{ state_attr('light.hue_essential_spot_3_2', 'brightness') }}";
            brightness_h2 = "{{ state_attr('light.hue_essential_spot_5', 'brightness') }}";
            sleep_mode = "{{ states('input_boolean.sleep_mode') }}";
            adaptive_lighting = "{{ states('switch.adaptive_lighting_hallway_lights') }}";
            adaptive_lighting_sleep = "{{ states('switch.adaptive_lighting_sleep_mode_hallway_lights') }}";
          };
        }
      ];
    }

    # -----------------------------------------
    # Temperature Monitoring
    # -----------------------------------------
    {
      sensor = [
        {
          name = "Average Home Temperature";
          unique_id = "average_home_temperature";
          state = ''
            {% set temps = [
              state_attr('climate.livingroom_thermostat', 'current_temperature') | float(0),
              state_attr('climate.bedroom_thermostat', 'current_temperature') | float(0),
              state_attr('climate.bathroom_thermostat', 'current_temperature') | float(0)
            ] %}
            {{ ((temps | sum) / (temps | length)) | round(1) }}
          '';
          unit_of_measurement = "°C";
          device_class = "temperature";
        }
        {
          name = "Max Home Temperature";
          unique_id = "max_home_temperature";
          state = ''
            {% set temps = [
              state_attr('climate.livingroom_thermostat', 'current_temperature') | float(0),
              state_attr('climate.bedroom_thermostat', 'current_temperature') | float(0),
              state_attr('climate.bathroom_thermostat', 'current_temperature') | float(0)
            ] %}
            {{ temps | max | round(1) }}
          '';
          unit_of_measurement = "°C";
          device_class = "temperature";
        }
        {
          name = "Min Home Temperature";
          unique_id = "min_home_temperature";
          state = ''
            {% set temps = [
              state_attr('climate.livingroom_thermostat', 'current_temperature') | float(0),
              state_attr('climate.bedroom_thermostat', 'current_temperature') | float(0),
              state_attr('climate.bathroom_thermostat', 'current_temperature') | float(0)
            ] %}
            {{ temps | min | round(1) }}
          '';
          unit_of_measurement = "°C";
          device_class = "temperature";
        }
        {
          name = "PM2.5 24h Average";
          unique_id = "pm25_24h_average";
          state = ''
            {% set mean = state_attr('sensor.airly_home_pm2_5', 'mean_24h') %}
            {% if mean is not none %}
              {{ mean | float | round(1) }}
            {% else %}
              {{ states('sensor.airly_home_pm2_5') | float(0) | round(1) }}
            {% endif %}
          '';
          unit_of_measurement = "µg/m³";
          device_class = "pm25";
        }
      ];
    }

    # -----------------------------------------
    # Person Location Tracking (Bermuda BLE + mmWave)
    # -----------------------------------------
    # NOTE: Update entity IDs after Bermuda GUI configuration
    # Bermuda device_tracker entity names discovered after setup
    {
      trigger = [
        # { platform = "state"; entity_id = "sensor.bermuda_marcin_iphone_area"; }
        { platform = "state"; entity_id = "binary_sensor.presence_sensor_presence"; }
        { platform = "state"; entity_id = "binary_sensor.presence_sensor_fp2_b63f_presence_sensor_2"; }
      ];
      sensor = [
        {
          name = "Marcin Current Room";
          unique_id = "marcin_current_room";
          state = ''
            {% set bathroom_mmwave = is_state('binary_sensor.presence_sensor_presence', 'on') %}
            {% set kitchen_mmwave = is_state('binary_sensor.presence_sensor_fp2_b63f_presence_sensor_2', 'on') %}
            {% if bathroom_mmwave %}bathroom
            {% elif kitchen_mmwave %}kitchen
            {% else %}{{ states('sensor.marcin_current_room') }}{% endif %}
          '';
          attributes = {
            confidence = "{{ 'high' if bathroom_mmwave or kitchen_mmwave else 'low' }}";
            source = "{{ 'mmwave' if bathroom_mmwave or kitchen_mmwave else 'last_known' }}";
          };
        }
        {
          name = "Ewa Current Room";
          unique_id = "ewa_current_room";
          state = ''
            {% set bathroom_mmwave = is_state('binary_sensor.presence_sensor_presence', 'on') %}
            {% set kitchen_mmwave = is_state('binary_sensor.presence_sensor_fp2_b63f_presence_sensor_2', 'on') %}
            {% if bathroom_mmwave %}bathroom
            {% elif kitchen_mmwave %}kitchen
            {% else %}{{ states('sensor.ewa_current_room') }}{% endif %}
          '';
          attributes = {
            confidence = "{{ 'high' if bathroom_mmwave or kitchen_mmwave else 'low' }}";
            source = "{{ 'mmwave' if bathroom_mmwave or kitchen_mmwave else 'last_known' }}";
          };
        }
      ];
    }

    # Anyone home status (updated after person entities created)
    {
      sensor = [
        {
          name = "Anyone Home";
          unique_id = "anyone_home";
          state = "unknown";
          # Update after person.marcin and person.ewa created:
          # state = "{{ is_state('person.marcin', 'home') or is_state('person.ewa', 'home') }}";
        }
      ];
      binary_sensor = [
        {
          name = "Anyone Home";
          unique_id = "anyone_home_binary";
          state = "off";
          # Update after person.marcin and person.ewa created:
          # state = "{{ is_state('person.marcin', 'home') or is_state('person.ewa', 'home') }}";
        }
      ];
    }

    # -----------------------------------------
    # Person Preferences - Active
    # -----------------------------------------
    {
      sensor = [
        {
          name = "Active Brightness Preference Bathroom";
          unique_id = "active_brightness_pref_bathroom";
          state = ''
            {% set marcin_here = is_state('sensor.marcin_current_room', 'bathroom') %}
            {% set ewa_here = is_state('sensor.ewa_current_room', 'bathroom') %}
            {% if marcin_here and ewa_here %}
              {{ [states('input_number.marcin_brightness_preference'), states('input_number.ewa_brightness_preference')] | map('float') | average | round(0) }}
            {% elif marcin_here %}{{ states('input_number.marcin_brightness_preference') }}
            {% elif ewa_here %}{{ states('input_number.ewa_brightness_preference') }}
            {% else %}{{ states('input_number.default_brightness') }}{% endif %}
          '';
          unit_of_measurement = "%";
        }
        {
          name = "Active Brightness Preference Kitchen";
          unique_id = "active_brightness_pref_kitchen";
          state = ''
            {% set marcin_here = is_state('sensor.marcin_current_room', 'kitchen') %}
            {% set ewa_here = is_state('sensor.ewa_current_room', 'kitchen') %}
            {% if marcin_here and ewa_here %}
              {{ [states('input_number.marcin_brightness_preference'), states('input_number.ewa_brightness_preference')] | map('float') | average | round(0) }}
            {% elif marcin_here %}{{ states('input_number.marcin_brightness_preference') }}
            {% elif ewa_here %}{{ states('input_number.ewa_brightness_preference') }}
            {% else %}{{ states('input_number.default_brightness') }}{% endif %}
          '';
          unit_of_measurement = "%";
        }
      ];
    }

    # -----------------------------------------
    # Air Quality Monitoring
    # -----------------------------------------
    {
      sensor = [
        {
          name = "PM2.5 Outdoor vs Indoor (Living Room)";
          unique_id = "pm25_outdoor_indoor_diff_living_room";
          state = "{{ states('sensor.airly_home_pm2_5') | float(999) - states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') | float(50) }}";
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
            {% set outdoor = states('sensor.airly_home_pm2_5') | float(999) %}
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
          # Ventilation considered safe when outdoor PM2.5 < 15 µg/m³
          # (good/upper-moderate boundary per WHO guidelines)
          # Based solely on Airly outdoor sensor for simplicity
          # No device_class to avoid confusing "Safe"/"Clear" labels in history
          state = "{{ states('sensor.airly_home_pm2_5') | float(999) < 15 }}";
        }
        {
          name = "Antibacterial Filter Run Due";
          unique_id = "antibacterial_run_due";
          # Antibacterial filter maintenance recommended every 7 days
          # Tracks time since last high-power run for filter sterilization
          state = "{{ (now() - as_local(as_datetime(states('input_datetime.last_antibacterial_run')))).days > 7 }}";
          device_class = "problem";
        }
      ];
    }
  ];
}
