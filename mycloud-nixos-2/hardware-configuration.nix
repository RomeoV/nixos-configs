{ config, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = true;  # for making nginx listen on addresses which will only instantiate after headscale is up
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };


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
      "x-systemd.automount"
      "x-systemd.mount-timeout=30"
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
      # Tells systemd to mount the filesystem on-demand when it's first accessed, rather than during boot. This means if the network/storage isn't immediately available, boot won't hang.
      "x-systemd.automount"
      # Sets a 30-second timeout for the mount attempt. If the mount doesn't succeed within 30 seconds, systemd will stop trying and continue booting.
      "x-systemd.mount-timeout=30"
    ];
  };

  fileSystems."/mnt/storage-box" = {
    device = "//u380790.your-storagebox.de/backup";
    fsType = "cifs";
    neededForBoot = false;
    options = [
      "credentials=${config.age.secrets.storage-box-cifs-credentials.path}"
      "_netdev"
      "nofail"
      "seal"          # encrypt traffic (SMB 3.0)
      "x-systemd.mount-timeout=30"
    ];
  };

  fileSystems."/sbucaptions-storage" =
    { device = "/dev/disk/by-id/scsi-0HC_Volume_101330357";
      fsType = "ext4";
      neededForBoot = false;
    };
}
