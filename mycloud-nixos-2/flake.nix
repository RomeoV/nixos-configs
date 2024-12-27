{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-mlflow.url = "github:NixOS/nixpkgs/3259cf03626f8fd2f54c67becd531b9276885a64";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.darwin.follows = "";
    redlib.url = "github:RomeoV/redlib";
    sbucaptions-webserver.url = "git+ssh://git@github/RomeoV/sbucaptions-webserver?rev=ea12ee93a37abd5cdece9e15e9eba0b9fe63e3ff";
    # sbucaptions-webserver.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, nixpkgs-mlflow, agenix, redlib, sbucaptions-webserver }: {
      nixosConfigurations.mycloud-nixos-2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ./networking.nix # generated at runtime by nixos-infect
          ./system-configuration.nix
          ./secrets-management.nix
          ./web-apps.nix
          ./nginx.nix
          ./mlflow-service.nix
          ./sbucaptions-webserver-service.nix
          agenix.nixosModules.default
        ];
        specialArgs = {
          # same as `nixpkgs=nixpgs; nixpkgs-unstable=nixpkgs-unstable;`
          inherit nixpkgs nixpkgs-unstable;
          inherit sbucaptions-webserver;
          inherit inputs;
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          pkgs-unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
          pkgs_unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;  # for compat with redlib
          pkgs-mlflow = nixpkgs-mlflow.legacyPackages.x86_64-linux;
          agenix = agenix.packages.x86_64-linux;
          redlib = redlib.packages.x86_64-linux;
          rootPath = ./.;
        };
      };
    };
}

