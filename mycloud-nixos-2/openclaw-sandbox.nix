# Debug: `sudo openclaw-sandbox` for interactive shell,
# or `sudo openclaw-sandbox -c 'himalaya account list'` for one-off commands.
{ pkgs, ... }:
let
  sandbox-inner = pkgs.writeShellScript "openclaw-sandbox-inner" ''
    PID=$1; shift
    cd /var/lib/openclaw
    while IFS= read -r -d "" line; do
      export "$line"
    done < /proc/"$PID"/environ
    exec ${pkgs.bash}/bin/bash --norc --noprofile "$@"
  '';
in {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "openclaw-sandbox" ''
      PID=$(systemctl show openclaw-gateway.service -p MainPID --value)
      if [ "$PID" = "0" ] || [ -z "$PID" ]; then
        echo "openclaw-gateway is not running" >&2
        exit 1
      fi
      exec nsenter -t "$PID" -m -n \
        -S "$(id -u openclaw)" -G "$(id -g openclaw)" -- \
        ${sandbox-inner} "$PID" "$@"
    '')
  ];
}
