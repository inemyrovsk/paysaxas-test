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

module "hetzner_lb" {
  source = "./modules/hetzner-lb"

  project_name = local.project_name
  location     = var.hetzner_location
  subnet_id    = module.hetzner_network.app_subnet_id
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

module "aws_backup_iam" {
  source = "./modules/aws-backup-iam"

  project_name    = local.project_name
  bucket_arn      = module.aws_backup.bucket_arn
  etcd_bucket_arn = module.aws_backup.etcd_bucket_arn
  kms_key_arn     = module.aws_kms.key_arn
  common_tags     = local.common_tags
}

# -----------------------------------------------------------------------------
# Store backup credentials in Secrets Manager (CI reads them from here)
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "backup" {
  name        = "${local.project_name}/backup"
  description = "Backup IAM credentials for CNPG and K3s etcd snapshots"
  tags        = local.common_tags
}

resource "aws_secretsmanager_secret_version" "backup" {
  secret_id = aws_secretsmanager_secret.backup.id
  secret_string = jsonencode({
    access_key_id     = module.aws_backup_iam.access_key_id
    secret_access_key = module.aws_backup_iam.secret_access_key
    s3_bucket         = module.aws_backup.bucket_name
    etcd_bucket       = module.aws_backup.etcd_bucket_name
  })

  # lifecycle {
  #   ignore_changes = [secret_string]
  # }
}

# -----------------------------------------------------------------------------
# Ansible Inventory
# -----------------------------------------------------------------------------

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../ansible/inventory.ini.tpl", {
    nat_ip    = module.hetzner_nat.nat_public_ip
    server_ip = module.hetzner_compute.server_private_ip
    cp_lb_ip  = module.hetzner_lb.lb_public_ip
  })
  filename = "${path.module}/../ansible/inventory.ini"
}

