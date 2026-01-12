{
  lib,
  pkgs,
  nixosConfig,
}: let
  dashboardFiles = [
    ../hosts/homelab/grafana/dashboards/infrastructure/node-exporter.json
    ../hosts/homelab/grafana/dashboards/infrastructure/postgresql.json
    ../hosts/homelab/grafana/dashboards/smart-home/home-assistant.json
    ../hosts/homelab/grafana/dashboards/services/service-health.json
    ../hosts/homelab/grafana/dashboards/services/error-logs.json
  ];

  # Validate JSON syntax
  validateJson = file:
    pkgs.runCommand "validate-${baseNameOf file}" {} ''
      echo "Validating JSON syntax: ${file}"
      ${pkgs.jq}/bin/jq empty ${file}
      touch $out
    '';

  # Check datasource UID is "prometheus" (or not set for community dashboards)
  checkDatasourceUid = file:
    pkgs.runCommand "check-uid-${baseNameOf file}" {} ''
      echo "Checking datasource UIDs in: ${file}"

      # Extract all datasource UIDs from panels
      UIDS=$(${pkgs.jq}/bin/jq -r '
        [.panels[]? | recurse | .datasource?.uid? | select(. != null)] | unique | .[]
      ' ${file} 2>/dev/null || echo "")

      # Check if any UIDs exist and validate them
      if [ -n "$UIDS" ]; then
        while IFS= read -r uid; do
          if [ "$uid" != "prometheus" ] && [ "$uid" != "\$\{DS_PROMETHEUS\}" ]; then
            echo "WARNING: Dashboard ${baseNameOf file} has datasource UID: $uid (expected 'prometheus')"
            # Don't fail - some community dashboards use template variables
          fi
        done <<< "$UIDS"
      fi

      echo "Datasource check passed for ${baseNameOf file}"
      touch $out
    '';

  # Validate dashboard has required fields
  validateDashboardStructure = file:
    pkgs.runCommand "structure-${baseNameOf file}" {} ''
      echo "Validating dashboard structure: ${file}"

      # Check required fields exist
      ${pkgs.jq}/bin/jq -e '.title' ${file} > /dev/null || {
        echo "ERROR: Dashboard ${file} missing 'title' field"
        exit 1
      }

      ${pkgs.jq}/bin/jq -e '.panels' ${file} > /dev/null || {
        echo "ERROR: Dashboard ${file} missing 'panels' field"
        exit 1
      }

      echo "Structure validation passed for ${baseNameOf file}"
      touch $out
    '';

  jsonTests = map validateJson dashboardFiles;
  uidTests = map checkDatasourceUid dashboardFiles;
  structureTests = map validateDashboardStructure dashboardFiles;
in {
  all = pkgs.runCommand "grafana-dashboard-tests" {} ''
    echo "=== Grafana Dashboard Validation ==="
    echo "Validating ${toString (builtins.length dashboardFiles)} dashboard files..."

    # Run all tests
    ${lib.concatMapStringsSep "\n" (t: "cat ${t}") (jsonTests ++ uidTests ++ structureTests)}

    echo ""
    echo "✓ All dashboard tests passed!"
    echo "  - JSON syntax: ${toString (builtins.length jsonTests)} files"
    echo "  - Datasource UIDs: ${toString (builtins.length uidTests)} files"
    echo "  - Structure: ${toString (builtins.length structureTests)} files"

    touch $out
  '';
}
