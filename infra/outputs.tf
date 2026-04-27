output "machine_ips" {
  value = { for k, v in hcloud_server.machines : k => v.ipv4_address }
}

output "volume_ids" {
  value = { for k, v in hcloud_volume.volumes : k => v.id }
}
