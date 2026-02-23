{ config, pkgs, ... }: {
  # Debug: `sudo openclaw-sandbox` for interactive shell,
  # or `sudo openclaw-sandbox -c 'himalaya account list'` for one-off commands.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "openclaw-sandbox" ''
      PID=$(systemctl show openclaw-gateway.service -p MainPID --value)
      if [ "$PID" = "0" ] || [ -z "$PID" ]; then
        echo "openclaw-gateway is not running" >&2
        exit 1
      fi
      exec nsenter -t "$PID" -m -n \
        -S "$(id -u openclaw)" -G "$(id -g openclaw)" -- \
        env - $(${pkgs.coreutils}/bin/tr '\0' '\n' < /proc/"$PID"/environ | ${pkgs.gnused}/bin/sed "s/'/'\\\\''/g;s/^/'/;s/\$/'/" | ${pkgs.coreutils}/bin/tr '\n' ' ') \
        ${pkgs.bash}/bin/bash --norc --noprofile "$@"
    '')
  ];

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

  # Tools available to the agent
  systemd.services.openclaw-gateway.path = with pkgs; [
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
      backend.root-dir = "/mnt/storage-box/mail/stanford"
    '';
  in [
    "d /var/lib/openclaw/.config/himalaya 0750 openclaw openclaw -"
    "L+ /var/lib/openclaw/.config/himalaya/config.toml - - - - ${himalayaConfig}"
  ];
}
