{ config, pkgs, pkgs-small, lib, ... }: {
  imports = [ ./openclaw-sandbox.nix ];

  services.openclaw = {
    enable = true;
    package = pkgs-small.openclaw;
    domain = "";           # No Caddy — Tailscale only
    openFirewall = false;

    modelProvider = "openrouter";
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
      "exec" "emacs"
    ];
  };

  # Tools available to the agent (via user profile so the exec tool can find them)
  users.users.openclaw.packages = with pkgs; [
    bash which coreutils findutils gnugrep gnused gawk gzip
    nix git curl wget jq python3 uv
    himalaya khal pimsync tailscale typst bun
    cron
  ];

  # Mail access
  users.users.openclaw.extraGroups = [ "mailread" ];
  users.users.openclaw.shell = pkgs.bash;
  systemd.services.openclaw-gateway.unitConfig.RequiresMountsFor = "/mnt/mail-storage";
  systemd.services.openclaw-gateway.serviceConfig.Restart = lib.mkForce "always";
  systemd.services.openclaw-gateway.serviceConfig.SupplementaryGroups = [ "mailread" ];
  systemd.services.openclaw-gateway.serviceConfig.BindReadOnlyPaths = [
    "/mnt/mail-storage/stanford"
  ];

  # Himalaya config for mail reading
  systemd.tmpfiles.rules = let
    himalayaConfig = pkgs.writeText "himalaya-config.toml" ''
      [accounts.stanford]
      default = true
      email = "romeov@stanford.edu"
      folder.aliases.inbox = "Inbox"
      backend.type = "maildir"
      backend.root-dir = "/mnt/mail-storage/stanford"
    '';
  in [
    # Allow syncthing (in openclaw group) to traverse to .openclaw/workspace
    "d /var/lib/openclaw              0750 openclaw openclaw -"
    "d /var/lib/openclaw/.openclaw    0750 openclaw openclaw -"
    "d /var/lib/openclaw/.openclaw/workspace 2770 openclaw openclaw -"
    "d /var/lib/openclaw/.config/himalaya 0750 openclaw openclaw -"
    "L+ /var/lib/openclaw/.config/himalaya/config.toml - - - - ${himalayaConfig}"
  ];
}
