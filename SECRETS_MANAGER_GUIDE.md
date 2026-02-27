# AWS Secrets Manager Integration Guide

This guide shows how to use AWS Secrets Manager for secure credential management in production.

## Overview

The infrastructure supports **two modes** for handling secrets:

### Mode 1: Testing/Development (Default - NOT for Production)
- Secrets in `terraform.tfvars` file
- `use_secrets_manager = false`
- ❌ **INSECURE** - Only for testing

### Mode 2: Production (Recommended)
- Secrets in AWS Secrets Manager
- `use_secrets_manager = true`
- ✅ **SECURE** - Production-ready

---

## Quick Start - Production Setup

### Option A: Let Terraform Create Secrets (Easiest)

**Step 1: Enable Secrets Manager**
```hcl
# terraform.tfvars
use_secrets_manager = true

# Remove these lines (secrets will be auto-generated):
# rds_master_password = "..."
# redis_auth_token    = "..."
```

**Step 2: Deploy**
```bash
terraform init -upgrade
terraform apply
```

**Step 3: Get Secret ARNs**
```bash
# Save these for future reference
terraform output rds_password_secret_arn
terraform output redis_token_secret_arn
```

**Done!** Terraform automatically generated secure random passwords and stored them in Secrets Manager.

---

### Option B: Use Existing Secrets (More Control)

**Step 1: Create Secrets in AWS**
```bash
# Generate secure passwords
RDS_PASSWORD=$(openssl rand -base64 32)
REDIS_TOKEN=$(openssl rand -base64 24)

# Create secrets
aws secretsmanager create-secret \
  --name prod/three-tier-app/rds/password \
  --secret-string "$RDS_PASSWORD" \
  --description "RDS master password" \
  --kms-key-id alias/three-tier-app-prod-rds

aws secretsmanager create-secret \
  --name prod/three-tier-app/redis/token \
  --secret-string "$REDIS_TOKEN" \
  --description "Redis auth token" \
  --kms-key-id alias/three-tier-app-prod-elasticache
```

**Step 2: Get Secret ARNs**
```bash
RDS_SECRET_ARN=$(aws secretsmanager describe-secret \
  --secret-id prod/three-tier-app/rds/password \
  --query ARN --output text)

REDIS_SECRET_ARN=$(aws secretsmanager describe-secret \
  --secret-id prod/three-tier-app/redis/token \
  --query ARN --output text)

echo "RDS Secret ARN: $RDS_SECRET_ARN"
echo "Redis Secret ARN: $REDIS_SECRET_ARN"
```

**Step 3: Configure Terraform**
```hcl
# terraform.tfvars
use_secrets_manager      = true
rds_password_secret_arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/three-tier-app/rds/password-AbCdEf"
redis_token_secret_arn   = "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/three-tier-app/redis/token-XyZ123"

# Remove these:
# rds_master_password = "..."
# redis_auth_token    = "..."
```

**Step 4: Deploy**
```bash
terraform init -upgrade
terraform apply
```

---

## Migrating from tfvars to Secrets Manager

### Current State (Insecure)
```hcl
# terraform.tfvars
use_secrets_manager = false
rds_master_password = "MyPassword123"
redis_auth_token    = "MyToken456"
```

### Step 1: Enable Secrets Manager (Zero-Downtime)
```hcl
# terraform.tfvars - Change only this line
use_secrets_manager = true

# Keep passwords temporarily for migration
rds_master_password = "MyPassword123"
redis_auth_token    = "MyToken456"
```

### Step 2: Apply (Creates Secrets)
```bash
terraform apply
# Terraform creates secrets with your current passwords
# No infrastructure changes, just creates secrets
```

### Step 3: Remove Plaintext (After Verification)
```hcl
# terraform.tfvars - Now safe to remove
use_secrets_manager = true

# Remove these lines:
# rds_master_password = "MyPassword123"
# redis_auth_token    = "MyToken456"
```

### Step 4: Final Apply
```bash
terraform apply
# No changes - confirms secrets are working
```

---

## How It Works

### Architecture

```
┌─────────────────┐
│ Terraform Code  │
└────────┬────────┘
         │
         │ use_secrets_manager = true?
         │
    ┌────▼────┐
    │  Yes    │
    └────┬────┘
         │
         │ secret_arn provided?
         │
    ┌────▼────┐        ┌─────────────────┐
    │   No    │───────>│ Create Secret   │
    └─────────┘        │ (random password)│
         │             └─────────────────┘
    ┌────▼────┐
    │  Yes    │        ┌─────────────────┐
    └────┬────┘───────>│ Use Existing    │
         │             │ Secret          │
         │             └─────────────────┘
         │
    ┌────▼────────────────────┐
    │ Retrieve from Secrets   │
    │ Manager (data source)   │
    └────┬────────────────────┘
         │
    ┌────▼────────────────────┐
    │ Pass to RDS/ElastiCache │
    └─────────────────────────┘
```

### Variable Configuration

