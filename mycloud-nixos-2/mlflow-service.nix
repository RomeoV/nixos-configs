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
    artifactRoot = mkOption {
      type = types.str;
      description = "Root directory for artifact storage";
    };
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
      serviceConfig = {
        ExecStart = "${pkgs.callPackage ./my-mlflow-server.nix {}}/bin/mlflow server --host ${cfg.host} --port ${toString cfg.port} --artifacts-destination ${cfg.artifactRoot} ${toString cfg.extraArgs}";
        Restart = "on-failure";
        User = "mlflow";
        Group = "mlflow";
      };
    };

    users.users.mlflow = {
      isSystemUser = true;
      group = "mlflow";
    };

    users.groups.mlflow = {};
  };
}
