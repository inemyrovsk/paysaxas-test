output "server_id" {
  description = "ID of the Hetzner server"
  value       = hcloud_server.main.id
}

output "server_public_ip" {
  description = "Public IPv4 address of the server"
  value       = hcloud_server.main.ipv4_address
}

output "server_private_ip" {
  description = "Private IP address of the server in the Hetzner network"
  value       = one(hcloud_server.main.network[*].ip)
}
