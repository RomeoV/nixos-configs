{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.darwin.follows = "";
    redlib.url = "github:RomeoV/redlib";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, agenix, redlib }: {
    nixosConfigurations.mycloud-nixos-2 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        ./networking.nix # generated at runtime by nixos-infect
        ./system-configuration.nix
        ./secrets-management.nix
        ./web-apps.nix
        agenix.nixosModules.default
        redlib.nixosModules.default
      ];
      specialArgs = {
        # same as `nixpkgs=nixpgs; nixpkgs-unstable=nixpkgs-unstable;`
        inherit nixpkgs nixpkgs-unstable;
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        pkgs-unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
        pkgs_unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;  # for compat with redlib
        agenix = agenix.packages.x86_64-linux;
        redlib = redlib.packages.x86_64-linux;
      };
    };
  };
}

