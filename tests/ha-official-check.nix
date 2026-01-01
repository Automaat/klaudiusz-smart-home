{
  lib,
  pkgs,
  nixosConfig,
}: let
  haConfig = nixosConfig.services.home-assistant.config;

  # ===========================================
  # Generate Home Assistant Configuration
  # ===========================================
  # Create a complete HA config directory structure
  haConfigDir = pkgs.runCommand "ha-config-dir" {
    buildInputs = [pkgs.yq-go];
  } ''
    mkdir -p $out/.storage
    mkdir -p $out/custom_components

    # Generate configuration.yaml from Nix config
    cat > $out/configuration.yaml <<'EOF'
${lib.generators.toYAML {} haConfig}
EOF

    # Create minimal .storage/core (required for HA to start)
    cat > $out/.storage/core <<'EOF'
{
  "version": 1,
  "minor_version": 1,
  "key": "core",
  "data": {}
}
EOF

    # Create empty secrets.yaml (referenced templates won't be validated)
    touch $out/secrets.yaml

    echo "Home Assistant config directory created at $out"
  '';

  # ===========================================
  # Run Official Home Assistant Config Check
  # ===========================================
  officialCheck = pkgs.runCommand "ha-official-config-check" {
    buildInputs = [pkgs.home-assistant];
  } ''
    export HOME=$TMPDIR

    # Run official check_config script with fail-on-warnings
    echo "Running official Home Assistant config validation..."
    if hass --script check_config \
      -c ${haConfigDir} \
      --fail-on-warnings \
      > $TMPDIR/check_output.txt 2>&1; then
      echo "PASS: Official Home Assistant config check passed"
      cat $TMPDIR/check_output.txt
      echo "PASS: Official Home Assistant config check passed" > $out
    else
      echo "FAIL: Official Home Assistant config check failed"
      cat $TMPDIR/check_output.txt
      exit 1
    fi
  '';
in {
  inherit officialCheck;

  # Export for use in flake checks
  all = officialCheck;
}
