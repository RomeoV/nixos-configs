{ config, lib, pkgs, ... }: 
let
  unstable = import <nixos-unstable> {};
  pkgs_unstable = unstable.pkgs;
  pkgs_master = (import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/403d5963cc5ca2de87bc891dd9090c9995dc7a97.tar.gz";
    sha256 = "1vpk02gjnv0map8n5s0i20y3g8alqm9477vxqjv4ddma1bwzr61l"; 
  }) {}).pkgs;
in {
  imports =   [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
    <agenix/modules/age.nix>  # requires `nix-channel --add https://github.com/ryantm/agenix/archive/main.tar.gz agenix`
    (import ./redlib_service.nix {inherit lib config pkgs_unstable; })
    # (import /etc/nixos/immich.nix {inherit lib config pkgs_unstable; })
    # (import /etc/nixos/mlflow-service.nix {inherit lib config; })
  ];

  system.stateVersion = "22.05";

  nix.settings.experimental-features = "nix-command flakes";
  # nix.allowedUsers = [ "@wheel" ];
  nix.settings.allowed-users = [ "root" ];

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Los_Angeles";

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    randomizedDelaySec = "10min";
    dates = "Mon,Fri 04:40";
  };
  system.copySystemConfiguration = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 90d";
  };
  services.journald.extraConfig = "SystemMaxUse=1000M";

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "mycloud-nixos";
  networking.domain = "romeov.me";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIzDCdxCAPnbdzwkKpp/9AUGMyABSPj/vZffRQoojdHh6Ct+9fZ60vYOS9NaQy9bqdagC0bHrrBvELiTqbAj5E3I1E7Mfp2BXjI/ig+NTlp0SIoaXnlLRNxnb+TSEDuAdqMdgwjxuy63T5PK04e7AH24NQ8J9sF16QAu0A0VurZEzPTLVZIoFCr/qmxZLnsJELdAtmnxCf+ZlBSs+v0qWOibOQ1mgKecii+0hRPSDpmY62FI++AzNoeVJ4j0ObSC/hpLMYkF5DJSkwaD+4+7CDLFhHdIQ5AzZNZp4gS2IESGUVTbUhXHm0YOr/xj66ZLqDzA16F+dSkKrnfRyTGrjdeWNsMTy42W42wEK1FhbHfsg4AQtT7S3kyiKS0lUFPdH34Q6iiTShTtySDCPW46hEp97sYshZ2aSDAIKYRty3mODPZlM12LL6z1bgbte6bsI3JN0nbIULemfgVqlZAHRDpCv05muEi4IPzYdDxMutAN8zNcMz3IyVoRQ/2bw2kds=" 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcP5JDW+JKSD04YGd+giu8oGCVGKjh7ZSap0UbNUYhP JuiceSSH"
  ];

  services.fail2ban = {
    enable = true;  # although the wiki says nixos has a preconfigured ssh jail? Not sure what that means.
    bantime-increment = {
      enable = true;
      factor = "4";
    };
  };

  # see https://xeiaso.net/blog/paranoid-nixos-2021-07-18/, "Audit tracing"
  security.auditd.enable = true;
  security.audit.enable = true;
  security.audit.rules = [
    "-a exit,always -F arch=b64 -S execve"
  ];

  programs = {
    mosh.enable = true;
    git.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      withPython3 = false;
      withRuby = false;
      configure = {
          customRC = ''
	    set nowrap
	  '';
      };
    };
  };

  environment.systemPackages = [
      (pkgs.callPackage <agenix/pkgs/agenix.nix> {})
      pkgs.helix
      pkgs.headscale
      pkgs.rclone
      pkgs.bottom
      # pkgs.onlyoffice-documentserver
      # pkgs.docker-compose  
      pkgs.podman-compose  
      pkgs.waypipe
      unstable.pkgs.redlib
  ];

  ## get ready for docker compose
  # from https://discourse.nixos.org/t/docker-compose-on-nixos/17502/2
  # Pick one
  # virtualisation.docker.enable = true;
  virtualisation = {
    podman = {
      enable = false;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  # virtualisation.podman.enable = true;
  # users.users.root.extraGroups = [ "docker" ];
  # users.users.postgres-immich = {
  #   isNormalUser = false;
  #   description = "postgres user for Immich App.";
  #   # extraGroups = [ postgres ];
  # };

  # services.libreddit = {
  #   enable = true;
  #   address = "127.0.0.1";
  #   port = 8081;
  # };
  # systemd.services.libreddit.environment = {
  #   LIBREDDIT_DEFAULT_SHOW_NSFW = "on";
  #   LIBREDDIT_DEFAULT_USE_HLS = "on";
  #   LIBREDDIT_DEFAULT_HIDE_HLS_NOTIFICATION = "on";
  #   LIBREDDIT_DEFAULT_AUTOPLAY_VIDEOS = "on";
  # };
  services.redlib = {
    enable = true;
    address = "127.0.0.1";
    port = 8081;
  };
  systemd.services.redlib.environment = {
    REDLIB_DEFAULT_SHOW_NSFW = "on";
    REDLIB_DEFAULT_USE_HLS = "on";
    REDLIB_DEFAULT_HIDE_HLS_NOTIFICATION = "on";
    REDLIB_DEFAULT_AUTOPLAY_VIDEOS = "on";
  };

  # services.mlflow-server = {
  #   enable = true;
  # };


  services.nitter = {
    enable = false;
    server = {
      port = 8082;
      https = true;
      hostname = "nitter.romeov.me";
    };
    preferences = {
      replaceTwitter = "nitter.romeov.me";
      hlsPlayback = true;
      muteVideos = true;
      hideTweetStats = true;
    };
  };

  services.gotosocial = {
    enable = true;
    # setupPostgresqlDB = true;
    settings.host = "gts.romeov.me";
    settings.port = 8089;
    # storage-local-base-path = "/mnt/storage-box/gotosocial";
  };


  services.headscale = {
    enable = true;
    port = 8083;
    settings = {
      serverUrl = "https://headscale.romeov.me";
      acl_policy_path = "/etc/headscale/tailnet_policy_file.json";
      # dns_config = { baseDomain = "romeov.me"; };
      # logtail.enabled = false; 
    };
  };
  systemd.services.headscale = {
    environment = {
      HEADSCALE_EXPERIMENTAL_FEATURE_SSH = "1";
    };
  };

  environment.etc."headscale/tailnet_policy_file.json".text = ''
      { "acls": [ {
     	    "action": "accept",
     	    "src": ["*"],
     	    "dst": ["*:*"]
     	} ],
        "ssh": [ {
            "action": "accept",
            "src": ["romeo-p1", "pixel-6"],
            "dst": ["mycloud-nixos", "mycloud-nixos-2"]
        } ] }
    '';
  systemd.services.headscale.serviceConfig.TimeoutStopSec = "15s";


  services.tailscale = {
    enable = true;
  };

  age.secrets = {
    nextcloud_admin_pass = {
      file = ./nextcloud_admin_pass.age;
      owner = "nextcloud";
    };
    hetzner_private_key = {
      file = ./hetzner_private_key.age;
      owner = "root";
    };
    backblaze_env.file = ./backblaze_env.age;
    backblaze_repo.file = ./backblaze_repo.age;
    backblaze_password.file = ./backblaze_password.age;
  };
  services.nextcloud = {
    enable = true;                   
    package = pkgs_unstable.nextcloud29;
    hostName = "storage.romeov.me";
    https = true;
    config.adminpassFile = config.age.secrets.nextcloud_admin_pass.path;
    # config.adminpassFile = "/etc/nixos/nextcloud_pass";
    home="/storage/nextcloud";
  };

  services.onlyoffice = {
    enable = false;
    hostname = "localhost";
  };

  # services.immich = {
  #   enable = false;
  #   domain = "immich.romeov.me";
  #   port = 8006;
  #   metricsPortServer = 8009;
  #   metricsPortMicroservices = 8010;
  #   storagePath = "/mnt/storage-box/immich";
  #   logLevel = "log";
  # };

  services.invidious = let
    customVersions = {
      invidious = {
        rev = " eda7444ca46dbc3941205316baba8030fe0b2989";
        hash = "sha256-b673695aa2704b880562399ac78659ad23b7940d";
        version = "0.20.1-unstable-2024-04-26";
      };
      videojs.hash = "sha256-jED3zsDkPN8i6GhBBJwnsHujbuwlHdsVpVqa1/pzSH4=";
    };
    myInvidious = pkgs.invidious.overrideAttrs (oldAttrs: rec {
      versions = builtins.toJSON customVersions;
    });
  in {
      enable = false;
      port = 8090;
      settings.db.user = "invidious";
      package = pkgs_master.invidious;
  };

  services.syncthing = {
    enable = false;
    # user = "nextcloud";  # so that we can write to the WebDAV folders.
    # group = "nextcloud";  # so that we can write to the WebDAV folders.
  };


  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      80 
      443    
      # config.services.grafana.settings.server.http_port 
    ];
    trustedInterfaces = [
      "tailscale0"
    ];
    extraCommands = ''
      iptables -A INPUT -s 180.101.88.232 -j DROP
    '';

  };
  # Use nginx and ACME (Let's encrypt) to enable https
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "40M";
    virtualHosts = {
      # "localhost".listen = [ { addr = "127.0.0.1"; port = 8084; } ];
      "storage.romeov.me" = {
        ## Force HTTP redirect to HTTPS
        forceSSL = true;
        ## LetsEncrypt
        useACMEHost = "romeov.me";
      };
      "libreddit.romeov.me" = {
        ## Force HTTP redirect to HTTPS
        forceSSL = true;
        ## LetsEncrypt
        useACMEHost = "romeov.me";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8081";
        };
      };
      "nitter.romeov.me" = {
        ## Force HTTP redirect to HTTPS
        forceSSL = true;
        ## LetsEncrypt
        useACMEHost = "romeov.me";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8082";
        };
      };
      "headscale.romeov.me" = {
         ## Force HTTP redirect to HTTPS
         forceSSL = true;
         ## LetsEncrypt
         useACMEHost = "romeov.me";
         locations."/" = {
         proxyPass = "http://127.0.0.1:8083";
         proxyWebsockets = true;
        };
      };
      # "immich.romeov.me" = {
      #    ## Force HTTP redirect to HTTPS
      #    forceSSL = true;
      #    ## LetsEncrypt
      #    useACMEHost = "romeov.me";
      #    locations."/" = {
      #    proxyPass = "http://127.0.0.1:2283";
      #   };
      # };
      "gts.romeov.me" = with config.services.gotosocial.settings; {
        useACMEHost = "romeov.me";
        forceSSL = true;
        locations = {
          "/" = {
            recommendedProxySettings = true;
            proxyWebsockets = true;
            proxyPass = "http://${bind-address}:${toString port}";
          };
        };
      };
      # "grafana.romeov.me" = {
      #   locations."/" = {
      #       proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
      #       proxyWebsockets = true;
      #       recommendedProxySettings = true;
      #   };
      # };
      # "romeov.me" =  with config.services.gotosocial.settings; {
      "romeov.me" = {
        enableACME = true;
        forceSSL = true;
        locations = {
          "/" = {
            extraConfig = ''
                rewrite ^.*$ https://page.romeov.me permanent;
            '';
          };
          # "/.well-known/webfinger" = {
          #   extraConfig = ''
          #       rewrite ^.*$ https://gts.romeov.me/.well-known/webfinger permanent;
          #   '';
          # };
          # "/.well-known/host-meta" = {
          #   extraConfig = ''
          #     rewrite ^.*$ https://gts.romeov.me/.well-known/host-meta permanent;
          #   '';
          # };
          # "/.well-known/nodeinfo" = {
          #   extraConfig = ''
          #     rewrite ^.*$ https://gts.romeov.me/.well-known/nodeinfo permanent;
          #   '';
          # };

          # "/" = {
          #   recommendedProxySettings = true;
          #   proxyWebsockets = true;
          # };
          # "/well-known" = {
          #   recommendedProxySettings = true;
          #   proxyWebsockets = true;
          #   # globalRedirect = "gts.romeov.me";
          # };
        };
      };
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "contact@romeov.me";
    certs."romeov.me".extraDomainNames = [
     "gts.romeov.me"
     "headscale.romeov.me"
     "libreddit.romeov.me"
     "storage.romeov.me"
     "nitter.romeov.me"
     # "immich.romeov.me"
    ];
  };


  # Set up some logging
  services.grafana = {
    enable = false;
    # settings.server.domain = "grafana.romeov.me";
    settings.server.http_port = 3000;
    # settings.server.http_addr = "127.0.0.1;0.0.0.0";
    settings.server.http_addr = "0.0.0.0";
  };
  services.prometheus = {
    enable = false;
    port = 9001;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
    scrapeConfigs = [
      {
        job_name = "prometheus-collect-data";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];
  };

  services.restic.backups = {
    daily = {
      initialize = true;

      environmentFile = config.age.secrets."backblaze_env".path;
      repositoryFile = config.age.secrets."backblaze_repo".path;
      passwordFile = config.age.secrets."backblaze_password".path;

      paths = [
        "/etc/nixos"
        "/storage/immich"
        "/storage/nextcloud"
      ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
    };
  };


  ## system specific section
  ## probably I could/should move this to another file?
  # mount hetzner volume
#   fileSystems."/storage" =
#     { device = "/dev/disk/by-id/scsi-0HC_Volume_23527885";
#       fsType = "ext4";
#       neededForBoot = false;
#     };
  # systemd.mounts = [{
  #     description = "Storage Box (via rclone)";
  #     after = [ "network-online.target" ];
  #     what = "storage-box:";
  #     where = "/mnt/storage-box";
  #     type = "rclone";
  #     options = "rw,_netdev,allow_other,args2env,vfs-cache-mode=writes,log-level=DEBUG,config=/root/.config/rclone/rclone.conf,cache-dir=/var/rclone-cache";
  #   }];
    environment.etc."rclone-mnt.conf".text = ''
    [storage-box]
    type = sftp
    host = u380790.your-storagebox.de
    user = u380790
    port = 23
    key_file = /run/agenix/hetzner_private_key
    shell_type = unix
    md5sum_command = md5 -r
    sha1sum_command = sha1 -r
'';

    fileSystems."/mnt/storage-box" = {
      device = "storage-box:";
      fsType = "rclone";
      neededForBoot = false;
      options = [
        "nodev"
        "nofail"
        "allow_other"
        "args2env"
        "config=/etc/rclone-mnt.conf"
      ];
    };

    # fileSystems."/mnt/storage-box" = {
    #   device = "storage-box:";
    #   fsType = "rclone";
    #   neededForBoot = false;
    #   options = [
    #     "ro"
    #     "allow_other"
    #     "_netdev"
    #     "noauto"
    #     "x-systemd.automount"
    #     "x-systemd.idle-timeout=60"
    #
    #     # rclone specific
    #     "env.PATH=/run/wrappers/bin" # for fusermount3
    #     "config=/root/.config/rclone/rclone.conf"
    #     "cache_dir=/storage/cache/rclone-mount"
    #     "vfs-cache-mode=full"
    #   ];
    # };

}
