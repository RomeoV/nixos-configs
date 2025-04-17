{ nixpkgs-unstable, config, pkgs, ... }: {
  # Use nginx and ACME (Let's encrypt) to enable https
  users.users.nginx.extraGroups = [ config.users.groups.anubis.name ];
  services.anubis.instances.redlib.settings.TARGET = "http://localhost:${toString config.services.redlib.port}";
  services.anubis.package = nixpkgs-unstable.legacyPackages.${config.nixpkgs.system}.anubis;
  services.anubis.defaultOptions.settings.DIFFICULTY = 4;

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "40M";
    virtualHosts = {
      "immich.romeov.me" = {
         enableACME = true;
         forceSSL = true;
         # acmeRoot = null;
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
           proxyPass = "http://unix:${config.services.anubis.instances.redlib.settings.BIND}";
        };
      };
      "disentangling-sbucaptions.romeov.me" = let
          port = toString config.services.sbucaptions-webserver.port;
        in {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:${port}";
          };
      };
      "disentangling-sbucaptions.xyz" = let
          port = toString config.services.sbucaptions-webserver.port;
        in {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:${port}";
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
      # "nextcloud" = {
      #   listen = [
      #     { addr = "0.0.0.0"; port=8086; }
      #   ];
      # };
      "agenda.romeov.me" = {
        root = "/var/www/todos";
        basicAuthFile = "/run/nginx/agenda-auth-file";
        forceSSL = true;
        enableACME = true;

        # Redirect from / to /todos
        locations."/" = {
          return = "301 /todos";
        };

        # Serve the todos page
        locations."/todos" = {
          index = "index.html";
          tryFiles = "$uri $uri/index.html $uri/ =404";
        };

        # Serve the agenda page
        locations."/agenda" = {
          index = "index.html";
          tryFiles = "$uri $uri/index.html $uri/ =404";
        };
      };
      # "mlflow.${toString config.networking.hostName}" = {
      #   enableACME = false;
      #   forceSSL = false;
      #   locations."/" = {
      #     proxyPass = "http://localhost:${toString config.services.mlflow-server.port}";
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


  systemd.services.nginx-agenda-auth-file = {
    description = "Generate Nginx agenda auth file";
    wantedBy = [ "nginx.service" ];
    before = [ "nginx.service" ];
    after = [ "agenix.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      Group = config.users.groups.keys.name;
    };

    script = ''
    # Read the plaintext password
    PASSWORD=$(cat ${config.age.secrets.agenda-password.path})

    # Create auth file using htpasswd
    mkdir -p /run/nginx
    echo "$PASSWORD" | ${pkgs.apacheHttpd}/bin/htpasswd -i -c /run/nginx/agenda-auth-file user

    # Make it readable by nginx
    chown nginx:nginx /run/nginx/agenda-auth-file
    chmod 400 /run/nginx/agenda-auth-file
  '';
  };


}
