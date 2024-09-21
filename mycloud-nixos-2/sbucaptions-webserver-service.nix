{ config, lib, pkgs, sbucaptions-webserver, ... }:
with lib;
let
  cfg = config.services.sbucaptions-webserver;
  args = concatStringsSep " " ([
    "--port ${toString cfg.port}"
    "--host ${cfg.address}"
  ]);
in
{
  options = {
    services.sbucaptions-webserver = {
      enable = mkEnableOption (lib.mdDoc "sbucaptions webserver");

      # package = mkPackageOption sbucaptions-webserver "sbucaptions-webserver" { };

      address = mkOption {
        default = "0.0.0.0";
        example = "127.0.0.1";
        type =  types.str;
        description = lib.mdDoc "The address to listen on";
      };

      port = mkOption {
        default = 8096;
        example = 8000;
        type = types.port;
        description = lib.mdDoc "The port to listen on";
      };


      # openFirewall = mkOption {
      #   type = types.bool;
      #   default = false;
      #   description = lib.mdDoc "Open ports in the firewall for the redlib web interface";
      # };

    };
  };

  config = mkIf cfg.enable {
    users.users.sbucaptions_webserver = {
      isSystemUser = true;
      group = "sbucaptions_webserver";
    };
    users.groups.sbucaptions_webserver = {};

    systemd.tmpfiles.rules = [
      "d /sbucaptions-storage/sbucaptions 0755 sbucaptions_webserver sbucaptions_webserver -"
    ];

    systemd.services.sbucaptions-webserver-service = {
      description = "sbucaptions_webserver service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${sbucaptions-webserver.packages.${pkgs.system}.default}/bin/sbucaptions_webserver ${args}";
        # ExecStart = "${lib.getExe cfg.package} ${args}";
        Environment = [
          "SBUCAPTIONS_EXTRACTED_DIR=/sbucaptions-storage/sbucaptions_extracted"
          "X_MATRIX_PATH=/sbucaptions-storage/CLIPVisionTransformer_sbucaptions_encodings_X.npy"
          "CONCEPT_DESCRIPTION_DIR=/sbucaptions-storage/both_batch_summaries_vlm"
        ];
        WorkingDirectory = "/sbucaptions-storage/sbucaptions";

        # DynamicUser = true;
        User = "sbucaptions_webserver";
        Group = "sbucaptions_webserver";
        AmbientCapabilities = lib.mkIf (cfg.port < 1024) [ "CAP_NET_BIND_SERVICE" ];
        Restart = "on-failure";
        RestartSec = "2s";
        # # Hardening
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
        # SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
        # UMask = "0077";
      };
    };
  };
}
