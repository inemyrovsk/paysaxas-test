data "aws_caller_identity" "current" {}

resource "aws_kms_key" "backup" {
  description             = "KMS key for ${var.project_name} backup encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-backup-key"
  })
}

resource "aws_kms_alias" "backup" {
  name          = "alias/${var.project_name}-backup"
  target_key_id = aws_kms_key.backup.key_id
}
