output "network_id" {
  description = "ID of the Hetzner private network"
  value       = hcloud_network.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet (NAT gateway)"
  value       = hcloud_network_subnet.public.id
}

output "app_subnet_id" {
  description = "ID of the application subnet (K3s nodes)"
  value       = hcloud_network_subnet.app.id
}

output "db_subnet_id" {
  description = "ID of the database subnet"
  value       = hcloud_network_subnet.db.id
}
