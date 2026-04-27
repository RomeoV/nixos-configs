{ config, pkgs, ... }:
let
  tailscaleIp = "100.64.0.10";
  tsListen = [{ addr = tailscaleIp; port = 80; }];
in {
  users.users.nginx.extraGroups = [ config.users.groups.anubis.name ];
  services.anubis.instances.redlib.settings.TARGET = "http://localhost:${toString config.services.redlib.port}";
  services.anubis.defaultOptions.settings.DIFFICULTY = 4;

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    clientMaxBodySize = "40M";
    virtualHosts = {
      # ── Public (ACME TLS) ──────────────────────────────────────────
      "immich.romeov.me" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.immich.port}";
          proxyWebsockets = true;
        };
        extraConfig = "client_max_body_size 0;";
      };
      "redlib.romeov.me" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://unix:/run/anubis/anubis-redlib/anubis.sock";
      };
      "disentangling-sbucaptions.romeov.me" = let port = toString config.services.sbucaptions-webserver.port; in {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://localhost:${port}";
      };
      "disentangling-sbucaptions.xyz" = let port = toString config.services.sbucaptions-webserver.port; in {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://localhost:${port}";
      };
      "headscale.romeov.me" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://${config.services.headscale.address}:${toString config.services.headscale.port}";
          proxyWebsockets = true;
        };
      };

      # ── Tailscale-only (plain HTTP on headscale IP) ────────────────
      "storage.mycloud".listen = tsListen;
      "freshrss.mycloud".listen = tsListen;
      "blog.mycloud" = {
        listen = tsListen;
        root = "/var/lib/blog/www";
        extraConfig = "gzip_static on;";
      };
      "openclaw.mycloud" = {
        listen = tsListen;
        locations."/" = {
          proxyPass = "http://localhost:18789";
          proxyWebsockets = true;
        };
      };
      "immich.mycloud" = {
        listen = tsListen;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.immich.port}";
          proxyWebsockets = true;
        };
        extraConfig = "client_max_body_size 0;";
      };
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
      PASSWORD=$(cat ${config.age.secrets.agenda-password.path})
      mkdir -p /run/nginx
      echo "$PASSWORD" | ${pkgs.apacheHttpd}/bin/htpasswd -i -c /run/nginx/agenda-auth-file user
      chown nginx:nginx /run/nginx/agenda-auth-file
      chmod 400 /run/nginx/agenda-auth-file
    '';
  };
}
