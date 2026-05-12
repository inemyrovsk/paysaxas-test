output "nat_server_id" {
  description = "ID of the NAT gateway server"
  value       = hcloud_server.nat.id
}

output "nat_public_ip" {
  description = "Public IPv4 address of the NAT gateway"
  value       = hcloud_server.nat.ipv4_address
}

output "nat_private_ip" {
  description = "Private IP address of the NAT gateway"
  value       = hcloud_server_network.nat.ip
}
