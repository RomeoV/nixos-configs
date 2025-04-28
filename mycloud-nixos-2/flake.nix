{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-mlflow.url = "github:NixOS/nixpkgs/3259cf03626f8fd2f54c67becd531b9276885a64";
    agenix ={
      url = "github:ryantm/agenix";
      inputs.darwin.follows = "";
    };
    redlib = {
      url = "github:RomeoV/redlib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sbucaptions-webserver.url = "git+ssh://git@github/RomeoV/sbucaptions-webserver?rev=ea12ee93a37abd5cdece9e15e9eba0b9fe63e3ff";
    # sbucaptions-webserver.inputs.nixpkgs.follows = "nixpkgs";
    isd = {
      url = "github:isd-project/isd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenda-exporter.url = "git+ssh://git@github/RomeoV/agenda-exporter?rev=908fc286a88e14c94e3f440d64155460be4b33ea";
  };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, nixpkgs-mlflow, agenix, redlib, sbucaptions-webserver, isd, agenda-exporter}: {
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
          # "${nixpkgs-unstable}/nixos/modules/services/networking/anubis.nix"
        ];
        specialArgs = {
          # same as `nixpkgs=nixpgs; nixpkgs-unstable=nixpkgs-unstable;`
          inherit nixpkgs;
          # inherit nixpkgs-unstable;
          inherit sbucaptions-webserver;
          inherit inputs;
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          pkgs-mlflow = nixpkgs-mlflow.legacyPackages.x86_64-linux;
          agenix = agenix.packages.x86_64-linux;
          isdPkgs = isd.packages.x86_64-linux;
          agendaExporter = agenda-exporter.packages.x86_64-linux;
          rootPath = ./.;
        };
      };
    };
}

