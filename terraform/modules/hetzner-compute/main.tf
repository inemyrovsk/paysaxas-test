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
    runcmd:
      - echo "Cloud-init complete" > /var/log/cloud-init-done
  EOT

  # Subnet dependency is implicit via module input from hetzner-network.subnet_id
  network {
    network_id = var.network_id
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}
