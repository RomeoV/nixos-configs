{ config, sbucaptions-webserver, inputs, ... }:
{
  options = {
    services.sbucaptions-webserver = {
      enable = mkEnableOption (lib.mdDoc "sbucaptions webserver");

      # package = mkPackageOption pkgs "redlib" { };

      # address = mkOption {
      #   default = "0.0.0.0";
      #   example = "127.0.0.1";
      #   type =  types.str;
      #   description = lib.mdDoc "The address to listen on";
      # };

      # port = mkOption {
      #   default = 8080;
      #   example = 8000;
      #   type = types.port;
      #   description = lib.mdDoc "The port to listen on";
      # };

      # openFirewall = mkOption {
      #   type = types.bool;
      #   default = false;
      #   description = lib.mdDoc "Open ports in the firewall for the redlib web interface";
      # };

    };
  };

  config = mkIf cfg.enable {
    systemd.services.sbucaption-webserver-service = {
      description = "sbucaptions_webserver service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${sbucaptions-webserver.packages.${pkgs.system}.default}/bin/sbucaptions_webserver";
        Environment = [
          "SBUCAPTIONS_DIR=/mnt/storage-box/ksvd-results/data/sbucaptions"
          "X_MATRIX_PATH=/mnt/storage-box/ksvd-results/encodings/X_mat.npy"
        ];

        DynamicUser = true;
        AmbientCapabilities = lib.mkIf (cfg.port < 1024) [ "CAP_NET_BIND_SERVICE" ];
        Restart = "on-failure";
        RestartSec = "2s";
        # Hardening
        CapabilityBoundingSet = if (cfg.port < 1024) then [ "CAP_NET_BIND_SERVICE" ] else [ "" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        # A private user cannot have process capabilities on the host's user
        # namespace and thus CAP_NET_BIND_SERVICE has no effect.
        PrivateUsers = (cfg.port >= 1024);
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
        UMask = "0077";
      };
    };
  }
}
