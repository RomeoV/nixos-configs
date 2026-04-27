# Machine-specific system config for mycloud-nixos-2.
# Shared config (SSH, audit, packages, etc.) lives in modules/base.nix.
{ pkgs, config, rootPath, isdPkgs, ... }: {
  system.stateVersion = "24.05";

  nix.settings.allowed-users = [ "root" "openclaw" ];

  system.autoUpgrade = {
    enable = true;
    flake = "path:${rootPath}";
    flags = [
      "--update-input"
      "nixpkgs"
      "--update-input"
      "agenix"
      "--no-write-lock-file"
      "-L"
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  programs.ssh.extraConfig = ''
  Host github
    AddKeysToAgent yes
    Hostname github.com
    IdentitiesOnly yes
    IdentityFile '' + config.age.secrets.github-key.path + ''

  '';

  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    headscale
    cifs-utils
    waypipe
    redlib
    dust
    isdPkgs.isd
  ];

  fonts.packages = with pkgs; [
    source-serif-pro source-sans-pro source-code-pro
    inter fira fira-code roboto roboto-slab
    libertinus eb-garamond lato merriweather
    carlito liberation_ttf corefonts
  ];

  services.restic.backups = {
    daily = {
      initialize = true;
      environmentFile = config.age.secrets."backblaze_env_2".path;
      repositoryFile = config.age.secrets."backblaze_repo_2".path;
      passwordFile = config.age.secrets."backblaze_password_2".path;
      paths = [
        "/mnt/storage-box/immich"
        "/mnt/mail-storage"
        "/var/lib"
      ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/syncthing 0750 syncthing syncthing -"
    "d /home/syncthing/todo_notes 0770 syncthing syncthing -"
  ];
}
