{...}: {
  # ===========================================
  # Users & Groups
  # ===========================================

  # Group for shared InfluxDB token access
  users.groups.influxdb-readers = {};

  # User group memberships
  users.users.hass.extraGroups = [
    "dialout" # Serial port access (Zigbee USB)
    "influxdb-readers" # InfluxDB token read access
  ];

  users.users.grafana.extraGroups = [
    "influxdb-readers" # InfluxDB token read access
  ];

  # ESPHome system user (DynamicUser disabled for PlatformIO)
  users.users.esphome = {
    isSystemUser = true;
    group = "esphome";
    extraGroups = ["dialout"]; # Serial port access for USB flashing
  };

  users.groups.esphome = {};
}
