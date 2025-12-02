{ config, pkgs
  , pkgs-unstable
  # , nixpkgs-unstable, pkgs-unstable
  , ... }:

{

  users.users.syncthing = {
    createHome = true;
    home = "/home/syncthing";
    homeMode = "750"; # Set home directory mode explicitly, so that other users in that group can access it.
    # Don't remove other settings your syncthing user already has
    isSystemUser = true;
    group = "syncthing";
  };
  services.syncthing = {
    enable = true;
    user = "syncthing";
    dataDir = "/home/syncthing";    # Default folder for new synced folders
    configDir = "/home/syncthing/.config/syncthing";   # Folder for Syncthing's settings and keys
    key = config.age.secrets.syncthing-key.path;
    cert = config.age.secrets.syncthing-cert.path;

    overrideDevices = true;     # overrides any devices added or deleted through the WebUI
    overrideFolders = true;     # overrides any folders added or deleted through the WebUI
    settings = {
      devices = {
        "Pixel-6" = { id = "AU6EZ3T-SS4M427-6PHHM2S-EC2VBOY-LQP2RVB-YEORIC7-UQMBEPQ-6ECGNAG"; };
        "Lenovo-P1" = { id = "CJFK7D3-YBQ7CFY-7BXQLIZ-P6UDS6I-MIZR6IH-JDRT5GH-OJY3B56-4SVJQAX"; };
      };
      folders = {
        "todo_notes" = {         # Folder ID in Syncthing, also the name of folder (label) by default
          path = "/home/syncthing/todo_notes";    # Which folder to add to Syncthing
          devices = [ "Pixel-6" "Lenovo-P1" ];      # Which devices to share the folder with
        };
      };
    };
  };

  services.sbucaptions-webserver = {
    enable = true;
    address = "0.0.0.0";
    port = 8096;
  };

  services.nextcloud = {
    enable = false;
    package = pkgs.nextcloud30;
    hostName = "nextcloud";
    settings.trusted_domains = ["100.64.0.10"];
    # https = true;
    config.adminpassFile = config.age.secrets.nextcloud_admin_pass.path;
    home = "/mnt/nextcloud_storage";
    # datadir = "/mnt/nextcloud_storage";
  };

  # # this doens't work. We have to go back to the datadir approach.
  # systemd.tmpfiles.rules = [
  #     "L+ /var/lib/nextcloud/data nextcloud nextcloud - /mnt/nextcloud_storage"
  # ];
  users.users.nextcloud = {
    uid = 994;
    group = "nextcloud";
  };
  users.groups.nextcloud.gid = 994;
  systemd.services.nextcloud-setup = {
    requires = [ "mnt-nextcloud_storage.mount" ];
    after = [ "mnt-nextcloud_storage.mount" ];
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

  services.audiobookshelf = {
    enable = true;
    # host = "127.0.0.1";
    host = "0.0.0.0";
    port = 8092;
  };

  services.calibre-web = {
    enable = true;
    listen = {
      ip = "0.0.0.0";
      port = 8093;
    };
  };

  services.invidious = {
      enable = false;
      port = 8090;
  };

  services.mlflow-server = {
    enable = true;
    # package = pkgs-unstable.mlflow-server;
    # python = pkgs-mlflow.python3;
    port = 8091;
    host = "0.0.0.0";  # Listen on all interfaces
    # basedir = "/mnt/mlflow-artifacts";
    # artifactRoot = "/mnt/mlflow-artifacts/mlartifacts";
    # extraArgs = [ "--backend-store-uri" "sqlite:///var/lib/mlflow/mlflow.db" ];
  };

  services.paperless = {
    enable = false;
    address = "0.0.0.0";
    port = 28981;
    passwordFile = config.age.secrets.paperless-admin-password.path;
    settings = {
      PAPERLESS_OCR_LANGUAGE = "deu+eng";
    };
  };
  systemd.services.paperless.serviceConfig.TimeoutStopSec = "15s";

  services.immich = {
    enable = true;
    machine-learning.enable = true;
    host = "0.0.0.0";
    port = 3001;
    # We keep upload there, but then symlink some dirs to mounted object storage
    mediaLocation = "/var/lib/immich";  # default
  };
  users.users.immich = {
    uid = 993;
    group = "immich";
  };
  users.groups.immich.gid = 993;
  systemd.services.immich-server = {
    requires = [ "mnt-immich\\x2dlibrary.mount" ];
    after = [ "mnt-immich\\x2dlibrary.mount" ];
  };

}
