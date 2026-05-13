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
    write_files:
      - path: /etc/resolv.conf
        content: |
          nameserver 1.1.1.1
          nameserver 8.8.8.8
      - path: /etc/ssh/sshd_config.d/hardening.conf
        content: |
          Port ${var.ssh_port}
          PasswordAuthentication no
          X11Forwarding no
          MaxAuthTries 5
      # Persist default route via systemd-networkd (Hetzner Debian uses systemd-networkd, not ifupdown)
      - path: /etc/systemd/network/10-private-route.network
        content: |
          [Match]
          Name=enp7s0

          [Network]
          DHCP=yes

          [Route]
          Gateway=10.0.0.1
          Metric=100
    # bootcmd runs BEFORE everything — sets up route for package_update
    bootcmd:
      - |
        for i in $(seq 1 60); do
          ip -o addr show | grep -q '${var.server_ip}' && break
          sleep 1
        done
        ip route add default via 10.0.0.1 dev enp7s0 metric 100 2>/dev/null || true
    package_update: true
    packages:
      - python3
      - curl
    runcmd:
      - networkctl reload 2>/dev/null || systemctl restart systemd-networkd
      - systemctl restart sshd
      - echo "Cloud-init complete" > /var/log/cloud-init-done
  EOT

  lifecycle {
    ignore_changes = [user_data]
  }

}
