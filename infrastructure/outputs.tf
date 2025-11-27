output "ollama_alb_dns_name" {
  description = "DNS name of the Ollama Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "ollama_open_webui_url" {
  description = "Open-WebUI URL"
  value       = "http://${aws_lb.main.dns_name}:${var.open_webui_port}"
}

output "ollama_api_url" {
  description = "Ollama API URL"
  value       = "http://${aws_lb.main.dns_name}:${var.ollama_api_port}"
}

output "ollama_dynamodb_table_name" {
  description = "DynamoDB table name for Ollama data"
  value       = aws_dynamodb_table.main.name
}

output "ollama_ssh_key_path" {
  description = "Path to private SSH key for Ollama instances"
  value       = local_file.private_key.filename
}

output "ollama_asg_name" {
  description = "Name of the Ollama Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "ollama_vpc_id" {
  description = "ID of the Ollama VPC"
  value       = aws_vpc.main.id
}

output "ollama_public_subnet_ids" {
  description = "IDs of Ollama public subnets"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "ollama_private_subnet_ids" {
  description = "IDs of Ollama private subnets"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

# Sensitive output for automation
output "ollama_ssh_private_key" {
  description = "Private SSH key in OpenSSH format (sensitive)"
  value       = tls_private_key.ssh.private_key_openssh
  sensitive   = true
}

# S3 Bucket Outputs
output "ollama_s3_bucket_name" {
  description = "Name of the S3 bucket for Ollama storage"
  value       = aws_s3_bucket.images.id
}

output "ollama_s3_bucket_arn" {
  description = "ARN of the S3 bucket for Ollama storage"
  value       = aws_s3_bucket.images.arn
}

output "ollama_s3_bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.images.region
}

# CloudFront Outputs
output "ollama_cloudfront_distribution_id" {
  description = "ID of the Ollama CloudFront distribution"
  value       = aws_cloudfront_distribution.images.id
}

output "ollama_cloudfront_domain_name" {
  description = "Domain name of the Ollama CloudFront distribution"
  value       = aws_cloudfront_distribution.images.domain_name
}

output "ollama_cloudfront_url" {
  description = "Full HTTPS URL for Ollama CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.images.domain_name}"
}

# Monitoring Outputs
output "ollama_cloudwatch_dashboard_name" {
  description = "Name of the Ollama CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.images.dashboard_name
}

output "ollama_sns_topic_arn" {
  description = "ARN of the SNS topic for Ollama alerts"
  value       = aws_sns_topic.image_alerts.arn
}
