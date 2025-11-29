# Terraform Configuration for Ollama + Open-WebUI EC2 Deployment
# Production-grade GPU-accelerated deployment with auto-scaling for 3000 concurrent users

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type - GPU instances recommended (g4dn.xlarge, g4dn.2xlarge, g5.xlarge)"
  type        = string
  default     = "g4dn.2xlarge"  # NVIDIA T4 GPU, 8 vCPUs, 32GB RAM -100.30.180.24
}

variable "min_instances" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 2  # High availability
}

variable "max_instances" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 10  # Scale up to handle 3000 concurrent users
}

variable "desired_instances" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 3  # Start with 3 instances
}

variable "use_spot_instances" {
  description = "Use spot instances for cost optimization (not recommended for production)"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH (your IP)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "storage_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 50
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "ollama-webui"
}

variable "git_repo_url" {
  description = "Git repository URL containing deployment scripts"
  type        = string
  default     = "https://github.com/yourusername/ollama-deployment.git"
}

variable "git_branch" {
  description = "Git branch to clone"
  type        = string
  default     = "main"
}

variable "default_model" {
  description = "Default Ollama model to install (1=deepseek-r1:8b, 2=deepseek-r1:14b, etc.)"
  type        = string
  default     = "1"
}

# Provider configuration
provider "aws" {
  region = var.aws_region
}

# Data source for latest Ubuntu 22.04 AMI with GPU support
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get all availability zones in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get subnets in the default VPC across multiple AZs
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Use default VPC with multi-AZ support
locals {
  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids  # Multiple subnets for multi-AZ deployment
  subnet_id  = data.aws_subnets.default.ids[0]  # Select first subnet for single instance
}

# Security Group
resource "aws_security_group" "ollama_sg" {
  name        = "${var.project_name}-security-group"
  description = "Security group for Ollama and Open-WebUI"
  vpc_id      = local.vpc_id

  # SSH access
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Open-WebUI access (port 8080)
  ingress {
    description = "Open-WebUI HTTP access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ollama API access (optional, for external access)
  ingress {
    description = "Ollama API access"
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound internet access
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

# User data script for automatic deployment
data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh.tpl")

  vars = {
    git_repo_url  = var.git_repo_url
    git_branch    = var.git_branch
    default_model = var.default_model
  }
}

# EC2 Instance
resource "aws_instance" "ollama_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = local.subnet_id

  vpc_security_group_ids = [aws_security_group.ollama_sg.id]

  # Assign public IP
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.storage_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name    = "${var.project_name}-root-volume"
      Project = var.project_name
    }
  }

  user_data = data.template_file.user_data.rendered
  
  # Force user_data to run on every instance replacement
  user_data_replace_on_change = true

  # Enable detailed monitoring
  monitoring = true

  # Instance metadata options (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name    = "${var.project_name}-server"
    Project = var.project_name
  }
}

# CloudWatch Alarm for high CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"

  dimensions = {
    InstanceId = aws_instance.ollama_server.id
  }

  tags = {
    Project = var.project_name
  }
}

# Outputs
output "vpc_id" {
  description = "VPC ID being used"
  value       = local.vpc_id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ollama_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.ollama_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.ollama_server.public_dns
}

output "webui_url" {
  description = "URL to access Open-WebUI"
  value       = "http://${aws_instance.ollama_server.public_ip}:8080"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.ollama_server.public_ip}"
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ollama_sg.id
}

output "deployment_log_command" {
  description = "SSH command to view deployment logs"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.ollama_server.public_ip} 'sudo tail -f /var/log/user-data.log'"
}

output "deployment_status_command" {
  description = "SSH command to check deployment status"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.ollama_server.public_ip} 'cat /home/ubuntu/deployment-status.txt'"
}
