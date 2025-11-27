# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "ollama-vpc"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "networking"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "ollama-igw"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "networking"
  }
}

# Public Subnets (for ALB and Frontend)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "ollama-public-subnet-1"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "networking"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "ollama-public-subnet-2"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "networking"
  }
}

# Private Subnets (for Backend)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "ollama-private-subnet-1"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "networking"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "ollama-private-subnet-2"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "networking"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "ollama-nat-eip"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "networking"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name        = "ollama-nat-gateway"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "networking"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "ollama-public-rt"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "networking"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "ollama-private-rt"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "networking"
  }
}

# Route Table Associations - Public
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# VPC Endpoint for DynamoDB (keeps traffic private)
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.${var.aws_region}.dynamodb"
  route_table_ids = [aws_route_table.private.id]

  tags = {
    Name        = "ollama-dynamodb-endpoint"
    Project     = "ollama-infrastructure"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "networking"
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
