# Control Plane Load Balancer — dedicated to K8s API (6443)
# App traffic is handled by a separate LB managed by hcloud-ccm

resource "hcloud_load_balancer" "main" {
  name               = "${var.project_name}-control-plane"
  load_balancer_type = "lb11"
  location           = var.location
}

resource "hcloud_load_balancer_network" "main" {
  load_balancer_id = hcloud_load_balancer.main.id
  subnet_id        = var.subnet_id
}

resource "hcloud_load_balancer_service" "k8s_api" {
  load_balancer_id = hcloud_load_balancer.main.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443

  health_check {
    protocol = "https"
    port     = 6443

    http {
      path         = "/readyz"
      tls          = true
      status_codes = ["200", "401"]
    }

    interval = 15
    timeout  = 10
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
