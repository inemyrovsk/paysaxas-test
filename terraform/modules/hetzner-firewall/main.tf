resource "hcloud_firewall" "main" {
  name = "${var.project_name}-firewall"

  # SSH - open to all for now (GitHub Actions has dynamic IPs)
  # TODO: restrict to admin_ip + GitHub Actions IP ranges
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = var.ssh_port
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # ICMP
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  dynamic "apply_to" {
    for_each = var.server_ids
    content {
      server = apply_to.value
    }
  }
}
