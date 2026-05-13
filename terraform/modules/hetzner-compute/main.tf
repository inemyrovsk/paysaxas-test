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
    # bootcmd runs BEFORE package_update and runcmd — sets up routing first
    bootcmd:
      - |
        for i in $(seq 1 60); do
          PRIV_IF=$(ip -o addr show | grep '${var.server_ip}' | awk '{print $2}')
          [ -n "$PRIV_IF" ] && break
          sleep 1
        done
        [ -n "$PRIV_IF" ] && ip route add default via 10.0.0.1 dev "$PRIV_IF" metric 100 2>/dev/null || true
    package_update: true
    packages:
      - python3
      - curl
    runcmd:
      - systemctl restart sshd
      - echo "Cloud-init complete" > /var/log/cloud-init-done
  EOT

  lifecycle {
    ignore_changes = [user_data]
  }

}
