#!/usr/bin/env sh

nixos-rebuild switch --target-host hetzner -I nixos-config=./configuration.nix -I agenix=https://github.com/ryantm/agenix/archive/main.tar.gz "$@"
