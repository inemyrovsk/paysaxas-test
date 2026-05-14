variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the S3 backup bucket"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for backup encryption"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to all AWS resources"
  type        = map(string)
  default     = {}
}
