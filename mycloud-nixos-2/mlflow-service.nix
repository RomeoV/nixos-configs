{ config, lib, pkgs-master, ... }:
let
  cfg = config.services.mlflow-server;
in
{
  options.services.mlflow-server = with lib; {
    enable = mkEnableOption "MLflow server";
    package = mkOption {
      type = types.package;
      default = pkgs-master.mlflow-server;
      description = "The MLflow server package to use";
    };
    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "The host to bind to";
    };
    port = mkOption {
      type = types.port;
      default = 5000;
      description = "The port to listen on";
    };
    basedir = mkOption {
      type = types.str;
      description = "The basedir path for all artifacts.";
    };
    backendStore = mkOption {
      type = types.str;
      description = "The backend store URI";
    };
    defaultArtifactRoot = mkOption {
      type = types.str;
      description = "The default artifact root";
    };
    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra arguments to pass to mlflow server";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mlflow-server = {
      description = "MLflow Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/mlflow server --host ${cfg.host} --port ${toString cfg.port} ${lib.escapeShellArgs cfg.extraArgs}";
        Restart = "always";
        User = "mlflow";
        Group = "mlflow";
        WorkingDirectory = "/var/lib/mlflow";
        # StateDirectory = "mlflow";
      };
    };

    users.users.mlflow = {
      isSystemUser = true;
      group = "mlflow";
      description = "MLflow server user";
      # home = "/var/lib/mlflow";
      # createHome = true;
    };

    users.groups.mlflow = {};

    systemd.tmpfiles.rules = [
      "d /var/lib/mlflow 0755 mlflow mlflow -"
    ];
  };
}
