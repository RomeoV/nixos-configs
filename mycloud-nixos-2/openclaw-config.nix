{ config, pkgs, ... }: {
  # Debug: run `sudo openclaw-sandbox` to get a shell inside the gateway's sandbox.
  # Enters the service's mount/pid/net namespaces with the service's environment.
  environment.systemPackages = let
    sandbox = pkgs.writeShellScript "openclaw-sandbox-inner" ''
      PID=$1
      cd /var/lib/openclaw
      # Load the service's environment
      while IFS= read -r -d "" line; do
        export "$line"
      done < /proc/"$PID"/environ
      exec ${pkgs.bash}/bin/bash
    '';
  in [
    (pkgs.writeShellScriptBin "openclaw-sandbox" ''
      PID=$(systemctl show openclaw-gateway.service -p MainPID --value)
      if [ "$PID" = "0" ] || [ -z "$PID" ]; then
        echo "openclaw-gateway is not running" >&2
        exit 1
      fi
      exec nsenter -t "$PID" -m -u -i -n -p \
        ${pkgs.util-linux}/bin/setpriv --reuid=openclaw --regid=openclaw --init-groups \
        ${pkgs.bash}/bin/bash ${sandbox} "$PID"
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
    bash coreutils findutils gnugrep gnused gawk gzip
    nix git curl wget jq python3 uv
    himalaya khal pimsync tailscale bun
  ];

  # Mail access
  users.users.openclaw.extraGroups = [ "mailread" ];
  users.users.openclaw.shell = pkgs.bash;
  systemd.services.openclaw-gateway.serviceConfig.SupplementaryGroups = [ "mailread" ];
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
