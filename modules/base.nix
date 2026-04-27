# Shared base configuration for all Hetzner servers.
{ pkgs, agenixPkgs, ... }: {
  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "America/Los_Angeles";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 45d";
  };
  services.journald.extraConfig = "SystemMaxUse=1G";

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  services.openssh = {
    enable = true;
    extraConfig = "AllowAgentForwarding yes";
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIzDCdxCAPnbdzwkKpp/9AUGMyABSPj/vZffRQoojdHh6Ct+9fZ60vYOS9NaQy9bqdagC0bHrrBvELiTqbAj5E3I1E7Mfp2BXjI/ig+NTlp0SIoaXnlLRNxnb+TSEDuAdqMdgwjxuy63T5PK04e7AH24NQ8J9sF16QAu0A0VurZEzPTLVZIoFCr/qmxZLnsJELdAtmnxCf+ZlBSs+v0qWOibOQ1mgKecii+0hRPSDpmY62FI++AzNoeVJ4j0ObSC/hpLMYkF5DJSkwaD+4+7CDLFhHdIQ5AzZNZp4gS2IESGUVTbUhXHm0YOr/xj66ZLqDzA16F+dSkKrnfRyTGrjdeWNsMTy42W42wEK1FhbHfsg4AQtT7S3kyiKS0lUFPdH34Q6iiTShTtySDCPW46hEp97sYshZ2aSDAIKYRty3mODPZlM12LL6z1bgbte6bsI3JN0nbIULemfgVqlZAHRDpCv05muEi4IPzYdDxMutAN8zNcMz3IyVoRQ/2bw2kds="
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcP5JDW+JKSD04YGd+giu8oGCVGKjh7ZSap0UbNUYhP JuiceSSH"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJbduBCVxs/ZTKkHXdGZ0LIzj0cUWvdLtmLcWO3ZA3I/AAAABHNzaDo= romeo@Romeo-P1"
  ];

  services.fail2ban = {
    enable = true;
    bantime-increment = {
      enable = true;
      factor = "4";
    };
  };

  services.tailscale.enable = true;

  # Audit tracing (https://xeiaso.net/blog/paranoid-nixos-2021-07-18/)
  security.auditd.enable = true;
  security.audit.enable = true;
  security.audit.rules = [ "-a exit,always -F arch=b64 -S execve" ];
  services.logrotate = {
    enable = true;
    settings = {
      header.dateext = true;
      "/var/log/audit/audit.log" = {
        frequency = "monthly";
        rotate = 3;
      };
    };
  };

  programs = {
    mosh.enable = true;
    git.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      withPython3 = false;
      withRuby = false;
      configure.customRC = ''set nowrap'';
    };
  };

  environment.systemPackages = [
    agenixPkgs.default
    pkgs.helix
    pkgs.rclone
    pkgs.bottom
    pkgs.jq
  ];
}
