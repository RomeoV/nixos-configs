# Debug: `sudo openclaw-sandbox` for interactive shell,
# or `sudo openclaw-sandbox -c 'himalaya account list'` for one-off commands.
{ pkgs, ... }: {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "openclaw-sandbox" ''
      PID=$(systemctl show openclaw-gateway.service -p MainPID --value)
      if [ "$PID" = "0" ] || [ -z "$PID" ]; then
        echo "openclaw-gateway is not running" >&2
        exit 1
      fi
      exec nsenter -t "$PID" -m -n \
        -S "$(id -u openclaw)" -G "$(id -g openclaw)" -- \
        env - $(${pkgs.coreutils}/bin/tr '\0' '\n' < /proc/"$PID"/environ | ${pkgs.gnused}/bin/sed "s/'/'\\\\''/g;s/^/'/;s/\$/'/" | ${pkgs.coreutils}/bin/tr '\n' ' ') \
        ${pkgs.bash}/bin/bash --norc --noprofile "$@"
    '')
  ];
}
