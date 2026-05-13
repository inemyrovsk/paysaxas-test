resource "hcloud_load_balancer" "main" {
  name               = "${var.project_name}-lb"
  load_balancer_type = "lb11"
  location           = var.location
}

resource "hcloud_load_balancer_network" "main" {
  load_balancer_id = hcloud_load_balancer.main.id
  subnet_id        = var.subnet_id
}

# HTTP - forward to Cilium Gateway API NodePort
resource "hcloud_load_balancer_service" "http" {
  load_balancer_id = hcloud_load_balancer.main.id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = 30080

  health_check {
    protocol = "tcp"
    port     = 30080
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

# HTTPS - forward to Cilium Gateway API NodePort (TLS terminated at Cilium)
resource "hcloud_load_balancer_service" "https" {
  load_balancer_id = hcloud_load_balancer.main.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 30443

  health_check {
    protocol = "tcp"
    port     = 30080
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

# K8s API - TCP passthrough for kubectl access via LB
resource "hcloud_load_balancer_service" "k8s_api" {
  load_balancer_id = hcloud_load_balancer.main.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

resource "hcloud_load_balancer_target" "main" {
  load_balancer_id = hcloud_load_balancer.main.id
  type             = "server"
  server_id        = var.server_id
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.main]
}
