{ modulesPath, ... }:
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
    key_file = /run/agenix/hetzner_private_key
    shell_type = unix
    md5sum_command = md5 -r
    sha1sum_command = sha1 -r
'';

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

  
}
