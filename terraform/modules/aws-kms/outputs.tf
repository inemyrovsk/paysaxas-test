output "key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.backup.arn
}

output "key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.backup.key_id
}

output "alias_arn" {
  description = "ARN of the KMS key alias"
  value       = aws_kms_alias.backup.arn
}
