#!/usr/bin/env sh

nixos-rebuild switch --flake .#mycloud-nixos-2 --target-host hetzner2
