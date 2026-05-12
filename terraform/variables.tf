variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for server access"
  type        = string
  default     = "~/.ssh/paysaxas.pub"
}

variable "admin_ip" {
  description = "Admin IP address for SSH access (CIDR notation, e.g. 1.2.3.4/32)"
  type        = string
}

variable "hetzner_server_type" {
  description = "Hetzner server type for the K3s node"
  type        = string
  default     = "cpx32"
}

variable "hetzner_location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "nbg1"
}
