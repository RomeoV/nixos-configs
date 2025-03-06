#!/usr/bin/env sh

# nix flake update agenda-exporter --override-input agenda-exporter ./agenda-exporter
nixos-rebuild switch --flake .#mycloud-nixos-2 --target-host hetzner2 "$@"
