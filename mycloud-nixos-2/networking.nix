{ lib, config, ... }: {
  networking = {
    hostName = "mycloud-nixos-2";
    # domain = "romeov.me";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
        22000  # syncthing: TCP and/or UDP for sync traffic, see https://wiki.nixos.org/wiki/Syncthing
        # config.services.grafana.settings.server.http_port
      ];
      allowedUDPPorts = [ 22000 21027 ];  # syncthing: for discovery, see https://wiki.nixos.org/wiki/Syncthing
      trustedInterfaces = [
        "tailscale0"
      ];
    };

    # The restwas populated at runtime with the networking
    # details gathered from the active system.
    nameservers = [  # config.services.headscale.settings.dns.nameservers.global ++
      # "100.64.0.100"  # Tailscale DNS
      "2a01:4ff:ff00::add:2"
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

  services.tailscale.enable = true;
  services.headscale = {
    enable = true;
    port = 8083;
    settings = {
      serverUrl = "https://headscale.romeov.me";
      noise.private_key_path = "/var/lib/headscale/noise_private.key";
      policy = {
        path = "/etc/headscale/tailnet_policy_file.json";
        mode = "file";
      };
      dns = {
        base_domain = "mycloud";
        override_local_dns = false;  # or set to true and add nameservers below
        extra_records = [
          # {
          #   name = "storage.mycloud";
          #   type = "CNAME";
          #   value = "mycloud-nixos-2.mycloud"; 
          # }
          {
           name = "storage.mycloud";
           type = "A";
           value = "100.64.0.10";  # The IP from the dig result
          }
          {
           name = "freshrss.mycloud";
           type = "A";
           value = "100.64.0.10";
          }
          {
           name = "blog.mycloud";
           type = "A";
           value = "100.64.0.10";
          }
          {
           name = "immich.mycloud";
           type = "A";
           value = "100.64.0.10";  # The IP from the dig result
          }
          {
           name = "openclaw.mycloud";
           type = "A";
           value = "100.64.0.10";
          }
        ];
      #   search_domains = [ "mycloud" ];
      #   nameservers.global = [ "100.64.0.254" ];
      };
    };
  };
  environment.etc."headscale/tailnet_policy_file.json".text = ''
  {"acls": [{
      "action": "accept",
      "src": ["*"],
      "dst": ["*:*"]
    }],
    "tagOwners": {
      "tag:bazzite": ["romeo@"]
    },
    "ssh": [
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["autogroup:self"],
      "users": ["romeo", "root"]
    },
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["tag:bazzite"],
      "users": ["merel"]
    },
    {
      "action": "accept",
      "src": ["romeo@"],
      "dst": ["tag:bazzite"],
      "users": ["romeo", "root"]
    }
    ]}
  '';
  # headscale sometimes takes forever to shut down...
  systemd.services.headscale.serviceConfig.TimeoutStopSec = "15s";
}
