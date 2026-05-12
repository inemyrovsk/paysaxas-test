variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "admin_ip" {
  description = "Admin IP address allowed for SSH access (CIDR notation)"
  type        = string
}

variable "ssh_port" {
  description = "Custom SSH port after hardening"
  type        = string
  default     = "22022"
}

variable "server_ids" {
  description = "List of server IDs to apply the firewall to"
  type        = list(number)
}
