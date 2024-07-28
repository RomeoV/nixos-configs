{ }:

{
  nixpkgs.config.packageOverrides = pkgs: {
    mlflow-server = pkgs.mlflow-server.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or []) ++ [ ./patches/mlflow-server.nix.patch ];
    });
  };
}
