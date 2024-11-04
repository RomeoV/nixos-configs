#!/usr/bin/env sh

rsync configuration.nix hetzner:/etc/nixos
rsync -r agenix hetzner:/etc/nixos
nixos-rebuild switch --target-host hetzner \
    -I nixos-config=./configuration.nix \
    -I nixos=https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz \
    -I nixos-unstable=https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz \
    -I agenix=https://github.com/ryantm/agenix/archive/main.tar.gz \
    "$@"
