resource "hcloud_server" "nat" {
  name        = "${var.project_name}-nat"
  server_type = "cx22"
  image       = "opensuse-16"
  location    = var.location
  ssh_keys    = [var.ssh_key_id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  labels = {
    project     = var.project_name
    environment = "production"
    role        = "nat-gateway"
  }

  user_data = <<-EOT
    #cloud-config
    hostname: ${var.project_name}-nat
    package_update: true
    packages:
      - python3
      - iptables
    write_files:
      - path: /etc/sysctl.d/99-nat.conf
        content: "net.ipv4.ip_forward = 1"
    runcmd:
      - sysctl -p /etc/sysctl.d/99-nat.conf
      - iptables -t nat -A POSTROUTING -s 10.0.0.0/16 -o eth0 -j MASQUERADE
      - iptables-save > /etc/sysconfig/iptables
      - echo "Cloud-init complete" > /var/log/cloud-init-done
  EOT

  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "hcloud_server_network" "nat" {
  server_id = hcloud_server.nat.id
  subnet_id = var.subnet_id
  ip        = var.nat_ip
}
