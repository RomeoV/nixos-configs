{ config, pkgs, ... }:
let
  himalayaConfig = pkgs.writeText "himalaya-config.toml" ''
    [accounts.stanford]
    default = true
    email = "romeov@stanford.edu"
    folder.aliases.inbox = "Inbox"
    backend.type = "maildir"
    backend.root-dir = "/var/lib/mailsync/stanford"
  '';
in {
  # Grant zeroclaw read-only access to synced mail
  users.users.zeroclaw.extraGroups = [ "mailread" ];

  # Place himalaya config at zeroclaw's default XDG path
  systemd.tmpfiles.rules = [
    "d /var/lib/zeroclaw/.config/himalaya 0750 zeroclaw zeroclaw -"
    "L+ /var/lib/zeroclaw/.config/himalaya/config.toml - - - - ${himalayaConfig}"
  ];

  services.zeroclaw = {
    enable = true;
    apiKeyFile = config.age.secrets.zeroclaw-api-key.path;
    model = "claude-sonnet-4-6";

    enableCli = true;
    autonomyLevel = "full";
    blockHighRiskCommands = false;
    workspaceOnly = false;
    enforceCommandAllowlist = false;
    extraPackages = [ pkgs.uv pkgs.python3 pkgs.pimsync pkgs.khal pkgs.himalaya ];

    telegram = {
      enable = true;
      botTokenFile = config.age.secrets.zeroclaw-telegram-token.path;
      allowedUsers = [ "8593807304" ];
    };
  };
}
