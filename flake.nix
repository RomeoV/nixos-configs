{
  description = "Hetzner servers - NixOS configurations + infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.darwin.follows = "";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Application inputs (mycloud-nixos-2)
    redlib = {
      url = "github:RomeoV/redlib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sbucaptions-webserver.url = "git+ssh://git@github/RomeoV/sbucaptions-webserver?rev=ea12ee93a37abd5cdece9e15e9eba0b9fe63e3ff";
    isd = {
      url = "github:isd-project/isd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenda-exporter.url = "git+ssh://git@github/RomeoV/agenda-exporter?rev=908fc286a88e14c94e3f440d64155460be4b33ea";
    openclaw-nix = {
      url = "github:romeov/openclaw-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nixpkgs-small, agenix, deploy-rs, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };

    # Extra args available to all NixOS modules via specialArgs
    commonSpecialArgs = {
      inherit inputs self;
      inherit (inputs) sbucaptions-webserver;
      pkgs-unstable = import nixpkgs-unstable { inherit system; };
      pkgs-small = import nixpkgs-small {
        inherit system;
        config.permittedInsecurePackages = [ "openclaw-2026.4.2" ];
      };
      agenixPkgs = agenix.packages.${system};
      isdPkgs = inputs.isd.packages.${system};
      agendaExporter = inputs.agenda-exporter.packages.${system};
      rootPath = ./.;
    };

    mkMachine = modules: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules = [ agenix.nixosModules.default ] ++ modules;
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        deploy-rs.packages.${system}.default
        pkgs.opentofu
        pkgs.jq
        pkgs.ssh-to-age
        agenix.packages.${system}.default
      ];
    };

    nixosConfigurations = {
      mycloud-nixos = mkMachine [ ./machines/mycloud-nixos ];
      mycloud-nixos-2 = mkMachine [
        inputs.openclaw-nix.nixosModules.default
        { nixpkgs.overlays = [ inputs.openclaw-nix.overlays.default ]; }
        { disabledModules = [ "services/web-apps/freshrss.nix" ]; }
        "${nixpkgs-unstable}/nixos/modules/services/web-apps/freshrss.nix"
        ./machines/mycloud-nixos-2
      ];
    };

    apps.${system}.deploy-rs = deploy-rs.apps.${system}.default;

    deploy.nodes.mycloud-nixos-2 = {
      hostname = "mycloud2";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.mycloud-nixos-2;
      };
    };

    checks.${system} = deploy-rs.lib.${system}.deployChecks self.deploy;
  };
}
