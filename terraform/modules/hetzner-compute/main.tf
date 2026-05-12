resource "hcloud_ssh_key" "main" {
  name       = "${var.project_name}-key"
  public_key = file(var.ssh_public_key_path)
}

resource "hcloud_server" "main" {
  name        = "${var.project_name}-k3s"
  server_type = var.server_type
  location    = var.location
  image       = "debian-12"
  ssh_keys    = [hcloud_ssh_key.main.id]

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  # Inline network block required — server with no public IP needs
  # a private network attached at creation time to boot.
  network {
    network_id = var.network_id
    ip         = var.server_ip
  }

  labels = {
    project     = var.project_name
    environment = "production"
    role        = "k3s"
  }

  user_data = <<-EOT
    #cloud-config
    hostname: ${var.project_name}-k3s
    package_update: true
    packages:
      - python3
      - python3-pip
      - curl
    write_files:
      # Persist default route via NAT gateway across reboots/DHCP renewals
      # Required since Hetzner removed legacy DHCP Router option (Aug 2025)
      - path: /etc/NetworkManager/dispatcher.d/99-default-route
        permissions: '0755'
        content: |
          #!/bin/bash
          # Add default route via NAT gateway on the private network interface
          IFACE=$(ip -o link show | awk -F': ' '/ens10|enp7s0/ {print $2; exit}')
          if [ -n "$IFACE" ] && [ "$1" = "$IFACE" ] && [ "$2" = "up" ]; then
            ip route replace default via ${var.nat_gateway_ip} dev "$IFACE" metric 100
          fi
    runcmd:
      # Wait for private interface to appear
      - |
        for i in $(seq 1 30); do
          PRIV_IF=$(ip -o addr show | grep '${var.server_ip}' | awk '{print $2}')
          [ -n "$PRIV_IF" ] && break
          sleep 2
        done
        if [ -n "$PRIV_IF" ]; then
          echo "Detected private interface: $PRIV_IF"
          # Add default route via NAT gateway (Hetzner DHCP change Aug 2025)
          ip route replace default via ${var.nat_gateway_ip} dev "$PRIV_IF" metric 100 2>/dev/null || true
          # Persist in /etc/network/interfaces
          echo "  post-up ip route replace default via ${var.nat_gateway_ip} dev $PRIV_IF metric 100" >> /etc/network/interfaces
        else
          echo "WARN: private interface not found" >&2
        fi
      - echo "Cloud-init complete" > /var/log/cloud-init-done
  EOT

  lifecycle {
    ignore_changes = [user_data]
  }

}
