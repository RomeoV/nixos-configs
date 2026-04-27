variable "ssh_public_key_path" {
  description = "Path to local SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "domain" {
  description = "Base domain (DNS zone)"
  type        = string
  default     = "romeov.me"
}
