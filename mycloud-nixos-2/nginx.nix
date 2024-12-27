{ config, ... }: {
  # Use nginx and ACME (Let's encrypt) to enable https
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "40M";
    virtualHosts = {
      "immich.romeov.me" = {
         enableACME = true;
         forceSSL = true;
         acmeRoot = null;
         locations."/" = {
           proxyPass = "http://localhost:${toString config.services.immich.port}";
        };
        extraConfig = ''
          client_max_body_size 1G;
        '';
      };
      "redlib.romeov.me" = {
         enableACME = true;
         forceSSL = true;
         locations."/" = {
           proxyPass = "http://localhost:${toString config.services.redlib.port}";
        };
      };
      "disentangling-sbucaptions.romeov.me" = {
          # useACMEHost = "romeov.me";
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.sbucaptions-webserver.port}";
          };
      };
      "headscale.romeov.me" = let
          hostname = config.services.headscale.address;
          port = toString config.services.headscale.port;
        in {
         forceSSL = true;
         enableACME = true;
         locations."/" = {
           proxyPass = "http://${hostname}:${port}";
           proxyWebsockets = true;
        };
      };
      # "mlflow.${toString config.networking.hostName}" = {
      #   enableACME = false;
      #   forceSSL = false;
      #   locations."/" = {
      #     proxyPass = "http://localhost:${toString config.services.mlflow-server.port}";
      #   };
      # };

      # "headscale.romeov.me" = {
      #    enableACME = true;
      #    forceSSL = true;
      #    locations."/" = {
      #      proxyPass = "http://localhost:${toString config.services.headscale.port}";
      #   };
      # };
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "contact@romeov.me";
      dnsProvider = "porkbun";
      credentialsFile = config.age.secrets.porkbun-secret-api-key-both.path;
    };
  };
}
