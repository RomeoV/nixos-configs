{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.darwin.follows = "";
    # redlib.url = "github:RomeoV/redlib";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, agenix }: {
    nixosConfigurations.mycloud-nixos-2 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix 
        agenix.nixosModules.default
        # redlib.nixosModules.default
      ];
      specialArgs = {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        pkgs-unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
        agenix = agenix.packages.x86_64-linux;
        # same as `nixpkgs=nixpgs; nixpkgs-unstable=nixpkgs-unstable;`
        inherit nixpkgs nixpkgs-unstable;
        # redlib = redlib.packages.x86_64-linux;
      };
    };
  };
}

