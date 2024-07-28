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
  fileSystems."/mnt/storage-box" = {
    device = "storage-box:";
    fsType = "rclone";
    neededForBoot = false;
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=/etc/rclone-mnt.conf"
    ];
  };
  fileSystems."/mnt/mlflow-artifacts" = {
    device = "mlflow_artifacts:mlflow-artifacts";
    fsType = "rclone";
    neededForBoot = false;
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      ("config="+config.age.secrets.mlflow-artifacts-key.path)
      "vfs-cache-mode=writes"
    ];
  };

  
}
