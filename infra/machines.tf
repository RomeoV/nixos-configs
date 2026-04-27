# Existing Hetzner Cloud servers - imported, not provisioned from scratch.
# These were originally created manually + nixos-infect, so there is no
# nixos-anywhere provisioner here (unlike opentofu-managed-servers).

locals {
  machines = {
    mycloud-nixos   = { server_type = "cpx11", location = "ash" }
    mycloud-nixos-2 = { server_type = "cx33",  location = "hel1" }
  }
}

resource "hcloud_server" "machines" {
  for_each    = local.machines
  name        = each.key
  server_type = each.value.server_type
  image       = "debian-12" # bootstrap image; already running NixOS via nixos-infect
  location    = each.value.location
  ssh_keys    = [hcloud_ssh_key.default.id]

  # Prevent Terraform from trying to recreate servers if image changes
  lifecycle {
    ignore_changes = [image, ssh_keys]
  }
}
