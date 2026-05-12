output "server_id" {
  description = "ID of the Hetzner server"
  value       = hcloud_server.main.id
}

output "server_private_ip" {
  description = "Private IP address of the server in the Hetzner network"
  value       = one(hcloud_server.main.network[*].ip)
}

output "ssh_key_id" {
  description = "ID of the Hetzner SSH key (shared with other modules)"
  value       = hcloud_ssh_key.main.id
}
