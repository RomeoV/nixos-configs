# DNS records managed via Porkbun + Hetzner rDNS.
# Records not tied to server IPs (e.g. page.romeov.me CNAME) are left manual.

locals {
  # A records on romeov.me → server IPs
  romeov_a_records = {
    # mycloud-nixos (currently OFF)
    romeov-me          = { subdomain = "",                            server = "mycloud-nixos" }
    storage            = { subdomain = "storage",                     server = "mycloud-nixos" }
    gts                = { subdomain = "gts",                         server = "mycloud-nixos" }
    libreddit          = { subdomain = "libreddit",                   server = "mycloud-nixos" }

    # mycloud-nixos-2 (running)
    immich             = { subdomain = "immich",                      server = "mycloud-nixos-2" }
    redlib             = { subdomain = "redlib",                      server = "mycloud-nixos-2" }
    headscale          = { subdomain = "headscale",                   server = "mycloud-nixos-2" }
    sbucaptions-sub    = { subdomain = "disentangling-sbucaptions",   server = "mycloud-nixos-2" }
    agenda             = { subdomain = "agenda",                      server = "mycloud-nixos-2" }
  }
}

resource "porkbun_dns_record" "romeov_a" {
  for_each  = local.romeov_a_records
  domain    = var.domain
  subdomain = each.value.subdomain
  type      = "A"
  content   = hcloud_server.machines[each.value.server].ipv4_address
  ttl       = 600
}

# disentangling-sbucaptions.xyz — separate domain, root A record
resource "porkbun_dns_record" "sbucaptions_xyz" {
  domain    = "disentangling-sbucaptions.xyz"
  subdomain = ""
  type      = "A"
  content   = hcloud_server.machines["mycloud-nixos-2"].ipv4_address
  ttl       = 600
}

# ── Reverse DNS (Hetzner side) ──────────────────────────────────────────

resource "hcloud_rdns" "mycloud-nixos-ipv4" {
  server_id  = hcloud_server.machines["mycloud-nixos"].id
  ip_address = hcloud_server.machines["mycloud-nixos"].ipv4_address
  dns_ptr    = var.domain
}

resource "hcloud_rdns" "mycloud-nixos-2-ipv4" {
  server_id  = hcloud_server.machines["mycloud-nixos-2"].id
  ip_address = hcloud_server.machines["mycloud-nixos-2"].ipv4_address
  dns_ptr    = "mycloud-nixos-2.${var.domain}"
}
