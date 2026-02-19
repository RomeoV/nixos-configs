{ config, pkgs, ... }: {
  services.zeroclaw = {
    enable = true;
    apiKeyFile = config.age.secrets.zeroclaw-api-key.path;
    model = "claude-sonnet-4-6";

    enableCli = true;
    extraPackages = [ pkgs.git pkgs.uv pkgs.python3 ];
    extraAllowedCommands = [ "uv" "python3" ];
    extraEnvironment.UV_PYTHON_PREFERENCE = "only-system";

    telegram = {
      enable = true;
      botTokenFile = config.age.secrets.zeroclaw-telegram-token.path;
      allowedUsers = [ "8593807304" ];
    };
  };
}
