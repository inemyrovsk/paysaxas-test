output "firewall_id" {
  description = "ID of the Hetzner firewall"
  value       = hcloud_firewall.main.id
}
