{ lib, ... }: {
  networking = {
    hostName = "mycloud-nixos-2";
    # domain = "romeov.me";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
        # config.services.grafana.settings.server.http_port
      ];
      trustedInterfaces = [
        "tailscale0"
      ];
      extraCommands = ''
          iptables -A INPUT -s 180.101.88.232 -j DROP
        '';
    };

    # The restwas populated at runtime with the networking
    # details gathered from the active system.
    nameservers = [ "2a01:4ff:ff00::add:2"
                    "2a01:4ff:ff00::add:1"
                    "185.12.64.1"
                  ];
    defaultGateway = "172.31.1.1";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="37.27.193.229"; prefixLength=32; }
        ];
        ipv6.addresses = [
          { address="2a01:4f9:c012:ef00::1"; prefixLength=64; }
          { address="fe80::9400:3ff:fe92:42e7"; prefixLength=64; }
        ];
        ipv4.routes = [ { address = "172.31.1.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = "fe80::1"; prefixLength = 128; } ];
      };
      
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="96:00:03:92:42:e7", NAME="eth0"
    
  '';

  services.fail2ban = {
    enable = true;  # although the wiki says nixos has a preconfigured ssh jail? Not sure what that means.
    bantime-increment = {
      enable = true;
      factor = "4";
    };
  };

  services.tailscale = {
    enable = true;
  };

  services.headscale = {
    enable = true;
    port = 8083;
    settings = {
      serverUrl = "https://headscale.romeov.me";
      acl_policy_path = "/etc/headscale/tailnet_policy_file.json";
      # dns_config = { baseDomain = "romeov.me"; };
      # logtail.enabled = false;
    };
  };
  environment.etc."headscale/tailnet_policy_file.json".text = ''
      { "acls": [ {
          "action": "accept",
          "src": ["*"],
          "dst": ["*:*"]
      } ],
        "ssh": [ {
            "action": "accept",
            "src": ["*"],
            "dst": ["mycloud-nixos"]
        } ] }
    '';
  systemd.services.headscale.serviceConfig.TimeoutStopSec = "15s";

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
         locations."/" = {
         proxyPass = "http://0.0.0.0:3001";
        };
      };
    };
  };
  security.acme = {
    acceptTerms = true;
    certs."immich.romeov.me".email = "contact@romeov.me";
  };
}
