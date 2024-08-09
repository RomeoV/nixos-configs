{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };

  # mount hetzner volume
  fileSystems."/storage" =
    { device = "/dev/disk/by-id/scsi-0HC_Volume_23527885";
      fsType = "ext4";
      neededForBoot = true;
    };
  fileSystems."/nix" =
    { device = "/storage/nix";
      # fsType = "none";
      options = ["bind"];
      neededForBoot = true;
    };
  
}
