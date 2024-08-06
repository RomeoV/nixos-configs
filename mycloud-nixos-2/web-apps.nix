{ config, pkgs, nixpkgs-immich, pkgs-immich, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud28;
    hostName = "storage.romeov.me";
    https = true;
    config.adminpassFile = config.age.secrets.nextcloud_admin_pass.path;
    # home="/storage/nextcloud";
  };

  services.redlib = {
    enable = true;
    address = "0.0.0.0";
    port = 8081;
  };
  systemd.services.redlib.environment = {
    REDLIB_DEFAULT_SHOW_NSFW = "on";
    REDLIB_DEFAULT_USE_HLS = "on";
    REDLIB_DEFAULT_HIDE_HLS_NOTIFICATION = "on";
    REDLIB_DEFAULT_AUTOPLAY_VIDEOS = "on";
  };

  services.gotosocial = {
    enable = false;
    # setupPostgresqlDB = true;
    settings.host = "gts.romeov.me";
    settings.port = 8089;
    # storage-local-base-path = "/storage/gotosocial";
  };

  services.invidious = {
      enable = true;
      port = 8090;
  };

  services.mlflow-server = {
    enable = true;
    port = 5000;
    host = "0.0.0.0";  # Listen on all interfaces
    basedir = "/mnt/mlflow-artifacts";
    # artifactRoot = "/mnt/mlflow-artifacts/mlartifacts";
    # extraArgs = [ "--backend-store-uri" "sqlite:///var/lib/mlflow/mlflow.db" ];
  };

  services.paperless = {
    enable = true;
    address = "0.0.0.0";
    port = 28981;
    passwordFile = config.age.secrets.paperless-admin-password.path;
    settings = {
      PAPERLESS_OCR_LANGUAGE = "deu+eng";
    };
  };

  # Using immich from another nixpkgs fork.
  # See https://lgug2z.com/articles/selectivey-using-service-modules-from-nixos-unstable/

  # We would usually disable this, but immich isn't defined yet at all.
  imports = [
    "${nixpkgs-immich}/nixos/modules/services/web-apps/immich.nix"
  ];
  services.immich = {
    enable = true;
    package = pkgs-immich.immich;
    host = "0.0.0.0";
    mediaLocation = "/mnt/storage-box/immich";
  };

}
