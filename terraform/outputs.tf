output "nat_public_ip" {
  description = "Public IP of the NAT gateway (SSH jump host)"
  value       = module.hetzner_nat.nat_public_ip
}

output "server_private_ip" {
  description = "Private IP address of the K3s server"
  value       = module.hetzner_compute.server_private_ip
}


output "s3_backup_bucket_name" {
  description = "Name of the S3 bucket for database backups"
  value       = module.aws_backup.bucket_name
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for backup encryption"
  value       = module.aws_kms.key_arn
}

output "backup_access_key_id" {
  description = "IAM access key ID for CNPG/K3s backups"
  value       = module.aws_backup_iam.access_key_id
  sensitive   = true
}

output "backup_secret_access_key" {
  description = "IAM secret access key for CNPG/K3s backups"
  value       = module.aws_backup_iam.secret_access_key
  sensitive   = true
}
