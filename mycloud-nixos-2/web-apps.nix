{ config, pkgs
  , pkgs-unstable
  # , nixpkgs-unstable, pkgs-unstable
  , ... }:

{

  users.users.syncthing = {
    createHome = true;
    home = "/home/syncthing";
    homeMode = "750"; # Set home directory mode explicitly, so that other users in that group can access it.
    isSystemUser = true;
    group = "syncthing";
    extraGroups = [ "openclaw" ]; # Read access to /var/lib/openclaw for syncing
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
        "Pixel-9" = { id = "WATB6HW-SRETYW3-5GH5CRH-Z7ND2I5-EUVXA4A-2KBXA77-WXDZYQU-SSISFQF"; };
        "Lenovo-P1" = { id = "CJFK7D3-YBQ7CFY-7BXQLIZ-P6UDS6I-MIZR6IH-JDRT5GH-OJY3B56-4SVJQAX"; };
      };
      folders = {
        "todo_notes" = {         # Folder ID in Syncthing, also the name of folder (label) by default
          path = "/home/syncthing/todo_notes";    # Which folder to add to Syncthing
          devices = [ "Pixel-6" "Pixel-9" "Lenovo-P1" ];      # Which devices to share the folder with
        };
        "openclaw_workspace" = {         # Folder ID in Syncthing, also the name of folder (label) by default
          path = "/var/lib/openclaw/.openclaw/workspace";    # Which folder to add to Syncthing
          devices = [ "Pixel-6" "Pixel-9" "Lenovo-P1" ];      # Which devices to share the folder with
          versioning = {
            type = "staggered";
            params = {
              maxAge = "30";
            };
          };
        };
      };
    };
  };

  # UMask strips permissions from new files. Digits: special-owner-group-other.
  # Default 0022 strips group+other write → files are 0644 (rw-r--r--).
  # We use 0002 to only strip other-write → files are 0664 (rw-rw-r--),
  # so openclaw can write to files via setgid group inheritance.
  systemd.services.syncthing.serviceConfig.UMask = "0002";

  services.sbucaptions-webserver = {
    enable = true;
    address = "0.0.0.0";
    port = 8096;
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "storage.mycloud";
    config.dbtype = "sqlite";  # just use a simple file-backed db
    https = false;  # for vpn usage

    # S3 Object Storage Configuration for Hetzner
    config.objectstore.s3 = {
      enable = true;
      bucket = "nextcloud-storage";
      hostname = "hel1.your-objectstorage.com";
      usePathStyle = false;
      region = "hel1";
      verify_bucket_exists = true;

      # Don't specify 'key' here - we'll use environment variable instead
      key = "IN0XRRAR736RWGGNWB5N";
      secretFile = config.age.secrets.nextcloud-object-storage-secret.path;
    };
    settings.trusted_domains = [
      "storage.mycloud"
    ];
    # https = true;
    config.adminpassFile = config.age.secrets.nextcloud_admin_pass.path;
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
  systemd.services.audiobookshelf.unitConfig.RequiresMountsFor = "/mnt/storage-box";

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

  services.freshrss = {
    enable = true;
    package = pkgs-unstable.freshrss;
    baseUrl = "http://freshrss.mycloud";
    defaultUser = "admin";
    authType = "none";
    virtualHost = "freshrss.mycloud";
    api.enable = true;
  };

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
