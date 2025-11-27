# Security Group for Application Instances
resource "aws_security_group" "app" {
  name        = "ollama-app-sg"
  description = "Security group for Ollama application instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Open-WebUI from ALB"
    from_port       = var.open_webui_port
    to_port         = var.open_webui_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Ollama API from ALB"
    from_port       = var.ollama_api_port
    to_port         = var.ollama_api_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH from anywhere (consider restricting to specific IPs in production)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ollama-app-sg"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "compute"
  }
}
