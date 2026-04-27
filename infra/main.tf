terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.60"
    }
    porkbun = {
      source  = "marcfrederick/porkbun"
      version = "~> 1.2"
    }
  }
}

# Both providers read credentials from env vars:
# hcloud:  HCLOUD_TOKEN
# porkbun: PORKBUN_API_KEY, PORKBUN_SECRET_API_KEY
provider "hcloud" {}
provider "porkbun" {}

resource "hcloud_ssh_key" "default" {
  name       = "romeo@Romeo-P1"
  public_key = file(var.ssh_public_key_path)

  # Key was created with RSA, now using ed25519 locally — don't recreate
  lifecycle {
    ignore_changes = [public_key]
  }
}
