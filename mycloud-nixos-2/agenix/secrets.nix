let
    Lenovo-P1 = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIzDCdxCAPnbdzwkKpp/9AUGMyABSPj/vZffRQoojdHh6Ct+9fZ60vYOS9NaQy9bqdagC0bHrrBvELiTqbAj5E3I1E7Mfp2BXjI/ig+NTlp0SIoaXnlLRNxnb+TSEDuAdqMdgwjxuy63T5PK04e7AH24NQ8J9sF16QAu0A0VurZEzPTLVZIoFCr/qmxZLnsJELdAtmnxCf+ZlBSs+v0qWOibOQ1mgKecii+0hRPSDpmY62FI++AzNoeVJ4j0ObSC/hpLMYkF5DJSkwaD+4+7CDLFhHdIQ5AzZNZp4gS2IESGUVTbUhXHm0YOr/xj66ZLqDzA16F+dSkKrnfRyTGrjdeWNsMTy42W42wEK1FhbHfsg4AQtT7S3kyiKS0lUFPdH34Q6iiTShTtySDCPW46hEp97sYshZ2aSDAIKYRty3mODPZlM12LL6z1bgbte6bsI3JN0nbIULemfgVqlZAHRDpCv05muEi4IPzYdDxMutAN8zNcMz3IyVoRQ/2bw2kds=";
    JuiceSSH = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcP5JDW+JKSD04YGd+giu8oGCVGKjh7ZSap0UbNUYhP JuiceSSH";
    system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPkmhGLFvUYG/rvZ12j+mamfEcXAh8xeMfYF3B4VBnVt";
    system2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINW3O4vGdlI7ZKhqTcuo4rFb97W3B9oquKMxoZI/ijkw";
    mycloud-nixos-2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBTIYFWBPT6gv2Udl37nRUPULH9oBDgg5q4zZOB8vWCA root@mycloud-nixos-2";
in {
  "nextcloud_admin_pass.age".publicKeys = [ Lenovo-P1 JuiceSSH system1 system2 mycloud-nixos-2 ];
  "hetzner_private_key.age".publicKeys = [ Lenovo-P1 JuiceSSH system1 system2 mycloud-nixos-2 ];
  "backblaze_env.age".publicKeys = [ Lenovo-P1 JuiceSSH system1 system2 mycloud-nixos-2 ];
  "backblaze_password.age".publicKeys = [ Lenovo-P1 JuiceSSH system1 system2 mycloud-nixos-2 ];
  "backblaze_repo.age".publicKeys = [ Lenovo-P1 JuiceSSH system1 system2 mycloud-nixos-2 ];
}
