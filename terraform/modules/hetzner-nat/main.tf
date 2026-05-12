resource "hcloud_server" "nat" {
  name        = "${var.project_name}-nat"
  server_type = "cx23"
  image       = "debian-12"
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
      - fail2ban
    write_files:
      - path: /etc/network/interfaces
        append: true
        content: |
          auto eth0
          iface eth0 inet dhcp
              post-up echo 1 > /proc/sys/net/ipv4/ip_forward
              post-up iptables -t nat -A POSTROUTING -s '${var.private_network_cidr}' ! -d '${var.private_network_cidr}' -o eth0 -j MASQUERADE
      - path: /etc/fail2ban/jail.d/sshd.local
        content: |
          [sshd]
          enabled = true
          port = ssh
          maxretry = 5
          bantime = 86400
      - path: /etc/ssh/sshd_config.d/hardening.conf
        content: |
          PasswordAuthentication no
          X11Forwarding no
          MaxAuthTries 5
    runcmd:
      - systemctl enable --now fail2ban
      - systemctl restart sshd
      - systemctl restart networking
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
