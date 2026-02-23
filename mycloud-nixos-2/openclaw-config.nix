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

  # Node.js needs AF_NETLINK for os.networkInterfaces()
  systemd.services.openclaw-gateway.serviceConfig.RestrictAddressFamilies =
    lib.mkForce [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];

  # Mail access
  users.users.openclaw.extraGroups = [ "mailread" ];
  systemd.services.openclaw-gateway.serviceConfig.BindReadOnlyPaths = [
    "/var/lib/mailsync/stanford"
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
