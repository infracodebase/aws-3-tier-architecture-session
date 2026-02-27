# Data sources for dynamic lookups

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# AWS Secrets Manager - RDS Password (when using existing secret)
data "aws_secretsmanager_secret_version" "rds_password" {
  count = var.use_secrets_manager && var.rds_password_secret_arn != "" ? 1 : 0

  secret_id = var.rds_password_secret_arn
}

# AWS Secrets Manager - Redis Auth Token (when using existing secret)
data "aws_secretsmanager_secret_version" "redis_token" {
  count = var.use_secrets_manager && var.redis_token_secret_arn != "" ? 1 : 0

  secret_id = var.redis_token_secret_arn
}
