# AWS 3-Tier Architecture - Terraform

Production-ready AWS 3-tier architecture with CloudFront CDN, Application Load Balancer, Auto Scaling EC2 instances, RDS PostgreSQL with Multi-AZ, and ElastiCache Redis.

## Architecture Overview

### Presentation Tier
- **CloudFront**: Global CDN for content delivery and edge caching
- **Application Load Balancer**: Traffic distribution across multiple AZs with health checks

### Application Tier
- **EC2 Auto Scaling Group**: Horizontally scalable application servers (min: 2, max: 6)
- **Private Subnets**: Application instances isolated from direct internet access
- **Auto Scaling Policies**: CPU and request count-based scaling

### Data Tier
- **RDS PostgreSQL**: Multi-AZ deployment with automatic failover
- **ElastiCache Redis**: Multi-AZ Redis cluster for caching and session management
- **Private Data Subnets**: Database resources in isolated subnets

### Network Design
- **VPC**: 10.0.0.0/16 CIDR with DNS support
- **Multi-AZ**: Deployed across 2 availability zones (us-east-1a, us-east-1b)
- **Subnet Segmentation**:
  - Public subnets (10.0.1.0/24, 10.0.11.0/24) - ALB
  - Private app subnets (10.0.2.0/24, 10.0.12.0/24) - EC2 instances
  - Private data subnets (10.0.3.0/24, 10.0.13.0/24) - RDS, ElastiCache
- **NAT Gateways**: One per AZ for high availability

## Prerequisites

- Terraform >= 1.6.0
- AWS CLI configured with appropriate credentials
- AWS account with necessary permissions

## Quick Start

1. **Clone and configure**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the plan**:
   ```bash
   terraform plan
   ```

4. **Deploy infrastructure**:
   ```bash
   terraform apply
   ```

## Required Variables

Set these in `terraform.tfvars`:

```hcl
rds_master_password = "your-strong-password-here"
```

## Optional Configuration

- **SSL Certificate**: Set `ssl_certificate_arn` for HTTPS support
- **CloudFront**: Set `enable_cloudfront = false` to disable CDN
- **Instance Types**: Adjust `ec2_instance_type`, `rds_instance_class`, `elasticache_node_type`

## Security Features

- **Encryption**: RDS and ElastiCache encrypted at rest and in transit
- **Network Isolation**: Multi-layer subnet segmentation
- **Security Groups**: Least-privilege access controls
- **IAM Roles**: SSM access for EC2 management
- **Enhanced Monitoring**: RDS and application metrics
- **CloudWatch Logs**: Centralized logging

## Outputs

After deployment, Terraform outputs:

- `application_url` - Primary URL to access the application
- `alb_dns_name` - Load balancer endpoint
- `cloudfront_domain_name` - CDN endpoint (if enabled)
- `rds_endpoint` - Database connection string
- `elasticache_configuration_endpoint` - Redis cluster endpoint

## Cost Optimization

Default configuration uses:
- t3.medium instances (adjust based on workload)
- Multi-AZ RDS (can be disabled for non-production)
- CloudFront (optional, can be disabled)

Estimated monthly cost: $300-500 (varies by region and usage)

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Architecture Diagram

See `aws-3tier-architecture` diagram in the Canvas tab for visual representation.

## File Structure

```
.
├── terraform.tf          # Terraform version and provider requirements
├── providers.tf          # AWS provider configuration
├── variables.tf          # Input variable definitions
├── locals.tf            # Local value definitions
├── data.tf              # Data sources
├── network.tf           # VPC, subnets, route tables, NAT gateways
├── security_groups.tf   # Security group definitions
├── alb.tf               # Application Load Balancer
├── compute.tf           # EC2 Auto Scaling Group
├── rds.tf               # RDS PostgreSQL
├── elasticache.tf       # ElastiCache Redis
├── cloudfront.tf        # CloudFront distribution
├── outputs.tf           # Output definitions
├── user_data.sh         # EC2 instance initialization script
└── .gitignore           # Git ignore patterns
```

## Notes

- RDS Multi-AZ provides automatic failover but increases cost
- NAT Gateways (one per AZ) are charged hourly plus data transfer
- CloudFront reduces ALB load and improves global performance
- Auto Scaling maintains minimum 2 instances for high availability
