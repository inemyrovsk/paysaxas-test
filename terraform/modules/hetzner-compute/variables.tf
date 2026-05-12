variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
}

variable "network_id" {
  description = "ID of the Hetzner private network to attach the server to"
  type        = number
}

variable "subnet_id" {
  description = "ID of the network subnet (used for dependency ordering)"
  type        = string
}
