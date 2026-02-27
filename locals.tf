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
}
