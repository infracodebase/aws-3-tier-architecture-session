# Outputs for the AWS 3-tier architecture

# Network outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of private application subnets"
  value       = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  description = "IDs of private data subnets"
  value       = aws_subnet.private_data[*].id
}

# Load Balancer outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

# CloudFront outputs
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].id : null
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].domain_name : null
}

output "cloudfront_url" {
  description = "URL of the CloudFront distribution"
  value       = var.enable_cloudfront ? "https://${aws_cloudfront_distribution.main[0].domain_name}" : null
}

# Auto Scaling outputs
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.arn
}

# RDS outputs
output "rds_endpoint" {
  description = "Connection endpoint for RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "Hostname of RDS instance"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "Port of RDS instance"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "Name of the database"
  value       = aws_db_instance.main.db_name
}

output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

# ElastiCache outputs
output "elasticache_replication_group_id" {
  description = "ID of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.main.id
}

output "elasticache_configuration_endpoint" {
  description = "Configuration endpoint for ElastiCache cluster"
  value       = aws_elasticache_replication_group.main.configuration_endpoint_address
}

output "elasticache_primary_endpoint" {
  description = "Primary endpoint for ElastiCache cluster"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "elasticache_reader_endpoint" {
  description = "Reader endpoint for ElastiCache cluster"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "elasticache_port" {
  description = "Port for ElastiCache cluster"
  value       = aws_elasticache_replication_group.main.port
}

# Application URL
output "application_url" {
  description = "Primary URL to access the application"
  value       = var.enable_cloudfront ? "https://${aws_cloudfront_distribution.main[0].domain_name}" : "http://${aws_lb.main.dns_name}"
}
