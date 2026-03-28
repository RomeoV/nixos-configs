#!/usr/bin/env sh

# nix flake update agenda-exporter --override-input agenda-exporter ./agenda-exporter
nix run .#deploy-rs -- .#mycloud2 "$@"
