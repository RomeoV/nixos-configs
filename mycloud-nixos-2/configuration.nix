{ config, lib, pkgs, pkgs-unstable, nixpkgs, nixpkgs-unstable, agenix, ... }: {
  imports =   [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
    # (import /etc/nixos/redlib_service.nix {inherit lib config pkgs_unstable; })
    # (import /etc/nixos/immich.nix {inherit lib config pkgs_unstable; })
  ];

  system.stateVersion = "24.05";

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
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 90d";
  };
  services.journald.extraConfig = "SystemMaxUse=1000M";

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "mycloud-nixos-2";
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
      # (pkgs.callPackage <agenix/pkgs/agenix.nix> {})
      agenix.default
      pkgs.helix
      pkgs.headscale
      pkgs.rclone
      pkgs.bottom
      # pkgs.onlyoffice-documentserver
      # pkgs.docker-compose  
      # pkgs.podman-compose
      pkgs.waypipe
      pkgs-unstable.redlib
  ];

  # services.redlib = {
  #   enable = true;
  #   address = "127.0.0.1";
  #   port = 8081;
  # };
  # systemd.services.redlib.environment = {
  #   REDLIB_DEFAULT_SHOW_NSFW = "on";
  #   REDLIB_DEFAULT_USE_HLS = "on";
  #   REDLIB_DEFAULT_HIDE_HLS_NOTIFICATION = "on";
  #   REDLIB_DEFAULT_AUTOPLAY_VIDEOS = "on";
  # };

  services.gotosocial = {
    enable = true;
    # setupPostgresqlDB = true;
    settings.host = "gts.romeov.me";
    settings.port = 8089;
    # storage-local-base-path = "/storage/gotosocial";
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
  environment.etc."headscale/tailnet_policy_file.json".text = ''
      { "acls": [ {
     	    "action": "accept",
     	    "src": ["*"],
     	    "dst": ["*:*"]
     	} ],
        "ssh": [ {
            "action": "accept",
            "src": ["*"],
            "dst": ["mycloud-nixos"]
        } ] }
    '';
  systemd.services.headscale.serviceConfig.TimeoutStopSec = "15s";


  services.tailscale = {
    enable = true;
  };

  # age.secrets = {
  #   nextcloud_admin_pass = {
  #     file = ./nextcloud_admin_pass.age;
  #     owner = "nextcloud";
  #   };
  #   hetzner_private_key = {
  #     file = ./hetzner_private_key.age;
  #     owner = "root";
  #   };
  #   backblaze_env.file = ./backblaze_env.age;
  #   backblaze_repo.file = ./backblaze_repo.age;
  #   backblaze_password.file = ./backblaze_password.age;
  # };

  # services.nextcloud = {
  #   enable = true;
  #   package = pkgs.nextcloud28;
  #   hostName = "storage.romeov.me";
  #   https = true;
  #   config.adminpassFile = config.age.secrets.nextcloud_admin_pass.path;
  #   # config.adminpassFile = "/etc/nixos/nextcloud_pass";
  #   home="/storage/nextcloud";
  # };

  # services.invidious = let
  #   customVersions = {
  #     invidious = {
  #       rev = " eda7444ca46dbc3941205316baba8030fe0b2989";
  #       hash = "sha256-b673695aa2704b880562399ac78659ad23b7940d";
  #       version = "0.20.1-unstable-2024-04-26";
  #     };
  #     videojs.hash = "sha256-jED3zsDkPN8i6GhBBJwnsHujbuwlHdsVpVqa1/pzSH4=";
  #   };
  #   myInvidious = pkgs.invidious.overrideAttrs (oldAttrs: rec {
  #     versions = builtins.toJSON customVersions;
  #   });
  # in {
  #     enable = true;
  #     port = 8090;
  #     settings.db.user = "invidious";
  #     package = pkgs_master.invidious;
  # };


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



  # # Set up some logging
  # services.grafana = {
  #   enable = true;
  #   # settings.server.domain = "grafana.romeov.me";
  #   settings.server.http_port = 3000;
  #   # settings.server.http_addr = "127.0.0.1;0.0.0.0";
  #   settings.server.http_addr = "0.0.0.0";
  # };
  # services.prometheus = {
  #   enable = true;
  #   port = 9001;
  #   exporters = {
  #     node = {
  #       enable = true;
  #       enabledCollectors = [ "systemd" ];
  #       port = 9002;
  #     };
  #   };
  #   scrapeConfigs = [
  #     {
  #       job_name = "prometheus-collect-data";
  #       static_configs = [{
  #         targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
  #       }];
  #     }
  #   ];
  # };

  # services.restic.backups = {
  #   daily = {
  #     initialize = true;

  #     environmentFile = config.age.secrets."backblaze_env".path;
  #     repositoryFile = config.age.secrets."backblaze_repo".path;
  #     passwordFile = config.age.secrets."backblaze_password".path;

  #     paths = [
  #       "/etc/nixos"
  #       "/storage/immich"
  #       "/storage/nextcloud"
  #     ];

  #     pruneOpts = [
  #       "--keep-daily 7"
  #       "--keep-weekly 5"
  #       "--keep-monthly 12"
  #     ];
  #   };
  # };
}
