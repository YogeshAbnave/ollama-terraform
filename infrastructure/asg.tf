# Generate SSH Key Pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_openssh
  filename        = "${path.module}/../.ssh/ollama-key"
  file_permission = "0600"
}

# Save public key locally
resource "local_file" "public_key" {
  content         = tls_private_key.ssh.public_key_openssh
  filename        = "${path.module}/../.ssh/ollama-key.pub"
  file_permission = "0644"
}

# AWS Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "ollama-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = {
    Name        = "ollama-key"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "compute"
  }
}

# Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "ollama-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  key_name = aws_key_pair.deployer.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app.id]
  }

  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh", {
    dynamodb_table    = aws_dynamodb_table.main.name
    aws_region        = var.aws_region
    s3_bucket_name    = aws_s3_bucket.images.id
    cloudfront_domain = aws_cloudfront_distribution.images.domain_name
    ollama_model      = var.ollama_model
    open_webui_port   = var.open_webui_port
    ollama_api_port   = var.ollama_api_port
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "ollama-instance"
      Project     = "ollama-infrastructure"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Service     = "compute"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                      = "ollama-asg"
  vpc_zone_identifier       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 1800  # 30 minutes for Ollama model download
  min_size                  = 2
  max_size                  = 10
  desired_capacity          = 2
  force_delete              = true
  wait_for_capacity_timeout = "10m"

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  lifecycle {
    create_before_destroy = true
    ignore_changes        = []  # Don't ignore any changes - enforce desired state
  }

  tag {
    key                 = "Name"
    value               = "ollama-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "ollama-infrastructure"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value               = "compute"
    propagate_at_launch = true
  }
}

# Auto Scaling Policy - Scale Up
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "ollama-scale-up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = aws_autoscaling_group.app.name
}

# CloudWatch Alarm - High CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "ollama-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "40"
  alarm_description   = "Triggers scale-up when CPU utilization exceeds 40%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name        = "ollama-high-cpu"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "monitoring"
  }
}

# Auto Scaling Policy - Scale Down
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "ollama-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

# CloudWatch Alarm - Low CPU
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "ollama-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "Triggers scale-down when CPU utilization is below 30%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name        = "ollama-low-cpu"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "monitoring"
  }
}
