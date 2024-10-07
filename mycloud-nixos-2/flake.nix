{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.darwin.follows = "";
    redlib.url = "github:RomeoV/redlib";
    sbucaptions-webserver.url = "git+ssh://git@github/RomeoV/sbucaptions-webserver";
    # sbucaptions-webserver.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, agenix, redlib, sbucaptions-webserver }: {
      nixosConfigurations.mycloud-nixos-2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ./networking.nix # generated at runtime by nixos-infect
          ./system-configuration.nix
          ./secrets-management.nix
          ./web-apps.nix
          ./mlflow-service.nix
          ./sbucaptions-webserver-service.nix
          agenix.nixosModules.default
          redlib.nixosModules.default
        ];
        specialArgs = {
          # same as `nixpkgs=nixpgs; nixpkgs-unstable=nixpkgs-unstable;`
          inherit nixpkgs nixpkgs-unstable;
          inherit sbucaptions-webserver;
          inherit inputs;
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          pkgs-unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
          pkgs_unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;  # for compat with redlib
          agenix = agenix.packages.x86_64-linux;
          redlib = redlib.packages.x86_64-linux;
          rootPath = ./.;
        };
      };
    };
}

