{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.agenix.url = "github:ryantm/agenix";

  outputs = { nixpkgs, flake-utils, agenix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.nixos-rebuild
            pkgs.bashInteractive
            agenix.packages.${system}.default
          ];
        };
      });
}
