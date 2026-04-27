locals {
  volumes = {
    volume-ash-1        = { size = 100, location = "ash",  server = "mycloud-nixos" }
    sbucaption-storage  = { size = 40,  location = "hel1", server = "mycloud-nixos-2" }
    mail-storage        = { size = 25,  location = "hel1", server = "mycloud-nixos-2" }
  }
}

resource "hcloud_volume" "volumes" {
  for_each = local.volumes
  name     = each.key
  size     = each.value.size
  location = each.value.location

  lifecycle {
    ignore_changes = [location, labels]
  }
}

resource "hcloud_volume_attachment" "attachments" {
  for_each  = local.volumes
  volume_id = hcloud_volume.volumes[each.key].id
  server_id = hcloud_server.machines[each.value.server].id
  automount = false
}
