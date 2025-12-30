{
  lib,
  pkgs,
  nixosConfig,
}: let
  haConfig = nixosConfig.services.home-assistant.config;

  # Mock secrets for config validation
  mockSecrets = pkgs.runCommand "mock-secrets" {} ''
    mkdir -p $out
    echo "mock-prometheus-token-12345" > $out/home-assistant-prometheus-token
    echo "mock-grafana-password-12345" > $out/grafana-admin-password
  '';

  # Generate Home Assistant configuration for validation
  # This converts the Nix config structure to what HA expects
  haConfigDir =
    pkgs.runCommand "ha-config-for-validation" {
      buildInputs = [pkgs.home-assistant];
    } ''
      mkdir -p $out

      # Create a minimal configuration.yaml that includes our generated config
      # HA will validate the structure when we run check_config
      cat > $out/configuration.yaml <<EOF
      # Generated from NixOS configuration for validation

      homeassistant:
        name: ${haConfig.homeassistant.name}
        unit_system: ${haConfig.homeassistant.unit_system}
        currency: ${haConfig.homeassistant.currency}
        country: ${haConfig.homeassistant.country}
        language: ${haConfig.homeassistant.language}
        time_zone: ${haConfig.homeassistant.time_zone}
        latitude: ${toString haConfig.homeassistant.latitude}
        longitude: ${toString haConfig.homeassistant.longitude}
        elevation: ${toString haConfig.homeassistant.elevation}

      # Core components
      conversation: {}
      frontend: {}
      http:
        server_port: ${toString haConfig.http.server_port}

      # Logger
      logger:
        default: ${haConfig.logger.default}

      # Recorder (PostgreSQL)
      recorder:
        db_url: ${haConfig.recorder.db_url}
        purge_keep_days: ${toString haConfig.recorder.purge_keep_days}
        commit_interval: ${toString haConfig.recorder.commit_interval}
      EOF

      # Create empty directories HA expects
      mkdir -p $out/.storage
      mkdir -p $out/custom_components
      mkdir -p $out/themes

      # Create minimal core config
      echo '{"version": 1}' > $out/.storage/core
    '';

  # Validation tests that don't require running HA
  structureValidation = let
    # Test 1: Verify required top-level keys exist
    requiredKeys = ["homeassistant" "recorder" "http" "logger"];
    missingKeys = lib.filter (key: !(haConfig ? ${key})) requiredKeys;
  in
    if missingKeys != []
    then
      throw ''
        FAIL: Missing required HA config keys:
        ${lib.concatStringsSep "\n" (builtins.map (k: "  - ${k}") missingKeys)}
      ''
    else "PASS: All required HA config keys present";

  # Test 2: Validate homeassistant section
  homeassistantValidation = let
    ha = haConfig.homeassistant;
    requiredHaKeys = ["name" "unit_system" "language" "time_zone" "latitude" "longitude"];
    missingHaKeys = lib.filter (key: !(ha ? ${key})) requiredHaKeys;
  in
    if missingHaKeys != []
    then
      throw ''
        FAIL: Missing required homeassistant config keys:
        ${lib.concatStringsSep "\n" (builtins.map (k: "  - ${k}") missingHaKeys)}
      ''
    else "PASS: All required homeassistant keys present";

  # Test 3: Validate recorder configuration
  recorderValidation = let
    recorderCfg = haConfig.recorder;
    hasDbUrl = recorderCfg ? db_url && recorderCfg.db_url != null;
  in
    if !hasDbUrl
    then throw "FAIL: recorder.db_url must be configured"
    else if !(lib.hasPrefix "postgresql://" recorderCfg.db_url)
    then throw "FAIL: recorder.db_url must use PostgreSQL"
    else "PASS: Recorder configuration valid";

  # Test 4: Validate HTTP configuration
  httpValidation = let
    http = haConfig.http;
    port = http.server_port or 8123;
  in
    if port < 1 || port > 65535
    then throw "FAIL: http.server_port must be 1-65535, got ${toString port}"
    else "PASS: HTTP configuration valid";

  # Test 5: Validate logger configuration
  loggerValidation =
    if !(haConfig.logger ? default)
    then throw "FAIL: logger.default must be set"
    else if !(builtins.elem haConfig.logger.default ["critical" "error" "warning" "info" "debug"])
    then throw "FAIL: logger.default must be valid log level"
    else "PASS: Logger configuration valid";

  # Evaluation-time summary
  evalTests = builtins.deepSeq [
    structureValidation
    homeassistantValidation
    recorderValidation
    httpValidation
    loggerValidation
  ] "PASS: HA config structure validation passed";

  # Build-time YAML syntax validation
  yamlSyntaxValidation =
    pkgs.runCommand "ha-yaml-syntax-check" {
      buildInputs = [pkgs.yq-go];
    } ''
      echo "Validating generated HA configuration YAML syntax..."
      if yq eval '.' ${haConfigDir}/configuration.yaml > /dev/null 2>&1; then
        echo "PASS: HA configuration YAML syntax valid" > $out
      else
        echo "FAIL: HA configuration YAML syntax errors" >&2
        exit 1
      fi
    '';

  # Build-time configuration structure check
  # This doesn't run the full HA config check (requires too many deps)
  # but validates the YAML structure is loadable
  configStructureCheck =
    pkgs.runCommand "ha-config-structure-check" {
      buildInputs = [pkgs.yq-go pkgs.jq];
    } ''
      echo "Validating HA configuration structure..."

      # Extract and validate homeassistant section
      if ! yq eval '.homeassistant.name' ${haConfigDir}/configuration.yaml | grep -q .; then
        echo "FAIL: homeassistant.name not found in config" >&2
        exit 1
      fi

      # Validate recorder section
      if ! yq eval '.recorder.db_url' ${haConfigDir}/configuration.yaml | grep -q 'postgresql'; then
        echo "FAIL: recorder not configured for PostgreSQL" >&2
        exit 1
      fi

      # Check no obvious YAML errors
      if yq eval '.' ${haConfigDir}/configuration.yaml | grep -qi 'null:'; then
        echo "FAIL: Config contains null keys" >&2
        exit 1
      fi

      echo "PASS: HA configuration structure valid" > $out
    '';
in {
  # Export evaluation-time tests
  inherit
    structureValidation
    homeassistantValidation
    recorderValidation
    httpValidation
    loggerValidation
    evalTests
    ;

  # Export build-time tests
  inherit
    yamlSyntaxValidation
    configStructureCheck
    ;

  # Combined check
  all =
    pkgs.runCommand "ha-config-validation" {
      evalResult = evalTests;
    } ''
      echo "Running Home Assistant configuration validation..."
      cat ${yamlSyntaxValidation}
      cat ${configStructureCheck}
      echo "$evalResult"
      echo "PASS: All HA config validation tests passed" > $out
    '';
}
