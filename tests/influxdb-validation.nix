{
  lib,
  pkgs,
  nixosConfig,
}: let
  haConfig = nixosConfig.services.home-assistant.config;
  influxdbConfig = nixosConfig.services.influxdb2;
  grafanaConfig = nixosConfig.services.grafana;
  sopsSecrets = nixosConfig.sops.secrets;

  # =============================================
  # InfluxDB Service Validation
  # =============================================

  # Test 1: If HA uses influxdb, service must be enabled
  influxdbServiceEnabled =
    if haConfig ? influxdb
    then
      if !influxdbConfig.enable
      then
        throw ''
          FAIL: HA config has influxdb integration but services.influxdb2.enable = false
          services.home-assistant.config.influxdb is configured
        ''
      else "PASS: InfluxDB service is enabled"
    else "PASS: InfluxDB integration not configured";

  # Test 2: HA influxdb config matches service settings
  influxdbConfigMatches =
    if haConfig ? influxdb && influxdbConfig.enable
    then let
      haInfluxConfig = haConfig.influxdb;
      expectedHost = "localhost";
      expectedPort = 8086;
      expectedOrg = "homeassistant";
      expectedBucket = "home-assistant";
      expectedApiVersion = 2;
    in
      if haInfluxConfig.host or null != expectedHost
      then
        throw ''
          FAIL: InfluxDB host mismatch
          HA config: ${toString (haInfluxConfig.host or "null")}
          Expected: ${expectedHost}
        ''
      else if haInfluxConfig.port or null != expectedPort
      then
        throw ''
          FAIL: InfluxDB port mismatch
          HA config: ${toString (haInfluxConfig.port or "null")}
          Expected: ${toString expectedPort}
        ''
      else if haInfluxConfig.organization or null != expectedOrg
      then
        throw ''
          FAIL: InfluxDB organization mismatch
          HA config: ${haInfluxConfig.organization or "null"}
          Expected: ${expectedOrg}
        ''
      else if haInfluxConfig.bucket or null != expectedBucket
      then
        throw ''
          FAIL: InfluxDB bucket mismatch
          HA config: ${haInfluxConfig.bucket or "null"}
          Expected: ${expectedBucket}
        ''
      else if haInfluxConfig.api_version or null != expectedApiVersion
      then
        throw ''
          FAIL: InfluxDB API version mismatch
          HA config: ${toString (haInfluxConfig.api_version or "null")}
          Expected: ${toString expectedApiVersion}
        ''
      else "PASS: InfluxDB HA config matches service settings"
    else "PASS: InfluxDB integration not configured";

  # Test 3: Grafana has InfluxDB datasource if influxdb is enabled
  grafanaInfluxdbDatasource =
    if influxdbConfig.enable && grafanaConfig.enable
    then let
      datasources = grafanaConfig.provision.datasources.settings.datasources or [];
      influxdbDatasources = builtins.filter (ds: ds.type or null == "influxdb") datasources;
    in
      if builtins.length influxdbDatasources == 0
      then
        throw ''
          FAIL: InfluxDB is enabled but no InfluxDB datasource in Grafana
          services.grafana.provision.datasources.settings.datasources must include influxdb datasource
        ''
      else let
        influxdbDs = builtins.head influxdbDatasources;
      in
        if influxdbDs.url or null != "http://localhost:8086"
        then
          throw ''
            FAIL: Grafana InfluxDB datasource URL mismatch
            Datasource URL: ${influxdbDs.url or "null"}
            Expected: http://localhost:8086
          ''
        else if (influxdbDs.jsonData.organization or null) != "homeassistant"
        then
          throw ''
            FAIL: Grafana InfluxDB datasource organization mismatch
            Datasource org: ${influxdbDs.jsonData.organization or "null"}
            Expected: homeassistant
          ''
        else "PASS: Grafana has valid InfluxDB datasource"
    else "PASS: InfluxDB or Grafana not enabled";

  # Test 4: InfluxDB admin token secret exists
  influxdbSecretExists =
    if influxdbConfig.enable
    then
      if !(sopsSecrets ? "influxdb-admin-token")
      then
        throw ''
          FAIL: InfluxDB is enabled but influxdb-admin-token secret not defined
          sops.secrets."influxdb-admin-token" must be configured
        ''
      else "PASS: InfluxDB admin token secret is configured"
    else "PASS: InfluxDB not enabled";
in {
  # Export test results
  inherit
    influxdbServiceEnabled
    influxdbConfigMatches
    grafanaInfluxdbDatasource
    influxdbSecretExists
    ;

  # Summary test that fails if any check fails
  all = builtins.deepSeq [
    influxdbServiceEnabled
    influxdbConfigMatches
    grafanaInfluxdbDatasource
    influxdbSecretExists
  ] "PASS: All InfluxDB validation tests passed";
}
