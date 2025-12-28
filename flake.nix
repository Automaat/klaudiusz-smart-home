{
  description = "Klaudiusz Smart Home - NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, comin }: {
    nixosConfigurations = {
      # Home Assistant server (Intel N100)
      homelab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          comin.nixosModules.comin
          ./hosts/homelab
        ];
      };
    };
  };
}
