{
  config,
  pkgs,
  lib,
  ...
}: {
  # ===========================================
  # Input Helpers
  # ===========================================
  input_boolean = {
    away_mode = {
      name = "Tryb poza domem";
      icon = "mdi:home-export-outline";
      initial = false;
    };
    guest_mode = {
      name = "Tryb gościa";
      icon = "mdi:account-group";
    };
    sleep_mode = {
      name = "Tryb nocny";
      icon = "mdi:sleep";
    };
    high_pollution_mode = {
      name = "High Pollution Mode";
      icon = "mdi:alert-circle";
    };
  };

  input_datetime = {
    last_antibacterial_run = {
      name = "Last Antibacterial Filter Run";
      has_date = true;
      has_time = true;
    };
    last_filter_task_living_room = {
      name = "Last Filter Task - Living Room";
      has_date = true;
      has_time = true;
    };
  };

  input_number = {
    default_brightness = {
      name = "Domyślna jasność";
      min = 0;
      max = 100;
      step = 5;
      unit_of_measurement = "%";
      icon = "mdi:brightness-6";
    };

    # Person preferences - Marcin
    marcin_brightness_preference = {
      name = "Jasność - Marcin";
      min = 0;
      max = 100;
      step = 5;
      unit_of_measurement = "%";
      initial = 75;
      icon = "mdi:brightness-6";
    };
    marcin_temp_preference_salon = {
      name = "Temperatura salon - Marcin";
      min = 18;
      max = 24;
      step = 0.5;
      unit_of_measurement = "°C";
      initial = 21;
      icon = "mdi:thermometer";
    };

    # Person preferences - Ewa
    ewa_brightness_preference = {
      name = "Jasność - Ewa";
      min = 0;
      max = 100;
      step = 5;
      unit_of_measurement = "%";
      initial = 60;
      icon = "mdi:brightness-6";
    };
    ewa_temp_preference_salon = {
      name = "Temperatura salon - Ewa";
      min = 18;
      max = 24;
      step = 0.5;
      unit_of_measurement = "°C";
      initial = 20;
      icon = "mdi:thermometer";
    };
  };
}
