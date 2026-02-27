# EC2 instances and Auto Scaling

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2" {
  name_prefix = "${local.name_prefix}-ec2-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach SSM managed policy for Systems Manager access
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name_prefix = "${local.name_prefix}-ec2-"
  role        = aws_iam_role.ec2.name

  tags = local.common_tags
}

# Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-app-"
  image_id      = var.ec2_ami_id != "" ? var.ec2_ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type = var.ec2_instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    rds_endpoint         = aws_db_instance.main.endpoint
    elasticache_endpoint = aws_elasticache_replication_group.main.configuration_endpoint_address
    database_name        = var.rds_database_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      {
        Name = "${local.name_prefix}-app-instance"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      local.common_tags,
      {
        Name = "${local.name_prefix}-app-volume"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name_prefix               = "${local.name_prefix}-app-"
  vpc_zone_identifier       = aws_subnet.private_app[*].id
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = 2
  max_size         = 6
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-app-instance"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# Auto Scaling Policies - Target Tracking based on CPU
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${local.name_prefix}-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Auto Scaling Policy - Target Tracking based on ALB Request Count
resource "aws_autoscaling_policy" "request_count" {
  name                   = "${local.name_prefix}-request-count-scaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.app.arn_suffix}"
    }
    target_value = 1000.0
  }
}
