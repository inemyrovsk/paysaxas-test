resource "hcloud_firewall" "main" {
  name = "${var.project_name}-firewall"

  # HTTP - needed for LB health checks and traffic
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS - needed for LB health checks and traffic
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # SSH default port - needed for initial provisioning before Ansible changes it
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = [var.admin_ip]
  }

  # SSH custom port - used after Ansible hardens sshd
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = var.ssh_port
    source_ips = [var.admin_ip]
  }

  # ICMP
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  apply_to {
    server = var.server_ids[0]
  }
}
