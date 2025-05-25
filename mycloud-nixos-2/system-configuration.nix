{ pkgs
, agenix
, config
, rootPath
, isdPkgs
, agendaExporter
, lib
, ... }: {
  system.stateVersion = "24.05";

  nix.settings.experimental-features = "nix-command flakes";
  # nix.allowedUsers = [ "@wheel" ];
  nix.settings.allowed-users = [ "root" ];

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Los_Angeles";

  # see https://discourse.nixos.org/t/best-practices-for-auto-upgrades-of-flake-enabled-nixos-systems/31255/2
  # and https://github.com/NixOS/nixpkgs/issues/349734
  system.autoUpgrade = {
    enable = true;
    flake = "path:${rootPath}";
    flags = [
      "--update-input"
      "nixpkgs"
      # "--update-input"
      # "nixpkgs-unstable"
      "--update-input"
      "agenix"
      "--no-write-lock-file"
      "-L" # print build logs
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 45d";
  };
  services.journald.extraConfig = "SystemMaxUse=1G";

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  services.openssh.enable = true;
  services.openssh.extraConfig = ''
    AllowAgentForwarding yes
  '';
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIzDCdxCAPnbdzwkKpp/9AUGMyABSPj/vZffRQoojdHh6Ct+9fZ60vYOS9NaQy9bqdagC0bHrrBvELiTqbAj5E3I1E7Mfp2BXjI/ig+NTlp0SIoaXnlLRNxnb+TSEDuAdqMdgwjxuy63T5PK04e7AH24NQ8J9sF16QAu0A0VurZEzPTLVZIoFCr/qmxZLnsJELdAtmnxCf+ZlBSs+v0qWOibOQ1mgKecii+0hRPSDpmY62FI++AzNoeVJ4j0ObSC/hpLMYkF5DJSkwaD+4+7CDLFhHdIQ5AzZNZp4gS2IESGUVTbUhXHm0YOr/xj66ZLqDzA16F+dSkKrnfRyTGrjdeWNsMTy42W42wEK1FhbHfsg4AQtT7S3kyiKS0lUFPdH34Q6iiTShTtySDCPW46hEp97sYshZ2aSDAIKYRty3mODPZlM12LL6z1bgbte6bsI3JN0nbIULemfgVqlZAHRDpCv05muEi4IPzYdDxMutAN8zNcMz3IyVoRQ/2bw2kds=" 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcP5JDW+JKSD04YGd+giu8oGCVGKjh7ZSap0UbNUYhP JuiceSSH"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJbduBCVxs/ZTKkHXdGZ0LIzj0cUWvdLtmLcWO3ZA3I/AAAABHNzaDo= romeo@Romeo-P1"
  ];
  programs.ssh.extraConfig = ''
  Host github
    AddKeysToAgent yes
    Hostname github.com
    IdentitiesOnly yes
    IdentityFile '' + config.age.secrets.github-key.path + ''

  '';

  # see https://xeiaso.net/blog/paranoid-nixos-2021-07-18/, "Audit tracing"
  security.auditd.enable = true;
  security.audit.enable = true;
  security.audit.rules = [
    "-a exit,always -F arch=b64 -S execve"
  ];
  services.logrotate = {
    enable = true;
    settings = {
      header = {
        dateext = true;
      };
      "/var/log/audit/audit.log" = {
        frequency = "monthly";  # this is also the default
        rotate = 3;
      };
    };
  };

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
      pkgs.redlib
      # pkgs.mlflow-server
      pkgs.du-dust
      isdPkgs.isd
  ];

  services.netdata.enable = false;

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

  users.users.agenda-exporter = {
    isSystemUser = true;
    group = "agenda-exporter";
    description = "User for exporting org todos to HTML";
    extraGroups = [ "syncthing" ];
  };
  # Create a matching group
  users.groups.agenda-exporter = {};

  systemd.tmpfiles.rules = [
    "d /var/www/todos/todos 0755 agenda-exporter agenda-exporter -"
    "d /var/www/todos/agenda 0755 agenda-exporter agenda-exporter -"
    "d /home/syncthing 0750 syncthing syncthing -"
    "d /home/syncthing/todo_notes 0770 syncthing syncthing -"
  ];

  systemd.services.export-agenda = {
    description = "Export todos from org to HTML";
    startAt = "5min";

    unitConfig = {
      StartLimitIntervalSec = 60;
      StartLimitBurst = 3;
    };

    serviceConfig = {
      Type = "oneshot";
      User = "agenda-exporter";
      RestartSec = "30sec";
      Restart = "on-failure";
      ProtectSystem = "strict";
      ProtectHome = false;  # Allow access to /home
      ReadWritePaths = [
        "/var/www/todos"
        "/home/syncthing/todo_notes"
      ];
      PrivateTmp = true;  # This gives the service its own isolated /tmp
    };

    # Use the executable path directly from your app definition
    script = ''
      ${lib.getExe agendaExporter.default}
    '';
  };
  systemd.paths.export-agenda = {
    description = "Watch for changes in todo files";
    wantedBy = [ "multi-user.target" ];

    # Specify which file(s) to watch
    pathConfig = {
      PathChanged = "/home/syncthing/todo_notes/todo.org";
      # Set a timeout to prevent rapid triggers
      Unit = "export-agenda.service";
    };
  };

}
