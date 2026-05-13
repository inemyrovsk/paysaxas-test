variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
}

variable "ssh_key_id" {
  description = "ID of the Hetzner SSH key resource"
  type        = number
}

variable "network_id" {
  description = "ID of the Hetzner private network"
  type        = number
}

variable "subnet_id" {
  description = "ID of the public subnet to attach the NAT gateway to"
  type        = string
}

variable "nat_ip" {
  description = "Private IP address for the NAT gateway"
  type        = string
  default     = "10.0.1.2"
}

variable "ssh_port" {
  description = "SSH port for the NAT server"
  type        = string
  default     = "22022"
}

variable "private_network_cidr" {
  description = "CIDR of the private network for MASQUERADE rule"
  type        = string
  default     = "10.0.0.0/16"
}
