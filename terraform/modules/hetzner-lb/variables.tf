variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
}

variable "subnet_id" {
  description = "ID of the app subnet for the load balancer network attachment"
  type        = string
}

variable "server_id" {
  description = "ID of the server to add as LB target"
  type        = number
}
