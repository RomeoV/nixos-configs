{ config, ... }: {
  services.zeroclaw = {
    enable = true;
    apiKeyFile = config.age.secrets.zeroclaw-api-key.path;

    telegram = {
      enable = true;
      botTokenFile = config.age.secrets.zeroclaw-telegram-token.path;
      allowedUsers = [ "8593807304" ];
    };
  };
}
