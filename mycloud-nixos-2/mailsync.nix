# NixOS module for syncing Stanford mail via mbsync + OAuth2.
#
# - Runs as isolated `mailsync` system user with systemd hardening.
# - Mail is readable by the `mailread` group (for zeroclaw, etc.).
# - OAuth2 tokens are private to `mailsync` (0700 tokens dir).
# - Initial token is seeded from an agenix secret; once seeded the
#   service maintains its own copy (mutt_oauth2.py refreshes in-place).
{ config, lib, pkgs, ... }:

let
  stateDir = "/var/lib/mailsync";
  tokenDir = "${stateDir}/tokens";
  tokenFile = "${tokenDir}/stanford.tokens";
  maildirPath = "${stateDir}/stanford";

  # Thunderbird's well-known public client credentials (intentionally public)
  clientId = "08162f7c-0fd2-4200-a84a-f25a4db0b584";
  clientSecret = "TxRBilcHdC6WGBee]fs?QR:SJ8nI[g82";

  saslPath = "${pkgs.cyrus-sasl-xoauth2}/lib/sasl2:${pkgs.cyrus_sasl}/lib/sasl2";

  # Patch mutt_oauth2.py: fix scope to office365.com, drop POP/SMTP
  mutt-oauth2 = pkgs.runCommand "mutt-oauth2-patched" { } ''
    mkdir -p $out/bin
    cp ${pkgs.neomutt}/share/neomutt/oauth2/mutt_oauth2.py $out/bin/mutt_oauth2.py
    chmod +w $out/bin/mutt_oauth2.py
    sed -i "s|'scope': ('offline_access https://outlook.office.com/IMAP.AccessAsUser.All '|'scope': 'offline_access https://outlook.office365.com/IMAP.AccessAsUser.All',|" $out/bin/mutt_oauth2.py
    sed -i "/POP.AccessAsUser.All/d" $out/bin/mutt_oauth2.py
    sed -i "/SMTP.Send/d" $out/bin/mutt_oauth2.py
    chmod +x $out/bin/mutt_oauth2.py
  '';

  passCmd = "${pkgs.python3}/bin/python3 ${mutt-oauth2}/bin/mutt_oauth2.py ${tokenFile} --decryption-pipe cat";

  mbsyncrc = pkgs.writeText "mbsyncrc-stanford" ''
    IMAPAccount stanford
    Host outlook.office365.com
    User romeov@stanford.edu
    AuthMechs XOAUTH2
    PassCmd "${passCmd}"
    TLSType IMAPS

    IMAPStore stanford-remote
    Account stanford

    MaildirStore stanford-local
    SubFolders Verbatim
    Path ${maildirPath}/
    Inbox ${maildirPath}/Inbox

    Channel stanford
    Far :stanford-remote:
    Near :stanford-local:
    Patterns *
    Create Near
    Expunge None
    SyncState *
  '';

  # Wrapper: seed token from agenix on first run, then exec mbsync
  syncScript = pkgs.writeShellScript "mailsync-stanford" ''
    set -euo pipefail

    # Seed token from agenix secret if no writable copy exists yet
    if [ ! -f "${tokenFile}" ]; then
      echo "Seeding token from agenix secret..."
      cp "${config.age.secrets.stanford-oauth-tokens.path}" "${tokenFile}"
      chmod 600 "${tokenFile}"
    fi

    export SASL_PATH="${saslPath}"
    exec ${pkgs.isync}/bin/mbsync -c "${mbsyncrc}" stanford
  '';
in {
  # -- Groups --
  users.groups.mailsync = { };
  users.groups.mailread = { };

  # -- User --
  users.users.mailsync = {
    isSystemUser = true;
    group = "mailsync";
    extraGroups = [ "mailread" ];
    home = stateDir;
    createHome = true;
    description = "Mail sync service user";
  };

  # -- Directories --
  systemd.tmpfiles.rules = [
    "d ${stateDir}    2750 mailsync mailread -"
    "d ${maildirPath} 2750 mailsync mailread -"
    "d ${tokenDir}    0700 mailsync mailsync -"
  ];

  # -- Service --
  systemd.services.mailsync-stanford = {
    description = "Sync Stanford mail via mbsync + OAuth2";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "mailsync";
      Group = "mailsync";
      SupplementaryGroups = [ "mailread" ];
      ExecStart = syncScript;
      WorkingDirectory = stateDir;
      Nice = 10;

      # -- Hardening --
      ProtectHome = true;
      ProtectSystem = "strict";
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;

      ReadWritePaths = [ stateDir ];

      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      ProtectHostname = true;
      ProtectClock = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      LockPersonality = true;

      CapabilityBoundingSet = "";
      AmbientCapabilities = "";

      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];
      IPAddressDeny = "multicast";

      SystemCallFilter = [ "@system-service" ];
      SystemCallArchitectures = "native";

      RestrictNamespaces = true;

      # Python needs W|X pages, so no MemoryDenyWriteExecute
      MemoryMax = "512M";
      CPUQuota = "50%";
      TasksMax = 16;

      UMask = "0027";
    };
  };

  # -- Timer --
  systemd.timers.mailsync-stanford = {
    description = "Sync Stanford mail every 5 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5";
      RandomizedDelaySec = "30s";
    };
  };
}
