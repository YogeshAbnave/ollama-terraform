# Terraform Configuration for Ollama + Open-WebUI EC2 Deployment
# This file automates the creation of EC2 instance with proper configuration

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
  description = "EC2 instance type"
  type        = string
  default     = "t3.xlarge"
  # Options: t3.large, t3.xlarge, c5.2xlarge, g4dn.xlarge
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH (your IP)"
  type        = string
  default     = "0.0.0.0/0" # Change to your IP for security
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

# Data source for latest Ubuntu 22.04 AMI
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

# VPC
resource "aws_vpc" "ollama_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ollama_igw" {
  vpc_id = aws_vpc.ollama_vpc.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

# Public Subnet
resource "aws_subnet" "ollama_subnet" {
  vpc_id                  = aws_vpc.ollama_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name    = "${var.project_name}-subnet"
    Project = var.project_name
  }
}

# Route Table
resource "aws_route_table" "ollama_rt" {
  vpc_id = aws_vpc.ollama_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ollama_igw.id
  }

  tags = {
    Name    = "${var.project_name}-rt"
    Project = var.project_name
  }
}

# Route Table Association
resource "aws_route_table_association" "ollama_rta" {
  subnet_id      = aws_subnet.ollama_subnet.id
  route_table_id = aws_route_table.ollama_rt.id
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Security Group
resource "aws_security_group" "ollama_sg" {
  name        = "${var.project_name}-security-group"
  description = "Security group for Ollama and Open-WebUI"
  vpc_id      = aws_vpc.ollama_vpc.id

  # Allow all inbound traffic
  ingress {
    description = "Allow all inbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
  template = file("${path.module}/user-data-simple.sh.tpl")

  vars = {
    default_model = var.default_model
  }
}

# EC2 Instance
resource "aws_instance" "ollama_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = aws_subnet.ollama_subnet.id

  vpc_security_group_ids = [aws_security_group.ollama_sg.id]

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

# Elastic IP (optional, for static IP)
resource "aws_eip" "ollama_eip" {
  instance = aws_instance.ollama_server.id
  domain   = "vpc"

  tags = {
    Name    = "${var.project_name}-eip"
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
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ollama_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.ollama_eip.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.ollama_server.public_dns
}

output "webui_url" {
  description = "URL to access Open-WebUI"
  value       = "http://${aws_eip.ollama_eip.public_ip}:8080"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.ollama_eip.public_ip}"
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ollama_sg.id
}

output "deployment_log_command" {
  description = "SSH command to view deployment logs"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.ollama_eip.public_ip} 'sudo tail -f /var/log/user-data.log'"
}

output "deployment_status_command" {
  description = "SSH command to check deployment status"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.ollama_eip.public_ip} 'cat /home/ubuntu/deployment-status.txt'"
}
