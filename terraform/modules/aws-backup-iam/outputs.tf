output "access_key_id" {
  description = "IAM access key ID for CNPG backup"
  value       = aws_iam_access_key.backup.id
  sensitive   = true
}

output "secret_access_key" {
  description = "IAM secret access key for CNPG backup"
  value       = aws_iam_access_key.backup.secret
  sensitive   = true
}
