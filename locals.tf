# Local values for resource naming and configuration

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Region    = var.aws_region
    }
  )

  # Subnet configuration per AZ
  az_count = length(var.availability_zones)

  # Secret management - use Secrets Manager if enabled, otherwise fall back to variables
  rds_password = var.use_secrets_manager ? (
    var.rds_password_secret_arn != "" ? (
      data.aws_secretsmanager_secret_version.rds_password[0].secret_string
      ) : (
      aws_secretsmanager_secret_version.rds_password[0].secret_string
    )
  ) : var.rds_master_password

  redis_auth_token = var.use_secrets_manager ? (
    var.redis_token_secret_arn != "" ? (
      data.aws_secretsmanager_secret_version.redis_token[0].secret_string
      ) : (
      aws_secretsmanager_secret_version.redis_token[0].secret_string
    )
  ) : var.redis_auth_token
}
