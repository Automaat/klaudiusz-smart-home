{
  description = "Klaudiusz Smart Home - NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    comin,
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

      # All tests
      all-tests =
        pkgs.runCommand "all-tests" {
          buildInputs = [
            self.checks.${system}.config-validation
            self.checks.${system}.schema-validation
          ];
        } ''
          echo "All tests passed!"
          touch $out
        '';
    };
  };
}
