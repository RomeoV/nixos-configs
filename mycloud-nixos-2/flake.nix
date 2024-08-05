{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/3259cf03626f8fd2f54c67becd531b9276885a64";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.darwin.follows = "";
    redlib.url = "github:RomeoV/redlib";
    nixpkgs-immich.url = "github:jvanbruegge/nixpkgs/immich";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-master, agenix, redlib, nixpkgs-immich }: {
      nixosConfigurations.mycloud-nixos-2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ./networking.nix # generated at runtime by nixos-infect
          ./system-configuration.nix
          ./secrets-management.nix
          ./web-apps.nix
          ./mlflow-service.nix
          agenix.nixosModules.default
          redlib.nixosModules.default
        ];
        specialArgs = {
          # same as `nixpkgs=nixpgs; nixpkgs-unstable=nixpkgs-unstable;`
          inherit nixpkgs nixpkgs-unstable nixpkgs-master;
          inherit nixpkgs-immich;
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          pkgs-unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
          pkgs_unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;  # for compat with redlib
          pkgs-master = nixpkgs-master.legacyPackages.x86_64-linux;
          pkgs-immich = nixpkgs-immich.legacyPackages.x86_64-linux;
          agenix = agenix.packages.x86_64-linux;
          redlib = redlib.packages.x86_64-linux;
        };
      };
    };
}

