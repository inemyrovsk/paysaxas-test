resource "hcloud_ssh_key" "main" {
  name       = "${var.project_name}-key"
  public_key = file(var.ssh_public_key_path)
}

resource "hcloud_server" "main" {
  name        = "${var.project_name}-k3s"
  server_type = var.server_type
  location    = var.location
  image       = "opensuse-16"
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
      # Detect private network interface dynamically (not hardcoded eth1)
      - |
        IFACE=$(ip -o link show | awk -F': ' '/ens10|enp7s0/ {print $2; exit}')
        if [ -z "$IFACE" ]; then
          # Fallback: find the interface with our private IP
          IFACE=$(ip -o addr show | grep '${var.server_ip}' | awk '{print $2}')
        fi
        # Add default route immediately
        ip route replace default via ${var.nat_gateway_ip} dev "$IFACE" metric 100
        # Persist via NetworkManager connection
        nmcli connection modify "$(nmcli -t -f NAME,DEVICE con show | grep "$IFACE" | cut -d: -f1)" \
          +ipv4.routes "0.0.0.0/0 ${var.nat_gateway_ip} 100" 2>/dev/null || true
      - echo "Cloud-init complete" > /var/log/cloud-init-done
  EOT

  lifecycle {
    ignore_changes = [user_data]
  }

}
