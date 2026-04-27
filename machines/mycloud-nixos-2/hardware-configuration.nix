# Machine-specific hardware: storage mounts, volumes.
# Common QEMU/Hetzner config is in modules/hetzner.nix.
{ config, ... }: {
  boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = true;  # nginx listens on headscale addresses

  environment.etc."rclone-storage-box.conf".text = ''
[storage-box]
type = sftp
host = u380790.your-storagebox.de
user = u380790
port = 23
key_file = ${config.age.secrets.hetzner_private_key.path}

shell_type = unix
md5sum_command = md5 -r
sha1sum_command = sha1 -r
'';

  fileSystems."/mnt/immich-library" = {
    device = "immich-object-storage:immich-library2";
    fsType = "rclone";
    neededForBoot = false;
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "default_permissions"
      "uid=${toString config.users.users.immich.uid}"
      "gid=${toString config.users.groups.immich.gid}"
      "config=${config.age.secrets.rclone-config-immich-object-storage.path}"
      "vfs-cache-mode=full"
      "vfs-cache-max-size=4G"
      "use-server-modtime"
      "x-systemd.automount"
      "x-systemd.mount-timeout=30"
    ];
  };
  systemd.tmpfiles.rules = [
    "L ${config.services.immich.mediaLocation}/library - - - - /mnt/immich-library/library"
    "L ${config.services.immich.mediaLocation}/thumbs - - - - /mnt/immich-library/thumbs"
    "L ${config.services.immich.mediaLocation}/encoded-video - - - - /mnt/immich-library/encoded-video"
    "L ${config.services.immich.mediaLocation}/profile - - - - /mnt/immich-library/profile"
    "L ${config.services.immich.mediaLocation}/backups - - - - /mnt/immich-library/backups"
  ];

  fileSystems."/mnt/mlflow-artifacts" = {
    device = "mlflow_artifacts:mlflow-artifacts";
    fsType = "rclone";
    neededForBoot = false;
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=${config.age.secrets.mlflow-artifacts-key.path}"
      "vfs-cache-mode=writes"
      "x-systemd.automount"
      "x-systemd.mount-timeout=30"
    ];
  };

  fileSystems."/mnt/storage-box" = {
    device = "storage-box:";
    fsType = "rclone";
    neededForBoot = false;
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "config=/etc/rclone-storage-box.conf"
      "vfs-cache-mode=writes"
      "x-systemd.automount"
      "x-systemd.mount-timeout=30"
      "x-systemd.requires=network-online.target"
      "x-systemd.after=network-online.target"
    ];
  };

  # Hetzner volume: mail-storage (ID 105304987, 25GB)
  fileSystems."/mnt/mail-storage" = {
    device = "/dev/disk/by-id/scsi-0HC_Volume_105304987";
    fsType = "ext4";
    neededForBoot = false;
  };

  # Hetzner volume: sbucaption-storage (ID 101330357, 40GB)
  fileSystems."/sbucaptions-storage" = {
    device = "/dev/disk/by-id/scsi-0HC_Volume_101330357";
    fsType = "ext4";
    neededForBoot = false;
  };
}
