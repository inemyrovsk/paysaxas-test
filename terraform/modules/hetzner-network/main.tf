resource "hcloud_network" "main" {
  name     = "${var.project_name}-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "public" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_network_subnet" "app" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.2.0/24"
}

resource "hcloud_network_subnet" "db" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.3.0/24"
}

resource "hcloud_network_route" "nat_default" {
  network_id  = hcloud_network.main.id
  destination = "0.0.0.0/0"
  gateway     = var.nat_gateway_ip
}
