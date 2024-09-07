{ inputs, pkgs, pkgs-unstable, agenix, config, ... }: {

  system.stateVersion = "24.05";

  nix.settings.experimental-features = "nix-command flakes";
  # nix.allowedUsers = [ "@wheel" ];
  nix.settings.allowed-users = [ "root" ];

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Los_Angeles";

  # see https://discourse.nixos.org/t/best-practices-for-auto-upgrades-of-flake-enabled-nixos-systems/31255/2
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "--update-input"
      "nixpkgs-unstable"
      "--update-input"
      "agenix"
      "--update-input"
      "nixpkgs-immich"
      "--no-write-lock-file"
      "-L" # print build logs
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 90d";
  };
  services.journald.extraConfig = "SystemMaxUse=1000M";

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIzDCdxCAPnbdzwkKpp/9AUGMyABSPj/vZffRQoojdHh6Ct+9fZ60vYOS9NaQy9bqdagC0bHrrBvELiTqbAj5E3I1E7Mfp2BXjI/ig+NTlp0SIoaXnlLRNxnb+TSEDuAdqMdgwjxuy63T5PK04e7AH24NQ8J9sF16QAu0A0VurZEzPTLVZIoFCr/qmxZLnsJELdAtmnxCf+ZlBSs+v0qWOibOQ1mgKecii+0hRPSDpmY62FI++AzNoeVJ4j0ObSC/hpLMYkF5DJSkwaD+4+7CDLFhHdIQ5AzZNZp4gS2IESGUVTbUhXHm0YOr/xj66ZLqDzA16F+dSkKrnfRyTGrjdeWNsMTy42W42wEK1FhbHfsg4AQtT7S3kyiKS0lUFPdH34Q6iiTShTtySDCPW46hEp97sYshZ2aSDAIKYRty3mODPZlM12LL6z1bgbte6bsI3JN0nbIULemfgVqlZAHRDpCv05muEi4IPzYdDxMutAN8zNcMz3IyVoRQ/2bw2kds=" 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcP5JDW+JKSD04YGd+giu8oGCVGKjh7ZSap0UbNUYhP JuiceSSH"
  ];

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
        customRC = ''set nowrap'';
      };
    };
  };

  environment.systemPackages = [
      agenix.default
      pkgs.helix
      pkgs.headscale
      pkgs.rclone
      pkgs.bottom
      pkgs.waypipe
      pkgs-unstable.redlib
      (pkgs.callPackage ./my-mlflow-server.nix {})
  ];


  age.secrets = {
    nextcloud_admin_pass = {
      file = agenix/nextcloud_admin_pass.age;
      owner = "nextcloud";
    };
    hetzner_private_key = {
      file = agenix/hetzner_private_key.age;
      owner = "root";
    };
    backblaze_env_2.file = agenix/backblaze_env_2.age;
    backblaze_repo_2.file = agenix/backblaze_repo_2.age;
    backblaze_password_2.file = agenix/backblaze_password_2.age;
    mlflow-artifacts-key.file = agenix/mlflow-artifacts-key.age;
    paperless-admin-password.file = agenix/paperless-admin-password.age;
  };


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

  services.restic.backups = {
    daily = {
      initialize = true;

      environmentFile = config.age.secrets."backblaze_env_2".path;
      repositoryFile = config.age.secrets."backblaze_repo_2".path;
      passwordFile = config.age.secrets."backblaze_password_2".path;

      paths = [
        "/mnt/storage-box/immich"
        "/var/lib"
      ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
    };
  };
}
