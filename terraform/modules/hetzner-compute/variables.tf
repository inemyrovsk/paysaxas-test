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
  description = "ID of the Hetzner private network"
  type        = number
}

variable "subnet_id" {
  description = "ID of the app subnet to attach the server to"
  type        = string
}

variable "server_ip" {
  description = "Private IP address for the K3s server"
  type        = string
  default     = "10.0.2.2"
}

variable "nat_gateway_ip" {
  description = "Private IP of the NAT gateway for default route"
  type        = string
  default     = "10.0.1.2"
}
