{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    # nixpkgs-mlflow.url = "github:NixOS/nixpkgs/3259cf03626f8fd2f54c67becd531b9276885a64";
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
    nix-zeroclaw = {
      url = "github:RomeoV/nix-zeroclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    openclaw-nix = {
      url = "git+file:///home/romeo/Documents/hetzner-servers/worktrees/hetzner2/openclaw-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, nixpkgs-small, agenix, redlib, sbucaptions-webserver, isd, agenda-exporter, nix-zeroclaw, openclaw-nix, deploy-rs }:
    let
      moduleArgs = {
        # same as `nixpkgs=nixpgs; nixpkgs-unstable=nixpkgs-unstable;`
        inherit nixpkgs;
        # inherit nixpkgs-unstable;
        inherit sbucaptions-webserver;
        inherit inputs;
        # pkgs = nixpkgs.legacyPackages.x86_64-linux;
        pkgs-unstable = import nixpkgs-unstable { system = "x86_64-linux"; };
        pkgs-small = import nixpkgs-small {
          system = "x86_64-linux";
          config.permittedInsecurePackages = [ "openclaw-2026.4.2" ];
        };
        # pkgs-mlflow = nixpkgs-mlflow.legacyPackages.x86_64-linux;
        agenix = agenix.packages.x86_64-linux;
        isdPkgs = isd.packages.x86_64-linux;
        agendaExporter = agenda-exporter.packages.x86_64-linux;
        rootPath = ./.;
      };
    in {
      apps.x86_64-linux.deploy-rs = deploy-rs.apps.x86_64-linux.default;

      deploy.nodes.mycloud-nixos-2 = {
        hostname = "mycloud2";
        sshUser = "root";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.mycloud-nixos-2;
        };
      };

      checks.x86_64-linux = deploy-rs.lib.x86_64-linux.deployChecks self.deploy;

      nixosConfigurations.mycloud-nixos-2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ./networking.nix # generated at runtime by nixos-infect
          ./system-configuration.nix
          ./secrets-management.nix
          ./web-apps.nix
          ./nginx.nix
          ./blog.nix
          ./mlflow-service.nix
          ./sbucaptions-webserver-service.nix
          agenix.nixosModules.default
          # nix-zeroclaw.nixosModules.zeroclaw  # Disabled - using openclaw now
          openclaw-nix.nixosModules.default
          { nixpkgs.overlays = [
              # nix-zeroclaw.overlays.default  # Disabled - using openclaw now
              openclaw-nix.overlays.default
            ];
          }
          # ./zeroclaw.nix  # Disabled - keeping config for reference
          ./openclaw-config.nix
          ./mailsync.nix
          ({ _module.args = moduleArgs;  })
          # "${nixpkgs-unstable}/nixos/modules/services/networking/anubis.nix"
          { disabledModules = [ "services/web-apps/freshrss.nix" ]; }
          "${nixpkgs-unstable}/nixos/modules/services/web-apps/freshrss.nix"
        ];
      };
    };
}
