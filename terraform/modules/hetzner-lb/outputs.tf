output "lb_id" {
  description = "ID of the Hetzner load balancer"
  value       = hcloud_load_balancer.main.id
}

output "lb_public_ip" {
  description = "Public IPv4 address of the load balancer"
  value       = hcloud_load_balancer.main.ipv4
}
