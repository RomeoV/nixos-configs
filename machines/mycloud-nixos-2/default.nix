{ ... }: {
  imports = [
    ../../modules/base.nix
    ../../modules/hetzner.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./system-configuration.nix
    ./secrets-management.nix
    ./web-apps.nix
    ./nginx.nix
    ./blog.nix
    ./mailsync.nix
    ./mlflow-service.nix
    ./sbucaptions-webserver-service.nix
    ./openclaw-config.nix
  ];
}
