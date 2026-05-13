# -----------------------------------------------------------------------------
# Hetzner Infrastructure
# -----------------------------------------------------------------------------

module "hetzner_network" {
  source = "./modules/hetzner-network"

  project_name   = local.project_name
  nat_gateway_ip = "10.0.1.2"
}

module "hetzner_compute" {
  source = "./modules/hetzner-compute"

  project_name        = local.project_name
  ssh_public_key_path = var.ssh_public_key_path
  server_type         = var.hetzner_server_type
  location            = var.hetzner_location
  network_id          = module.hetzner_network.network_id
  subnet_id           = module.hetzner_network.app_subnet_id
  server_ip           = "10.0.2.2"
  nat_gateway_ip      = "10.0.1.2"

  depends_on = [module.hetzner_network]
}

module "hetzner_nat" {
  source = "./modules/hetzner-nat"

  project_name = local.project_name
  location     = var.hetzner_location
  ssh_key_id   = module.hetzner_compute.ssh_key_id
  network_id   = module.hetzner_network.network_id
  subnet_id    = module.hetzner_network.public_subnet_id
  nat_ip       = "10.0.1.2"

  depends_on = [module.hetzner_network]
}

module "hetzner_firewall" {
  source = "./modules/hetzner-firewall"

  project_name = local.project_name
  admin_ip     = var.admin_ip
  server_ids   = [module.hetzner_nat.nat_server_id]
}

# Hetzner LB is managed by hcloud-cloud-controller-manager (hccm) in K3s.
# Cilium Gateway API creates a LoadBalancer Service, hccm provisions the LB.

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

module "aws_backup_iam" {
  source = "./modules/aws-backup-iam"

  project_name = local.project_name
  bucket_arn   = module.aws_backup.bucket_arn
  kms_key_arn  = module.aws_kms.key_arn
  common_tags  = local.common_tags
}

# -----------------------------------------------------------------------------
# Generate Ansible inventory from Terraform outputs
# -----------------------------------------------------------------------------

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../ansible/inventory.ini.tpl", {
    nat_ip    = module.hetzner_nat.nat_public_ip
    server_ip = module.hetzner_compute.server_private_ip
  })
  filename = "${path.module}/../ansible/inventory.ini"
}

