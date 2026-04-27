# mycloud-nixos: older server, currently OFF (cpx11 in ash).
# Cleaned up from channel-based config to work with flakes.
{ config, pkgs, pkgs-unstable, ... }: {
  imports = [
    ../../modules/base.nix
    ../../modules/hetzner.nix
    ./hardware-configuration.nix
    ./networking.nix
  ];

  system.stateVersion = "22.05";
  networking.hostName = "mycloud-nixos";
  networking.domain = "romeov.me";

  nix.settings.allowed-users = [ "root" ];

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    randomizedDelaySec = "10min";
    dates = "Mon,Fri 04:40";
  };

  environment.systemPackages = with pkgs; [
    headscale
    waypipe
    redlib
  ];

  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    trustedInterfaces = [ "tailscale0" ];
    extraCommands = ''
      iptables -A INPUT -s 180.101.88.232 -j DROP
    '';
  };

  # -- Secrets --
  age.secrets = {
    nextcloud_admin_pass = {
      file = ../../secrets/nextcloud_admin_pass.age;
      owner = "nextcloud";
    };
    hetzner_private_key = {
      file = ../../secrets/hetzner_private_key.age;
      owner = "root";
    };
    backblaze_env.file = ../../secrets/backblaze_env.age;
    backblaze_repo.file = ../../secrets/backblaze_repo.age;
    backblaze_password.file = ../../secrets/backblaze_password.age;
    porkbun-secret-api-key-both.file = ../../secrets/porkbun-secret-api-key-both.age;
  };

  # -- Services --
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

  services.gotosocial = {
    enable = true;
    settings.host = "gts.romeov.me";
    settings.port = 8089;
  };

  services.headscale = {
    enable = true;
    port = 8083;
    settings = {
      serverUrl = "https://headscale.romeov.me";
      acl_policy_path = "/etc/headscale/tailnet_policy_file.json";
    };
  };
  systemd.services.headscale.environment.HEADSCALE_EXPERIMENTAL_FEATURE_SSH = "1";
  systemd.services.headscale.serviceConfig.TimeoutStopSec = "15s";
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

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud30;
    hostName = "storage.romeov.me";
    https = true;
    config.adminpassFile = config.age.secrets.nextcloud_admin_pass.path;
    home = "/storage/nextcloud";
  };

  # -- Nginx + ACME --
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "40M";
    virtualHosts = {
      "storage.romeov.me" = {
        forceSSL = true;
        useACMEHost = "romeov.me";
      };
      "libreddit.romeov.me" = {
        forceSSL = true;
        useACMEHost = "romeov.me";
        locations."/".proxyPass = "http://127.0.0.1:8081";
      };
      "headscale.romeov.me" = {
        forceSSL = true;
        useACMEHost = "romeov.me";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8083";
          proxyWebsockets = true;
        };
      };
      "disentangling-sbucaptions.romeov.me" = {
        forceSSL = true;
        useACMEHost = "romeov.me";
        locations."/".proxyPass = "http://100.64.0.10:8096";
      };
      "gts.romeov.me" = with config.services.gotosocial.settings; {
        useACMEHost = "romeov.me";
        forceSSL = true;
        locations."/" = {
          recommendedProxySettings = true;
          proxyWebsockets = true;
          proxyPass = "http://${bind-address}:${toString port}";
        };
      };
      "romeov.me" = {
        enableACME = true;
        forceSSL = true;
        locations."/".extraConfig = ''
          rewrite ^.*$ https://page.romeov.me permanent;
        '';
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
    ];
  };

  # -- Backups --
  services.restic.backups.daily = {
    initialize = true;
    environmentFile = config.age.secrets."backblaze_env".path;
    repositoryFile = config.age.secrets."backblaze_repo".path;
    passwordFile = config.age.secrets."backblaze_password".path;
    paths = [ "/etc/nixos" "/storage/immich" "/storage/nextcloud" ];
    pruneOpts = [ "--keep-daily 7" "--keep-weekly 5" "--keep-monthly 12" ];
  };

  # -- Storage --
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
    options = [ "nodev" "nofail" "allow_other" "args2env" "config=/etc/rclone-mnt.conf" ];
  };
}
