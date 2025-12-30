{
  description = "Klaudiusz Smart Home - NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    comin,
    sops-nix,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    homelabConfig = self.nixosConfigurations.homelab;
  in {
    nixosConfigurations = {
      # Home Assistant server (Intel N100)
      homelab = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          comin.nixosModules.comin
          sops-nix.nixosModules.sops
          ./hosts/homelab
        ];
      };
    };

    # Formatter for `nix fmt`
    formatter = {
      x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
    };

    # Tests
    checks.${system} = let
      lib = nixpkgs.lib;
      nixosConfig = homelabConfig.config;

      configValidation = import ./tests/config-validation.nix {
        inherit lib pkgs nixosConfig;
      };

      schemaValidation = import ./tests/schema-validation.nix {
        inherit lib pkgs nixosConfig;
      };

      serviceValidation = import ./tests/service-validation.nix {
        inherit lib pkgs nixosConfig;
      };

      haConfigCheck = import ./tests/ha-config-check.nix {
        inherit lib pkgs nixosConfig;
      };

      vmTest = import ./tests/vm-test.nix {
        inherit pkgs self;
      };
    in {
      # Configuration validation tests
      config-validation = pkgs.runCommand "config-validation-tests" {} ''
        echo "Running configuration validation tests..."
        echo "${configValidation.all}"
        touch $out
      '';

      # Schema validation tests
      schema-validation = pkgs.runCommand "schema-validation-tests" {} ''
        echo "Running schema validation tests..."
        echo "${schemaValidation.all}"
        touch $out
      '';

      # Service validation tests
      service-validation = pkgs.runCommand "service-validation-tests" {} ''
        echo "Running service validation tests..."
        echo "${serviceValidation.all}"
        touch $out
      '';

      # Home Assistant config validation
      ha-config-validation = haConfigCheck.all;

      # NixOS VM integration test
      vm-integration-test = vmTest;

      # All static tests (fast - run on PRs)
      all-static-tests = pkgs.runCommand "all-static-tests" {} ''
        echo "Running all static tests..."
        echo "Config validation result: $(cat ${self.checks.${system}.config-validation})"
        echo "Schema validation result: $(cat ${self.checks.${system}.schema-validation})"
        echo "Service validation result: $(cat ${self.checks.${system}.service-validation})"
        echo "HA config validation result: $(cat ${self.checks.${system}.ha-config-validation})"
        echo "All static tests passed!"
        touch $out
      '';

      # All integration tests (slow - run on main only)
      all-integration-tests = pkgs.runCommand "all-integration-tests" {
        vmTestResult = vmTest;
      } ''
        echo "Running all integration tests..."
        echo "VM test completed successfully"
        echo "All integration tests passed!"
        touch $out
      '';

      # All tests (static + integration)
      all-tests = pkgs.runCommand "all-tests" {} ''
        echo "Running all tests..."
        cat ${self.checks.${system}.all-static-tests}
        cat ${self.checks.${system}.all-integration-tests}
        echo "All tests passed!"
        touch $out
      '';
    };
  };
}
