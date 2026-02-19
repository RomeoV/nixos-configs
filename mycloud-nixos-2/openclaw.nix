# Workaround: use explicit instance because top-level providers.telegram
# is missing `groups` option (bug in NixOS module, PR #24).
{ config, ... }: {
  services.openclaw = {
    enable = true;
    documents = ./openclaw-documents;
    gateway.auth.tokenFile = config.age.secrets.openclaw-gateway-token.path;

    instances.default = {
      providers.anthropic.apiKeyFile = config.age.secrets.openclaw-anthropic-key.path;
      providers.telegram = {
        enable = true;
        botTokenFile = config.age.secrets.openclaw-telegram-token.path;
        allowFrom = [ 8593807304 ];
      };
      gateway.auth.tokenFile = config.age.secrets.openclaw-gateway-token.path;
    };
  };
}
