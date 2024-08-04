{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.myMlflowServer;
in {
  options.services.myMlflowServer = {
    enable = mkEnableOption "MLflow server";
    port = mkOption {
      type = types.port;
      default = 5000;
      description = "Port on which MLflow server will listen";
    };
    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Hostname or IP address to bind";
    };
    basedir = mkOption {
      type = types.str;
      description = "Root directory for storage";
    };
    # artifactRoot = mkOption {
    #   type = types.str;
    #   description = "Root directory for artifact storage";
    # };
    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra arguments to pass to MLflow server";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.mlflow-server = {
      description = "MLflow Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        mkdir -p ${cfg.basedir}
        chown mlflow:mlflow ${cfg.basedir}
      '';
      serviceConfig = {
        ExecStart = ''
          ${pkgs.callPackage ./my-mlflow-server.nix {}}/bin/mlflow server --host ${cfg.host} --port ${toString cfg.port} \
          ${toString cfg.extraArgs}
        '';
        Restart = "on-failure";
        User = "mlflow";
        Group = "mlflow";
        WorkingDirectory = cfg.basedir;  # Set the working directory
      };
    };

    users.users.mlflow = {
      isSystemUser = true;
      group = "mlflow";
    };

    users.groups.mlflow = {};
  };
}
