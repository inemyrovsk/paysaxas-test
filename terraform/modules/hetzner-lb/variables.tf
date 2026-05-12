variable "project_name" {
  description = "Project name used for resource naming"
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
  description = "ID of the network subnet (used for dependency ordering)"
  type        = string
}

variable "server_id" {
  description = "ID of the server to add as LB target"
  type        = number
}
