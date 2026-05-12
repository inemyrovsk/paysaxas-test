output "server_public_ip" {
  description = "Public IP address of the K3s server"
  value       = module.hetzner_compute.server_public_ip
}

output "server_private_ip" {
  description = "Private IP address of the K3s server (for Ansible inventory)"
  value       = module.hetzner_compute.server_private_ip
}

output "lb_public_ip" {
  description = "Public IP address of the Hetzner load balancer"
  value       = module.hetzner_lb.lb_public_ip
}

output "s3_backup_bucket_name" {
  description = "Name of the S3 bucket for database backups"
  value       = module.aws_backup.bucket_name
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for backup encryption"
  value       = module.aws_kms.key_arn
}
