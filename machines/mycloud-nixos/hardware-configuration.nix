# Machine-specific hardware for mycloud-nixos.
# Common QEMU/Hetzner config is in modules/hetzner.nix.
{ ... }: {
  # Hetzner volume: volume-ash-1 (ID 23527885, 100GB)
  fileSystems."/storage" = {
    device = "/dev/disk/by-id/scsi-0HC_Volume_23527885";
    fsType = "ext4";
    neededForBoot = true;
  };
  fileSystems."/nix" = {
    device = "/storage/nix";
    options = [ "bind" ];
    neededForBoot = true;
  };
}
