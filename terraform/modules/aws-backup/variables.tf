variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for S3 server-side encryption"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
