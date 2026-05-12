# -----------------------------------------------------------------------------
# Hetzner Infrastructure
# -----------------------------------------------------------------------------

module "hetzner_network" {
  source = "./modules/hetzner-network"

  project_name = local.project_name
}

module "hetzner_compute" {
  source = "./modules/hetzner-compute"

  project_name        = local.project_name
  ssh_public_key_path = var.ssh_public_key_path
  server_type         = var.hetzner_server_type
  location            = var.hetzner_location
  network_id          = module.hetzner_network.network_id
  subnet_id           = module.hetzner_network.subnet_id
}

module "hetzner_firewall" {
  source = "./modules/hetzner-firewall"

  project_name = local.project_name
  admin_ip     = var.admin_ip
  server_ids   = [module.hetzner_compute.server_id]
}

module "hetzner_lb" {
  source = "./modules/hetzner-lb"

  project_name = local.project_name
  location     = var.hetzner_location
  network_id   = module.hetzner_network.network_id
  subnet_id    = module.hetzner_network.subnet_id
  server_id    = module.hetzner_compute.server_id
}

# -----------------------------------------------------------------------------
# AWS Infrastructure
# -----------------------------------------------------------------------------

module "aws_kms" {
  source = "./modules/aws-kms"

  project_name = local.project_name
  common_tags  = local.common_tags
}

module "aws_backup" {
  source = "./modules/aws-backup"

  project_name = local.project_name
  kms_key_arn  = module.aws_kms.key_arn
  common_tags  = local.common_tags
}

# -----------------------------------------------------------------------------
# Generate Ansible inventory from Terraform outputs
# -----------------------------------------------------------------------------

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../ansible/inventory.ini.tpl", {
    server_ip = module.hetzner_compute.server_public_ip
  })
  filename = "${path.module}/../ansible/inventory.ini"
}
