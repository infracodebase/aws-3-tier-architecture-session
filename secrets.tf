# AWS Secrets Manager resources for secure credential storage

# Generate random password for RDS (only used when secrets are created by Terraform)
resource "random_password" "rds_password" {
  count = var.use_secrets_manager && var.rds_password_secret_arn == "" ? 1 : 0

  length  = 32
  special = true
}

# Generate random token for Redis (only used when secrets are created by Terraform)
resource "random_password" "redis_token" {
  count = var.use_secrets_manager && var.redis_token_secret_arn == "" ? 1 : 0

  length  = 32
  special = true
}

# RDS Password Secret
resource "aws_secretsmanager_secret" "rds_password" {
  count = var.use_secrets_manager && var.rds_password_secret_arn == "" ? 1 : 0

  name_prefix             = "${local.name_prefix}-rds-password-"
  description             = "RDS PostgreSQL master password for ${local.name_prefix}"
  recovery_window_in_days = 7
  kms_key_id              = aws_kms_key.rds.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-password"
    }
  )
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  count = var.use_secrets_manager && var.rds_password_secret_arn == "" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.rds_password[0].id
  secret_string = random_password.rds_password[0].result
}

# Redis Auth Token Secret
resource "aws_secretsmanager_secret" "redis_token" {
  count = var.use_secrets_manager && var.redis_token_secret_arn == "" ? 1 : 0

  name_prefix             = "${local.name_prefix}-redis-token-"
  description             = "ElastiCache Redis auth token for ${local.name_prefix}"
  recovery_window_in_days = 7
  kms_key_id              = aws_kms_key.elasticache.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-redis-token"
    }
  )
}

resource "aws_secretsmanager_secret_version" "redis_token" {
  count = var.use_secrets_manager && var.redis_token_secret_arn == "" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.redis_token[0].id
  secret_string = random_password.redis_token[0].result
}
