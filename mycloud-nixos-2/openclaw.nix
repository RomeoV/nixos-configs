{ config, ... }: {
  services.openclaw = {
    enable = true;
    documents = ./openclaw-documents;

    providers.anthropic.apiKeyFile = config.age.secrets.openclaw-anthropic-key.path;

    providers.telegram = {
      enable = true;
      botTokenFile = config.age.secrets.openclaw-telegram-token.path;
      allowFrom = [ 8593807304 ];
    };

    gateway.auth.tokenFile = config.age.secrets.openclaw-gateway-token.path;
  };
}
