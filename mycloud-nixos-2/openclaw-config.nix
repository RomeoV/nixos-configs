{ config, pkgs, ... }: {
  imports = [ ./openclaw-sandbox.nix ];

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

  # Tools available to the agent (via user profile so the exec tool can find them)
  users.users.openclaw.packages = with pkgs; [
    bash which coreutils findutils gnugrep gnused gawk gzip
    nix git curl wget jq python3 uv
    himalaya khal pimsync tailscale bun
  ];

  # Mail access
  users.users.openclaw.extraGroups = [ "mailread" ];
  users.users.openclaw.shell = pkgs.bash;
  systemd.services.openclaw-gateway.serviceConfig.SupplementaryGroups = [ "mailread" ];
  systemd.services.openclaw-gateway.serviceConfig.BindReadOnlyPaths = [
    "/mnt/storage-box/mail/stanford"
  ];

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
