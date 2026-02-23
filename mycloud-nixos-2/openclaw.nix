{ config, pkgs, ... }:
let
  # Himalaya config for openclaw (same as zeroclaw)
  himalayaConfig = pkgs.writeText "himalaya-config.toml" ''
    [accounts.stanford]
    default = true
    email = "romeov@stanford.edu"
    folder.aliases.inbox = "Inbox"
    backend.type = "maildir"
    backend.root-dir = "/var/lib/mailsync/stanford"
  '';
in {
  # 1. Create system user + group
  users.users.openclaw = {
    isSystemUser = true;
    group = "openclaw";
    extraGroups = [ "mailread" ];  # For mail access (same as zeroclaw)
    home = "/var/lib/openclaw";
    createHome = true;
    shell = pkgs.bash;  # Need a real shell for command execution
  };
  users.groups.openclaw = {};

  # 2. Setup himalaya config
  systemd.tmpfiles.rules = [
    "d /var/lib/openclaw/.config/himalaya 0750 openclaw openclaw -"
    "L+ /var/lib/openclaw/.config/himalaya/config.toml - - - - ${himalayaConfig}"
  ];

  # 3. Systemd service with hardening
  systemd.services.openclaw-gateway = {
    description = "OpenClaw Gateway";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    # Tools available in PATH (cleaner than Environment variable)
    path = with pkgs; [
      nix
      git
      curl
      wget
      jq
      bash
      coreutils
      findutils
      gnugrep
      gnused
      gawk
      # tar
      gzip
      python3
      uv
      himalaya
      khal
      pimsync
      tailscale
      bun
    ];

    serviceConfig = {
      User = "openclaw";
      Group = "openclaw";
      WorkingDirectory = "/var/lib/openclaw";
      StateDirectory = "openclaw";
      StateDirectoryMode = "0750";
      LogsDirectory = "openclaw";  # Creates /var/log/openclaw with proper ownership
      LogsDirectoryMode = "0750";

      # Command to run (gateway subcommand starts the WebSocket gateway)
      ExecStart = "${pkgs.openclaw}/bin/openclaw gateway";

      # Restart policy
      Restart = "always";
      RestartSec = 10;

      # Load secrets from agenix
      EnvironmentFile = [
        config.age.secrets.openclaw-api-key.path
        config.age.secrets.openclaw-telegram-token.path
      ];

      # Environment variables (without PATH, now using path attribute)
      Environment = [
        "OPENCLAW_STATE_DIR=/var/lib/openclaw"
        "OPENCLAW_CONFIG_PATH=/var/lib/openclaw/openclaw.json"
        "HOME=/var/lib/openclaw"  # For tools that use $HOME
        "NIX_PATH=nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      ];

      # ===== SYSTEMD HARDENING =====
      # Based on zeroclaw's hardening but adjusted for openclaw needs

      # Filesystem protection
      ProtectHome = "tmpfs";  # More permissive than "true" for potential access needs
      ProtectSystem = "strict";  # /usr, /boot, /etc read-only
      PrivateTmp = true;

      # Writable paths
      ReadWritePaths = [
        "/var/lib/openclaw"
        "/nix/var/nix"  # For nix commands (store DB, etc.)
      ];

      # Read-only binds
      BindReadOnlyPaths = [
        "/var/lib/mailsync/stanford"           # Mail access (symlink)
        "/mnt/storage-box/mail/stanford"       # Real mail location
      ];

      # Capabilities - minimal (CAP_CHOWN needed for log file ownership)
      CapabilityBoundingSet = "CAP_CHOWN CAP_FOWNER";
      AmbientCapabilities = "";
      NoNewPrivileges = true;

      # Kernel protection
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;

      # Process visibility
      ProtectProc = "invisible";
      ProcSubset = "pid";

      # Namespace restrictions
      RestrictNamespaces = true;
      LockPersonality = true;

      # Privilege restrictions
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;

      # Network - full access (IPv4, IPv6, Unix, Netlink)
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];
      # No IPAddressDeny - allow all network destinations

      # Syscall filtering - whitelist safe syscalls plus fchown for log file ownership
      SystemCallFilter = [ "@system-service" "~@privileged" "fchown" ];
      SystemCallArchitectures = "native";

      # Memory protection
      # Note: MemoryDenyWriteExecute disabled for Node.js V8 JIT compilation
      MemoryDenyWriteExecute = false;
      MemoryMax = "4G";

      # Resource limits
      CPUQuota = "200%";  # 2 cores
      TasksMax = 128;

      # File creation permissions
      UMask = "0027";
    };
  };

  # Note: No firewall port opening needed (Tailscale access only)
}
