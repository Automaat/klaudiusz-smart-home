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
            {{ state_attr('sensor.airly_home_pm2_5', 'mean_24h') | float(0) | round(1) }}
          '';
          unit_of_measurement = "µg/m³";
          device_class = "pm25";
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
          # Ventilation considered safe when:
          # - Outdoor PM2.5 < 15 µg/m³ (good/upper-moderate boundary per WHO)
          # - Outdoor air cleaner than indoor air
          # Threshold 15 µg/m³ balances health protection with practical ventilation opportunities
          state = "{{ states('sensor.airly_home_pm2_5') | float(999) < 15 and states('sensor.airly_home_pm2_5') | float(999) < states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') | float(50) }}";
          device_class = "safety";
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