```hcl
# Mode Selection
variable "use_secrets_manager" {
  default = false  # Set to true for production
}

# For existing secrets (Option B)
variable "rds_password_secret_arn" {
  default = ""  # Provide ARN if secret already exists
}

variable "redis_token_secret_arn" {
  default = ""  # Provide ARN if secret already exists
}

# Fallback for testing (only used if use_secrets_manager = false)
variable "rds_master_password" {
  default = ""
  sensitive = true
}

variable "redis_auth_token" {
  default = ""
  sensitive = true
}
```

### Secret Retrieval Logic

```hcl
# locals.tf
locals {
  rds_password = var.use_secrets_manager ? (
    # Using Secrets Manager
    var.rds_password_secret_arn != "" ? (
      # Using existing secret (Option B)
      data.aws_secretsmanager_secret_version.rds_password[0].secret_string
    ) : (
      # Using Terraform-created secret (Option A)
      aws_secretsmanager_secret_version.rds_password[0].secret_string
    )
  ) : (
    # Fallback to variable (testing only)
    var.rds_master_password
  )
}
```

---

## Secret Rotation

### Manual Rotation

```bash
# Update RDS password
aws secretsmanager update-secret \
  --secret-id prod/three-tier-app/rds/password \
  --secret-string "$(openssl rand -base64 32)"

# Apply changes
terraform apply
```

### Automatic Rotation (Advanced)

Create a Lambda function and enable rotation:

```hcl
resource "aws_secretsmanager_secret_rotation" "rds" {
  count = var.use_secrets_manager ? 1 : 0

  secret_id           = aws_secretsmanager_secret.rds_password[0].id
  rotation_lambda_arn = aws_lambda_function.rotate_rds_secret.arn

  rotation_rules {
    automatically_after_days = 30
  }
}
```

---

## Retrieving Secrets for Application Use

### From EC2/ECS/Lambda (using IAM roles)

```python
import boto3

client = boto3.client('secretsmanager')

# Get RDS password
response = client.get_secret_value(
    SecretId='arn:aws:secretsmanager:...'
)
rds_password = response['SecretString']

# Connect to database
connection = psycopg2.connect(
    host="rds-endpoint",
    password=rds_password,
    ...
)
```

### From CLI

```bash
# Get secret value
aws secretsmanager get-secret-value \
  --secret-id prod/three-tier-app/rds/password \
  --query SecretString \
  --output text
```

---

## IAM Permissions

### For Terraform

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:TagResource"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:*three-tier-app*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": "arn:aws:kms:*:*:key/*"
    }
  ]
}
```

### For Application (EC2/Lambda)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:*:*:secret:*three-tier-app/rds*",
        "arn:aws:secretsmanager:*:*:secret:*three-tier-app/redis*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:*:*:key/*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
        }
      }
    }
  ]
}
```

---

## Cost

**AWS Secrets Manager Pricing:**
- $0.40 per secret per month
- $0.05 per 10,000 API calls

**For this infrastructure:**
- 2 secrets = $0.80/month
- Typical API calls = $0.10/month
- **Total: ~$1/month**

---

## Benefits vs. Alternatives

| Feature | tfvars | Env Vars | Secrets Manager |
|---------|--------|----------|-----------------|
| **Encrypted at rest** | ❌ | ❌ | ✅ (KMS) |
| **Audit logging** | ❌ | ❌ | ✅ (CloudTrail) |
| **Automatic rotation** | ❌ | ❌ | ✅ |
| **Versioning** | ❌ | ❌ | ✅ |
| **Fine-grained access** | ❌ | ❌ | ✅ (IAM) |
| **No plaintext files** | ❌ | ✅ | ✅ |
| **Compliance ready** | ❌ | ⚠️ | ✅ |
| **Cost** | Free | Free | ~$1/month |

---

## Troubleshooting

### Error: "Secret not found"
```bash
# Check if secret exists
aws secretsmanager describe-secret --secret-id YOUR_ARN

# List all secrets
aws secretsmanager list-secrets
```

### Error: "Access Denied"
```bash
# Check IAM permissions
aws iam get-user
aws sts get-caller-identity

# Verify KMS key access
aws kms describe-key --key-id YOUR_KEY_ID
```

### Secret not updating
```bash
# Force Terraform to refresh
terraform refresh

# Or destroy and recreate secret
terraform state rm aws_secretsmanager_secret.rds_password
terraform apply
```

---

## Best Practices

1. ✅ **Always use Secrets Manager in production**
2. ✅ **Enable automatic rotation for 30-90 day cycles**
3. ✅ **Use separate secrets per environment (dev/staging/prod)**
4. ✅ **Monitor CloudTrail for secret access**
5. ✅ **Use least-privilege IAM policies**
6. ✅ **Never log or print secret values**
7. ✅ **Use KMS customer-managed keys**
8. ✅ **Set up alerts for secret access anomalies**

---

## Compliance

### PCI-DSS
- ✅ Requirement 3: Encrypt stored secrets (KMS)
- ✅ Requirement 8: Unique credentials (individual secrets)
- ✅ Requirement 10: Audit logging (CloudTrail)

### HIPAA
- ✅ Encryption at rest (KMS customer-managed keys)
- ✅ Access controls (IAM policies)
- ✅ Audit trails (CloudTrail integration)

### SOC 2
- ✅ Security: Encrypted credential storage
- ✅ Availability: Redundant across AZs
- ✅ Confidentiality: Access logging and monitoring
