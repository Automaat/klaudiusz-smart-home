{
  lib,
  pkgs,
  nixosConfig,
}: let
  haConfig = nixosConfig.services.home-assistant.config;
  postgresConfig = nixosConfig.services.postgresql;
  haServiceConfig = nixosConfig.systemd.services.home-assistant.serviceConfig;
  prometheusConfig = nixosConfig.services.prometheus;
  grafanaConfig = nixosConfig.services.grafana;

  # =============================================
  # PostgreSQL Recorder Validation
  # =============================================

  # Extract database name from recorder.db_url
  # Format: postgresql://@/dbname or postgresql://user:pass@host/dbname
  extractDbName = url: let
    # Remove postgresql:// prefix
    withoutScheme = lib.removePrefix "postgresql://" url;
    # Split by / and take last part (database name)
    parts = lib.splitString "/" withoutScheme;
  in
    lib.last parts;

  # Extract username from recorder.db_url
  # Format: postgresql://@/dbname (socket, no user) or postgresql://user@host/dbname
  extractDbUser = url:
    if url == null
    then null
    else let
      withoutScheme = lib.removePrefix "postgresql://" url;
    in
      # If starts with @, it's socket auth (use service user)
      if lib.hasPrefix "@" withoutScheme
      then "hass" # Assumes service runs as hass user
      else let
        # Split by @ to get user part
        userPart = lib.head (lib.splitString "@" withoutScheme);
        # Remove password if present (user:pass)
        userName = lib.head (lib.splitString ":" userPart);
      in
        userName;

  recorderDbUrl = haConfig.recorder.db_url or null;
  recorderDbName =
    if recorderDbUrl != null
    then extractDbName recorderDbUrl
    else null;
  recorderDbUser =
    if recorderDbUrl != null
    then extractDbUser recorderDbUrl
    else null;

  # Test 1: If recorder uses PostgreSQL, service must be enabled
  postgresqlServiceEnabled =
    if recorderDbUrl != null && lib.hasPrefix "postgresql://" recorderDbUrl
    then
      if !postgresConfig.enable
      then
        throw ''
          FAIL: Recorder uses PostgreSQL but services.postgresql.enable = false
          recorder.db_url = ${recorderDbUrl}
        ''
      else "PASS: PostgreSQL service is enabled for recorder"
    else "PASS: Recorder not using PostgreSQL or not configured";

  # Test 2: Database name in ensureDatabases must match recorder.db_url
  databaseNameMatches =
    if recorderDbName != null && postgresConfig.enable
    then
      if !builtins.elem recorderDbName postgresConfig.ensureDatabases
      then
        throw ''
          FAIL: Database name mismatch
          recorder.db_url expects: ${recorderDbName}
          services.postgresql.ensureDatabases: ${lib.concatStringsSep ", " postgresConfig.ensureDatabases}
        ''
      else "PASS: Database name matches between recorder and PostgreSQL config"
    else "PASS: PostgreSQL not configured or recorder not using it";

  # Test 3: User must exist in ensureUsers
  databaseUserExists =
    if recorderDbUser != null && postgresConfig.enable
    then let
      ensuredUserNames = builtins.map (u: u.name) postgresConfig.ensureUsers;
    in
      if !builtins.elem recorderDbUser ensuredUserNames
      then
        throw ''
          FAIL: Database user not found
          recorder.db_url expects user: ${recorderDbUser}
          services.postgresql.ensureUsers: ${lib.concatStringsSep ", " ensuredUserNames}
        ''
      else "PASS: Database user exists in PostgreSQL config"
    else "PASS: PostgreSQL not configured or recorder not using it";

  # Test 4: If using socket auth (@/dbname), home-assistant must have postgres supplementary group
  socketAuthConfigured =
    if recorderDbUrl != null && lib.hasInfix "@/" recorderDbUrl && postgresConfig.enable
    then
      if !(haServiceConfig ? SupplementaryGroups && builtins.elem "postgres" haServiceConfig.SupplementaryGroups)
      then
        throw ''
          FAIL: Socket authentication requires postgres group
          recorder.db_url uses socket: ${recorderDbUrl}
          systemd.services.home-assistant.serviceConfig.SupplementaryGroups must include "postgres"
          Current: ${lib.concatStringsSep ", " (haServiceConfig.SupplementaryGroups or [])}
        ''
      else "PASS: home-assistant service has postgres supplementary group for socket auth"
    else "PASS: Not using PostgreSQL socket authentication";

  # =============================================
  # Prometheus Validation
  # =============================================

  # Test 5: Prometheus retention should be 365d for long-term analysis
  prometheusRetentionCorrect =
    if prometheusConfig.enable
    then
      if prometheusConfig.retentionTime != "365d"
      then
        throw ''
          FAIL: Prometheus retention time misconfigured
          Expected: 365d (1 year for long-term trends)
          Actual: ${prometheusConfig.retentionTime}
        ''
      else "PASS: Prometheus retention set to 365d"
    else "PASS: Prometheus not enabled";

  # =============================================
  # Grafana Validation
  # =============================================

  # Test 6: Grafana dashboard provisioning must be enabled
  grafanaDashboardProvisioningEnabled =
    if grafanaConfig.enable
    then
      if !grafanaConfig.provision.enable
      then
        throw ''
          FAIL: Grafana provisioning not enabled
          services.grafana.provision.enable must be true
        ''
      else "PASS: Grafana provisioning enabled"
    else "PASS: Grafana not enabled";

  # Test 7: Dashboard providers must include required categories
  grafanaDashboardProvidersValid =
    if grafanaConfig.enable && grafanaConfig.provision.enable
    then let
      providers = grafanaConfig.provision.dashboards.settings.providers or [];
      providerNames = builtins.map (p: p.name) providers;
      requiredProviders = ["Infrastructure" "Smart Home" "Services"];
      missingProviders = lib.filter (name: !builtins.elem name providerNames) requiredProviders;
    in
      if builtins.length missingProviders > 0
      then
        throw ''
          FAIL: Grafana dashboard providers missing
          Required: ${lib.concatStringsSep ", " requiredProviders}
          Found: ${lib.concatStringsSep ", " providerNames}
          Missing: ${lib.concatStringsSep ", " missingProviders}
        ''
      else "PASS: All required Grafana dashboard providers configured"
    else "PASS: Grafana provisioning not configured";

  # Test 8: Prometheus datasource must be configured
  grafanaPrometheusDataSourceConfigured =
    if grafanaConfig.enable && grafanaConfig.provision.enable
    then let
      datasources = grafanaConfig.provision.datasources.settings.datasources or [];
      promDs = lib.findFirst (ds: ds.type == "prometheus") null datasources;
    in
      if promDs == null
      then
        throw ''
          FAIL: Prometheus datasource not configured in Grafana
          services.grafana.provision.datasources.settings.datasources must include prometheus
        ''
      else if (promDs.uid or "") != "prometheus"
      then
        throw ''
          FAIL: Prometheus datasource UID misconfigured
          Expected: prometheus
          Actual: ${promDs.uid or "not set"}
        ''
      else "PASS: Prometheus datasource configured with correct UID"
    else "PASS: Grafana provisioning not configured";
in {
  # Export test results
  inherit
    postgresqlServiceEnabled
    databaseNameMatches
    databaseUserExists
    socketAuthConfigured
    prometheusRetentionCorrect
    grafanaDashboardProvisioningEnabled
    grafanaDashboardProvidersValid
    grafanaPrometheusDataSourceConfigured
    ;

  # Summary test that fails if any check fails
  all = builtins.deepSeq [
    postgresqlServiceEnabled
    databaseNameMatches
    databaseUserExists
    socketAuthConfigured
    prometheusRetentionCorrect
    grafanaDashboardProvisioningEnabled
    grafanaDashboardProvidersValid
    grafanaPrometheusDataSourceConfigured
  ] "PASS: All service validation tests passed";
}
