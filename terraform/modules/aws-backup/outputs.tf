output "bucket_name" {
  description = "Name of the S3 backup bucket"
  value       = aws_s3_bucket.backup.id
}

output "bucket_arn" {
  description = "ARN of the S3 backup bucket"
  value       = aws_s3_bucket.backup.arn
}

output "etcd_bucket_name" {
  description = "Name of the S3 etcd snapshots bucket"
  value       = aws_s3_bucket.etcd.id
}

output "etcd_bucket_arn" {
  description = "ARN of the S3 etcd snapshots bucket"
  value       = aws_s3_bucket.etcd.arn
}
