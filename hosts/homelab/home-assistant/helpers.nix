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
  };
}
