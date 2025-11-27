variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "instance_type" {
  description = "EC2 instance type for Ollama (minimum t3.large recommended)"
  type        = string
  default     = "t3.large"
}

variable "ollama_model" {
  description = "Ollama model to install (e.g., deepseek-r1:8b, llama3.2:8b)"
  type        = string
  default     = "deepseek-r1:8b"
}

variable "open_webui_port" {
  description = "Port for Open-WebUI interface"
  type        = number
  default     = 8080
}

variable "ollama_api_port" {
  description = "Port for Ollama API"
  type        = number
  default     = 11434
}

variable "s3_bucket_prefix" {
  description = "Prefix for S3 bucket name"
  type        = string
  default     = "ollama-storage"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "ollama-data-table"
}

variable "image_lifecycle_ia_days" {
  description = "Days before transitioning to Infrequent Access storage"
  type        = number
  default     = 90
}

variable "image_lifecycle_glacier_days" {
  description = "Days in IA before transitioning to Glacier"
  type        = number
  default     = 180
}

variable "image_lifecycle_expiration_days" {
  description = "Days in Glacier before expiration"
  type        = number
  default     = 365
}
