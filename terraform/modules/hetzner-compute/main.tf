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
      # Detect private network interface dynamically
      - |
        set +e
        route_dev() { awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}'; }
        PRIV_IF=$(ip -4 route show 10.0.0.0/16 2>/dev/null | route_dev | head -n 1)
        if [ -z "$PRIV_IF" ]; then
          PRIV_IF=$(ip -4 route get 10.0.0.1 2>/dev/null | route_dev | head -n 1)
        fi
        if [ -z "$PRIV_IF" ]; then
          PRIV_IF=$(ip -o addr show | grep '${var.server_ip}' | awk '{print $2}')
        fi
        echo "Detected private interface: $PRIV_IF"

        # Open firewalld for private network (openSUSE enables it by default)
        if command -v firewall-cmd &>/dev/null && [ -n "$PRIV_IF" ]; then
          firewall-cmd --zone=trusted --add-interface="$PRIV_IF" --permanent
          firewall-cmd --reload
          echo "Firewalld: added $PRIV_IF to trusted zone"
        fi

        # Persist default route via NAT gateway (Hetzner DHCP change Aug 2025)
        METRIC=100
        if [ -n "$PRIV_IF" ] && systemctl is-active --quiet NetworkManager; then
          NM_CONN=$(nmcli -g GENERAL.CONNECTION device show "$PRIV_IF" 2>/dev/null | head -1)
          if [ -n "$NM_CONN" ]; then
            nmcli connection modify "$NM_CONN" +ipv4.routes "0.0.0.0/0 ${var.nat_gateway_ip} $METRIC" 2>/dev/null || true
            nmcli connection modify "$NM_CONN" ipv4.never-default yes 2>/dev/null || true
            nmcli connection modify "$NM_CONN" ipv4.route-metric $METRIC 2>/dev/null || true
            nmcli connection up "$NM_CONN" 2>/dev/null || true
            echo "NetworkManager: persisted default route via ${var.nat_gateway_ip}"
          fi
          # Runtime guard: add route immediately
          ip route replace default via ${var.nat_gateway_ip} dev "$PRIV_IF" metric $METRIC 2>/dev/null || true
        elif [ -n "$PRIV_IF" ]; then
          ip route replace default via ${var.nat_gateway_ip} dev "$PRIV_IF" metric $METRIC 2>/dev/null || true
        fi
        set -e
      - echo "Cloud-init complete" > /var/log/cloud-init-done
  EOT

  lifecycle {
    ignore_changes = [user_data]
  }

}
