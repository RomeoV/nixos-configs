{ config, pkgs, lib, ... }: {
  services.openclaw = {
    enable = true;
    domain = "";           # No Caddy — Tailscale only
    openFirewall = false;

    modelProvider = "anthropic";
    modelApiKeyFile = config.age.secrets.openclaw-api-key.path;

    telegram = {
      enable = true;
      tokenFile = config.age.secrets.openclaw-telegram-token.path;
    };

    toolSecurity = "allowlist";
    toolAllowlist = [
      "read" "write" "edit"
      "web_search" "web_fetch"
      "message" "tts"
      "exec"
    ];
  };

  # Upstream module bugs: wrong ExecStart, missing EnvironmentFile/secrets,
  # missing AF_NETLINK, missing tool PATH and HOME.
  systemd.services.openclaw-gateway = {
    path = with pkgs; [
      bash coreutils findutils gnugrep gnused gawk gzip
      nix git curl wget jq python3 uv
      himalaya khal pimsync tailscale bun
    ];
    serviceConfig = {
      ExecStart = lib.mkForce "${pkgs.openclaw}/bin/openclaw gateway";
      RestrictAddressFamilies = lib.mkForce [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];
      EnvironmentFile = [
        config.age.secrets.openclaw-api-key.path
        config.age.secrets.openclaw-telegram-token.path
      ];
      BindReadOnlyPaths = [
        "/var/lib/mailsync/stanford"
        "/mnt/storage-box/mail/stanford"
      ];
    };
    environment = {
      HOME = "/var/lib/openclaw";
      OPENCLAW_CONFIG_PATH = "/var/lib/openclaw/openclaw.json";
      NIX_PATH = "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos";
    };
  };

  # Mail access
  users.users.openclaw.extraGroups = [ "mailread" ];
  users.users.openclaw.shell = pkgs.bash;  # Need a real shell for command execution

  # Himalaya config for mail reading
  systemd.tmpfiles.rules = let
    himalayaConfig = pkgs.writeText "himalaya-config.toml" ''
      [accounts.stanford]
      default = true
      email = "romeov@stanford.edu"
      folder.aliases.inbox = "Inbox"
      backend.type = "maildir"
      backend.root-dir = "/var/lib/mailsync/stanford"
    '';
  in [
    "d /var/lib/openclaw/.config/himalaya 0750 openclaw openclaw -"
    "L+ /var/lib/openclaw/.config/himalaya/config.toml - - - - ${himalayaConfig}"
  ];
}
