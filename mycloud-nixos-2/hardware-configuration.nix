{ config, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };


  environment.etc."rclone-mnt.conf".text = ''
    [storage-box]
    type = sftp
    host = u380790.your-storagebox.de
    user = u380790
    port = 23
    key_file = ''+config.age.secrets.hetzner_private_key.path+''

    shell_type = unix
    md5sum_command = md5 -r
    sha1sum_command = sha1 -r
'';
  # we have to move the backblaze config into a age file because the key must be provided plain-text,
  # i.e. we can't pass something like `secrets.mlflow-artifacts-key.path` to the file.

  # We end up storing everything for immich by default in /var/lib/immich, but then symlink some dirs from there to this mount!
  # This is because the immich module doesn't separate between something like =homeDir= and =dataDir=.
  fileSystems."/mnt/immich-library" = {
    device = "immich-object-storage:immich-library2";
    fsType = "rclone";
    neededForBoot = false;
    options = [
      "nodev"  # Disallows access to special device files.
      "nofail"  # Allows the system to boot even if the mount fails.
      "allow_other"  # Allows users other than the owner of the mountpoint to access the mounted filesystem.
      "default_permissions"  # Enables permission checking for the mounted filesystem, using the standard Unix permission rules.
      # "args2env"
      "uid=${toString config.users.users.immich.uid}"
      "gid=${toString config.users.groups.immich.gid}"
      "config=${config.age.secrets.rclone-config-immich-object-storage.path}"
      "vfs-cache-mode=full"
      "vfs-cache-max-size=4G"
      "use-server-modtime"
    ];
  };
  systemd.tmpfiles.rules = [
    # The `-` are placeholders for user, group, mode, and age, which can be omitted in this case.
    "L ${config.services.immich.mediaLocation}/library - - - - /mnt/immich-library/library"
    "L ${config.services.immich.mediaLocation}/thumbs - - - - /mnt/immich-library/thumbs"
    "L ${config.services.immich.mediaLocation}/encoded-video - - - - /mnt/immich-library/encoded-video"
    "L ${config.services.immich.mediaLocation}/profile - - - - /mnt/immich-library/profile"
    "L ${config.services.immich.mediaLocation}/backups - - - - /mnt/immich-library/backups"
  ];

  fileSystems."/mnt/nextcloud-storage" = {
    device = "immich-object-storage:nextcloud-storage";
    fsType = "rclone";
    neededForBoot = false;
    options = [
      "nodev"  # Disallows access to special device files.
      "nofail"  # Allows the system to boot even if the mount fails.
      "allow_other"  # Allows users other than the owner of the mountpoint to access the mounted filesystem.
      "default_permissions"  # Enables permission checking for the mounted filesystem, using the standard Unix permission rules.
      # "args2env"
      "uid=${toString config.users.users.nextcloud.uid}"
      "gid=${toString config.users.groups.nextcloud.gid}"
      "config=${config.age.secrets.rclone-config-immich-object-storage.path}"
      "vfs-cache-mode=full"
      "vfs-cache-max-size=4G"
      "use-server-modtime"
    ];
  };
  # systemd.services."mnt-nextcloud\\x2dstorage.mount" = {
  #   before = [ "nextcloud-setup.service" ];
  #   requiredBy = [ "nextcloud-setup.service" ];
  # };

  fileSystems."/mnt/mlflow-artifacts" = {
    device = "mlflow_artifacts:mlflow-artifacts";
    fsType = "rclone";
    neededForBoot = false;
    options = [
      "nodev"        # don't interpret special characters (?)
      "nofail"       # continue booting if it fails
      "allow_other"  # all users can access this mount
      "args2env"     # pass configuraiton options as environment variables (!). rclone specific.
      "config=${config.age.secrets.mlflow-artifacts-key.path}"
      "vfs-cache-mode=writes"
    ];
  };

  fileSystems."/sbucaptions-storage" =
    { device = "/dev/disk/by-id/scsi-0HC_Volume_101330357";
      fsType = "ext4";
      neededForBoot = false;
    };
}
