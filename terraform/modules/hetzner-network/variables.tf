variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "nat_gateway_ip" {
  description = "Private IP of the NAT gateway for the default route"
  type        = string
  default     = "10.0.1.2"
}
