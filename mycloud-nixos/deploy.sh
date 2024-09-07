#!/usr/bin/env sh

scp configuration.nix root@mycloud-nixos:/etc/nixos
nixos-rebuild switch --target-host root@mycloud-nixos \
    -I nixos-config=./configuration.nix \
    -I nixos-unstable=https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz \
    -I agenix=https://github.com/ryantm/agenix/archive/main.tar.gz \
    "$@"
