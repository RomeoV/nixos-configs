{ config, pkgs, ... }: {
  # Grant zeroclaw read-only access to synced mail
  users.users.zeroclaw.extraGroups = [ "mailread" ];

  services.zeroclaw = {
    enable = true;
    apiKeyFile = config.age.secrets.zeroclaw-api-key.path;
    model = "claude-sonnet-4-6";

    enableCli = true;
    autonomyLevel = "full";
    blockHighRiskCommands = false;
    workspaceOnly = false;
    enforceCommandAllowlist = false;
    extraPackages = [ pkgs.uv pkgs.python3 pkgs.pimsync pkgs.khal ];
    extraEnvironment.UV_PYTHON_PREFERENCE = "only-system";

    telegram = {
      enable = true;
      botTokenFile = config.age.secrets.zeroclaw-telegram-token.path;
      allowedUsers = [ "8593807304" ];
    };
  };
}
