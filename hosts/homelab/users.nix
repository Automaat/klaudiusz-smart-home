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
}
