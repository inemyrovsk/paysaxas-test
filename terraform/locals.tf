locals {
  project_name = "paysaxas"

  common_tags = {
    Project     = local.project_name
    ManagedBy   = "terraform"
    Environment = "production"
  }
}
