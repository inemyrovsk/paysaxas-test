output "network_id" {
  description = "ID of the Hetzner private network"
  value       = hcloud_network.main.id
}

output "subnet_id" {
  description = "ID of the Hetzner network subnet"
  value       = hcloud_network_subnet.main.id
}
