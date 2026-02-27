#!/bin/bash
# User data script for EC2 application instances

set -e

# Update system packages
dnf update -y

# Install necessary packages
dnf install -y \
  httpd \
  postgresql15 \
  redis6 \
  amazon-cloudwatch-agent

# Configure environment variables for application
cat > /etc/environment << EOF
RDS_ENDPOINT=${rds_endpoint}
ELASTICACHE_ENDPOINT=${elasticache_endpoint}
DATABASE_NAME=${database_name}
EOF

# Create a simple health check endpoint
mkdir -p /var/www/html
cat > /var/www/html/health << 'EOF'
OK
EOF

# Start and enable httpd
systemctl start httpd
systemctl enable httpd

# CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << 'EOF'
{
  "metrics": {
    "namespace": "ThreeTierApp",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"}
        ],
        "totalcpu": false
      },
      "mem": {
        "measurement": [
          {"name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent"}
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

echo "Application instance setup complete"
