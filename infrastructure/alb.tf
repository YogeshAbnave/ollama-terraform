# Application Load Balancer
resource "aws_lb" "main" {
  name               = "ollama-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = {
    Name        = "ollama-alb"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "load-balancer"
  }
}

# Target Group for Application
resource "aws_lb_target_group" "app" {
  name     = "ollama-tg"
  port     = var.open_webui_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "ollama-tg"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "load-balancer"
  }
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "ollama-alb-sg"
  description = "Security group for Ollama Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
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
    Name        = "ollama-alb-sg"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "load-balancer"
  }
}
