# Design Document

## Overview

This design document outlines the refactoring and productionization of an AWS infrastructure project for deploying Ollama AI service with Open-WebUI. The current infrastructure uses Terraform to provision a highly available, auto-scaling architecture on AWS, but suffers from inconsistent naming conventions (references to "crud-app", "education-portal"), lacks production-grade features, and needs comprehensive improvements.

The refactored system will:
- Standardize all resource naming with "ollama-" prefix
- Implement production-grade monitoring, logging, security, and backup capabilities
- Provide comprehensive documentation and load testing frameworks
- Support multiple environments (dev, staging, production)
- Include CI/CD integration for automated deployments
- Optimize costs while maintaining high availability and performance

### Current Architecture

The existing infrastructure deploys a multi-tier application on AWS with:
- VPC with public and private subnets across 2 availability zones
- Application Load Balancer (ALB) for traffic distribution
- Auto Scaling Group (ASG) with EC2 instances
- DynamoDB for data storage
- S3 for image storage
- CloudFront CDN for content delivery
- IAM roles and security groups for access control
- CloudWatch for basic monitoring

### Target Architecture

The refactored infrastructure will maintain the same architectural pattern but with:
- Consistent "ollama-" naming across all resources
- Enhanced monitoring with comprehensive CloudWatch dashboards and alarms
- Security hardening with encryption, least-privilege IAM, and security best practices
- Automated backup and disaster recovery capabilities
- Cost optimization through intelligent resource sizing and lifecycle policies
- Multi-environment support with Terraform workspaces
- CI/CD integration for automated testing and deployment

## Architecture

### High-Level Architecture Diagram

```
                                    INTERNET
                                       |
                                       |
                    +------------------+------------------+
                    |                                     |
                    |      Application Load Balancer      |
                    |         (ollama-alb)                |
                    +------------------+------------------+
                                       |
                    +------------------+------------------+
                    |                                     |
        +-----------v-----------+           +-----------v-----------+
        |   PUBLIC SUBNET 1     |           |   PUBLIC SUBNET 2     |
        |   (us-east-1a)       |           |   (us-east-1b)       |
        |   10.0.1.0/24         |           |   10.0.2.0/24         |
        |                       |           |                       |
        |  +----------------+   |           |  +----------------+   |
        |  | Ollama EC2     |   |           |  | Ollama EC2     |   |
        |  | Auto Scaling   |   |           |  | Auto Scaling   |   |
        |  | (2-10 instances)|  |           |  | (2-10 instances)|  |
        |  | Open-WebUI:8080|   |           |  | Open-WebUI:8080|   |
        |  | Ollama:11434   |   |           |  | Ollama:11434   |   |
        |  +----------------+   |           |  +----------------+   |
        +-----------+-----------+           +-----------+-----------+
                    |                                   |
                    |         NAT GATEWAY               |
                    +------------------+----------------+
                                       |
        +------------------------------+------------------------------+
        |                              |                              |
        |                    +---------v---------+                    |
        |                    |                   |                    |
        |                    |  DynamoDB Table   |                    |
        |                    | (ollama-data)     |                    |
        |                    |                   |                    |
        |                    +-------------------+                    |
        |                                                             |
        |                    +-------------------+                    |
        |                    |                   |                    |
        |                    |    S3 Bucket      |                    |
        |                    | (ollama-storage)  |                    |
        |                    |                   |                    |
        |                    +---------+---------+                    |
        |                              |                              |
        |                    +---------v---------+                    |
        |                    |                   |                    |
        |                    |   CloudFront CDN  |                    |
        |                    | (ollama-cdn)      |                    |
        |                    |                   |                    |
        |                    +-------------------+                    |
        +-------------------------------------------------------------+
```

### Network Architecture

**VPC Configuration:**
- CIDR Block: 10.0.0.0/16 (65,536 IP addresses)
- DNS Support: Enabled
- DNS Hostnames: Enabled

**Subnets:**
- Public Subnet 1: 10.0.1.0/24 (AZ-1) - 256 IPs
- Public Subnet 2: 10.0.2.0/24 (AZ-2) - 256 IPs
- Private Subnet 1: 10.0.10.0/24 (AZ-1) - 256 IPs (reserved for future use)
- Private Subnet 2: 10.0.11.0/24 (AZ-2) - 256 IPs (reserved for future use)

**Routing:**
- Public Route Table: Routes 0.0.0.0/0 to Internet Gateway
- Private Route Table: Routes 0.0.0.0/0 to NAT Gateway
- VPC Endpoint: Direct connection to DynamoDB (no internet routing)

### Compute Architecture

**EC2 Instances:**
- Instance Type: Configurable (default: t3.medium for Ollama workloads)
- Operating System: Ubuntu 22.04 LTS
- Software Stack:
  - Ollama (installed via snap)
  - Docker (for Open-WebUI container)
  - Open-WebUI (running on port 8080)
  - CloudWatch Agent (for logs and metrics)

**Auto Scaling Configuration:**
- Minimum Capacity: 2 instances
- Maximum Capacity: 10 instances
- Desired Capacity: 2 instances
- Health Check Type: ELB
- Health Check Grace Period: 300 seconds
- Scaling Policies:
  - Scale Up: Add 2 instances when CPU > 40% for 1 minute
  - Scale Down: Remove 1 instance when CPU < 30% for 2 minutes
  - Cooldown: 180 seconds (scale up), 300 seconds (scale down)

**Load Balancer:**
- Type: Application Load Balancer (Layer 7)
- Scheme: Internet-facing
- Health Check: HTTP GET / (expect 200 OK)
- Health Check Interval: 30 seconds
- Healthy Threshold: 2 consecutive successes
- Unhealthy Threshold: 2 consecutive failures

### Data Architecture

**DynamoDB:**
- Table Name: ollama-data-table
- Billing Mode: PAY_PER_REQUEST (on-demand)
- Primary Key: id (String)
- Point-in-Time Recovery: Enabled
- Encryption: AWS managed keys

**S3 Storage:**
- Bucket Name: ollama-storage-{random-suffix}
- Versioning: Enabled
- Encryption: AES256 (server-side)
- Public Access: Blocked
- Lifecycle Policies:
  - Transition to Standard-IA after 90 days
  - Transition to Glacier after 270 days
  - Expiration after 635 days
  - Permanent retention for tagged objects

**CloudFront CDN:**
- Origin: S3 bucket
- Price Class: PriceClass_100 (US, Canada, Europe)
- Viewer Protocol: Redirect HTTP to HTTPS
- Cache TTL: Default 24 hours, Max 1 year
- Compression: Enabled
- Origin Access Identity: Configured for S3 access

## Components and Interfaces

### 1. Terraform Modules

#### VPC Module (vpc.tf)
**Purpose:** Creates network infrastructure

**Resources:**
- aws_vpc.main
- aws_internet_gateway.main
- aws_subnet.public_1, public_2
- aws_subnet.private_1, private_2 (reserved)
- aws_nat_gateway.main
- aws_eip.nat
- aws_route_table.public, private
- aws_route_table_association (4 associations)
- aws_vpc_endpoint.dynamodb

**Outputs:**
- vpc_id
- public_subnet_ids
- private_subnet_ids

#### Security Groups Module (security-groups.tf)
**Purpose:** Defines firewall rules

**Resources:**
- aws_security_group.alb (ollama-alb-sg)
- aws_security_group.app (ollama-app-sg)

**Rules:**
- ALB SG: Allow 80, 443 from 0.0.0.0/0; Allow all outbound
- App SG: Allow 80 from ALB SG; Allow 22 from 0.0.0.0/0; Allow all outbound

#### ALB Module (alb.tf)
**Purpose:** Load balancing and traffic distribution

**Resources:**
- aws_lb.main (ollama-alb)
- aws_lb_target_group.app (ollama-tg)
- aws_lb_listener.http

**Configuration:**
- Listener Port: 80
- Target Port: 80
- Health Check Path: /

#### ASG Module (asg.tf)
**Purpose:** Auto-scaling compute resources

**Resources:**
- tls_private_key.ssh
- local_file.private_key, public_key
- aws_key_pair.deployer
- aws_launch_template.app
- aws_autoscaling_group.app
- aws_autoscaling_policy.scale_up, scale_down
- aws_cloudwatch_metric_alarm.high_cpu, low_cpu

**User Data Script:**
- Updates system packages
- Installs Ollama via snap
- Installs Docker via snap
- Pulls and runs specified Ollama model
- Launches Open-WebUI Docker container
- Configures CloudWatch agent

#### DynamoDB Module (dynamodb.tf)
**Purpose:** NoSQL database for application data

**Resources:**
- aws_dynamodb_table.main (ollama-data-table)

**Configuration:**
- Billing Mode: PAY_PER_REQUEST
- Hash Key: id (String)
- Point-in-Time Recovery: Enabled

#### S3 Module (s3.tf)
**Purpose:** Object storage for files and images

**Resources:**
- aws_s3_bucket.storage
- aws_s3_bucket_versioning.storage
- aws_s3_bucket_server_side_encryption_configuration.storage
- aws_s3_bucket_public_access_block.storage
- aws_s3_bucket_lifecycle_configuration.storage
- aws_s3_bucket_cors_configuration.storage
- aws_s3_bucket_policy.storage

#### CloudFront Module (cloudfront.tf)
**Purpose:** CDN for content delivery

**Resources:**
- aws_cloudfront_origin_access_identity.storage
- aws_cloudfront_distribution.storage

**Configuration:**
- Origin: S3 bucket
- Cache Behavior: GET, HEAD, OPTIONS
- TTL: 24 hours default

#### IAM Module (iam.tf)
**Purpose:** Identity and access management

**Resources:**
- aws_iam_role.ec2_role (ollama-ec2-role)
- aws_iam_role_policy.dynamodb_policy
- aws_iam_role_policy.s3_policy
- aws_iam_role_policy.cloudwatch_policy (new)
- aws_iam_instance_profile.ec2_profile

**Permissions:**
- DynamoDB: GetItem, PutItem, UpdateItem, DeleteItem, Query, Scan
- S3: PutObject, GetObject, DeleteObject, ListBucket
- CloudWatch: PutMetricData, PutLogEvents, CreateLogGroup, CreateLogStream

#### Monitoring Module (monitoring.tf)
**Purpose:** Observability and alerting

**Resources:**
- aws_cloudwatch_dashboard.ollama
- aws_sns_topic.alerts
- aws_cloudwatch_metric_alarm (multiple alarms)
- aws_cloudwatch_log_group.ollama_app
- aws_cloudwatch_log_group.ollama_service

**Alarms:**
- High CPU (> 40%)
- Low CPU (< 30%)
- High Memory (> 80%)
- S3 Upload Failures
- CloudFront Cache Hit Ratio Low
- ALB Unhealthy Targets
- DynamoDB Throttling

### 2. Load Testing Framework

#### Locust Test Suite (locustfile.py)
**Purpose:** Performance and load testing

**Test Classes:**
- OllamaLoadTest: Simulates realistic Ollama API usage
- ReadHeavyUser: Tests ALB distribution with read operations
- WriteHeavyUser: Tests Auto Scaling with write operations

**Test Scenarios:**
- Model Inference: POST /api/generate
- Chat Completion: POST /api/chat
- Model Listing: GET /api/tags
- Health Check: GET /

**Metrics:**
- Requests per second
- Response time (p50, p95, p99)
- Error rate
- Concurrent users

#### Monitoring Scripts
**Purpose:** Real-time infrastructure monitoring

**Scripts:**
- monitor-scaling.ps1: Watches ASG scaling activities
- monitor-metrics.ps1: Displays CloudWatch metrics
- check-health.ps1: Verifies service health

### 3. Deployment Automation

#### Deployment Scripts
**Purpose:** Automated infrastructure deployment

**Scripts:**
- deploy.ps1: Main deployment orchestration
- destroy.ps1: Safe infrastructure teardown
- validate.ps1: Pre-deployment validation

**Features:**
- Environment selection (dev/staging/prod)
- Prerequisite checking
- Terraform plan review
- Post-deployment verification
- Rollback capability

#### Installation Scripts
**Purpose:** Ollama service installation

**Scripts:**
- ollama-install.sh: Automated Ollama setup
- ollama-cleanup.sh: Service cleanup and troubleshooting

## Data Models

### DynamoDB Schema

**Table: ollama-data-table**

Primary Key:
- id (String, Hash Key)

Attributes (flexible schema):
- user_id (String)
- conversation_id (String)
- model_name (String)
- prompt (String)
- response (String)
- timestamp (Number)
- metadata (Map)

### S3 Object Structure

**Bucket: ollama-storage-{suffix}**

Object Key Pattern:
```
models/{model_name}/{version}/
conversations/{user_id}/{conversation_id}/
logs/{date}/{instance_id}/
backups/{date}/
```

Object Metadata:
- Content-Type
- Cache-Control
- Retention (tag)
- Environment (tag)

### CloudWatch Logs Structure

**Log Groups:**
- /aws/ec2/ollama-app
- /aws/ec2/ollama-service
- /aws/lambda/ollama-functions (future)

**Log Streams:**
- {instance-id}/application.log
- {instance-id}/ollama.log
- {instance-id}/docker.log


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Resource Naming Consistency
*For any* AWS resource created by Terraform, the resource name should start with the "ollama-" prefix followed by a descriptive identifier.
**Validates: Requirements 1.1**

### Property 2: Documentation Naming Consistency
*For any* documentation file, all references to AWS resources should use "ollama-" naming and contain no references to "crud-app" or "education-portal".
**Validates: Requirements 2.2, 2.4**

### Property 3: Documentation Command Accuracy
*For any* command or code example in documentation, the command should be syntactically valid and reference correct "ollama-" prefixed resource names.
**Validates: Requirements 2.5, 2.7**

### Property 4: Terraform Variable Naming
*For any* Terraform variable definition, variables related to Ollama infrastructure should use descriptive names with "ollama_" prefix where semantically appropriate.
**Validates: Requirements 3.1**

### Property 5: Terraform Resource Tagging
*For any* taggable AWS resource created by Terraform, the resource should have tags for "Project", "Environment", "ManagedBy", and "Service".
**Validates: Requirements 3.2**

### Property 6: Terraform Output Naming
*For any* Terraform output definition, outputs should use "ollama_" prefix and include clear descriptions.
**Validates: Requirements 3.3**

### Property 7: Terraform Resource Reference Consistency
*For any* Terraform file, all resource references should use updated "ollama-" naming with no references to old names like "crud-app".
**Validates: Requirements 3.4**

### Property 8: User Data Ollama Installation
*For any* EC2 user data script, the script should contain commands to install Ollama service and Open-WebUI.
**Validates: Requirements 3.7**

### Property 9: Load Test Resource Naming
*For any* load testing script, all AWS resource references (ALB, ASG, etc.) should use "ollama-" prefixed names.
**Validates: Requirements 4.1**

### Property 10: Load Test Documentation Accuracy
*For any* load testing documentation, the content should describe Ollama-specific scenarios and contain no references to generic CRUD operations.
**Validates: Requirements 4.3**

### Property 11: Monitoring Script Resource References
*For any* monitoring script, CloudWatch metric queries should reference "ollama-" prefixed resource names.
**Validates: Requirements 4.4**

### Property 12: Load Test Response Validation
*For any* load test scenario, the test should validate Ollama API response structure and measure inference latency.
**Validates: Requirements 4.5**

### Property 13: Deployment Script Prerequisite Validation
*For any* deployment script execution, the script should validate prerequisites (AWS CLI, Terraform, permissions) before proceeding with deployment operations.
**Validates: Requirements 5.1**

### Property 14: Deployment Script Resource Naming
*For any* deployment script, all resource references and creation commands should use "ollama-" naming.
**Validates: Requirements 5.2**

### Property 15: Deployment Script Output Messaging
*For any* deployment script output, messages should reference Ollama-specific endpoints and services.
**Validates: Requirements 5.3**

### Property 16: Deployment Script Error Handling
*For any* error condition in deployment scripts, the script should provide clear error messages with remediation steps.
**Validates: Requirements 5.4**

### Property 17: Deployment Script Health Verification
*For any* successful deployment script execution, the script should verify Ollama service is running and accessible before completing.
**Validates: Requirements 5.5**

### Property 18: Deployment Script Environment Support
*For any* deployment script invocation, the script should accept and properly handle environment parameters (dev, staging, production).
**Validates: Requirements 5.6**

### Property 19: Cleanup Script Confirmation
*For any* cleanup script execution, the script should prompt for confirmation before removing infrastructure resources.
**Validates: Requirements 5.7**

### Property 20: CloudWatch Log Group Naming
*For any* CloudWatch log group created by Terraform, the log group name should use "ollama-" prefix.
**Validates: Requirements 6.1**

### Property 21: Log Streaming Configuration
*For any* EC2 instance, the CloudWatch agent configuration should stream logs to CloudWatch Logs with defined retention policies.
**Validates: Requirements 6.2**

### Property 22: CloudWatch Alarm SNS Integration
*For any* CloudWatch alarm created by Terraform, the alarm should have SNS topic actions configured for notifications.
**Validates: Requirements 6.3**

### Property 23: ALB Health Check Configuration
*For any* Application Load Balancer, the health check should be configured with an appropriate path for Ollama API endpoints.
**Validates: Requirements 6.6**

### Property 24: Log Retention Configuration
*For any* CloudWatch log group, the retention period should be set to an appropriate value (default 30 days).
**Validates: Requirements 6.7**

### Property 25: Security Group Least Privilege
*For any* security group created by Terraform, ingress rules should specify explicit port ranges and source restrictions, not allowing 0.0.0.0/0 on all ports.
**Validates: Requirements 7.1**

### Property 26: IAM Role Minimum Permissions
*For any* IAM role policy, the policy should grant specific permissions without unnecessary wildcard (*) actions or resources.
**Validates: Requirements 7.2**

### Property 27: Data Encryption at Rest
*For any* data storage resource (S3, DynamoDB), encryption at rest should be enabled.
**Validates: Requirements 7.3**

### Property 28: Data Encryption in Transit
*For any* data transmission endpoint (ALB, CloudFront), TLS/SSL encryption should be enforced.
**Validates: Requirements 7.4**

### Property 29: S3 Security Configuration
*For any* S3 bucket, versioning, encryption, and public access blocking should be enabled.
**Validates: Requirements 7.5**

### Property 30: SSH Key-Based Authentication
*For any* EC2 user data script, SSH configuration should disable password authentication and use key-based authentication only.
**Validates: Requirements 7.6**

### Property 31: ALB Access Logging
*For any* Application Load Balancer, access logging to S3 should be enabled.
**Validates: Requirements 7.7**

### Property 32: No Hardcoded Secrets
*For any* Terraform configuration or script file, no hardcoded secrets (passwords, API keys) should be present in the code.
**Validates: Requirements 7.8**

### Property 33: DynamoDB Point-in-Time Recovery
*For any* DynamoDB table, point-in-time recovery (PITR) should be enabled.
**Validates: Requirements 8.1**

### Property 34: S3 Lifecycle Policies
*For any* S3 bucket used for storage, lifecycle policies should be configured for cost optimization.
**Validates: Requirements 8.2**

### Property 35: Terraform State Versioning
*For any* Terraform backend configuration, the S3 bucket storing state should have versioning enabled.
**Validates: Requirements 8.3**

### Property 36: Backup Cleanup Automation
*For any* backup storage configuration, automated cleanup of old backups should be implemented via lifecycle policies.
**Validates: Requirements 8.7**

### Property 37: S3 Cost Optimization
*For any* S3 bucket, intelligent tiering or lifecycle policies should be configured to reduce storage costs.
**Validates: Requirements 9.3**

### Property 38: CloudFront Cache Configuration
*For any* CloudFront distribution, cache TTL should be set to appropriate values to minimize origin requests.
**Validates: Requirements 9.4**

### Property 39: Multi-AZ Deployment
*For any* Auto Scaling Group, instances should be distributed across multiple availability zones (minimum 2).
**Validates: Requirements 10.1**

### Property 40: Auto Scaling Policy Configuration
*For any* Auto Scaling Group, scaling policies should be defined based on CPU utilization and/or request count metrics.
**Validates: Requirements 10.2**

### Property 41: ALB Health Check Thresholds
*For any* ALB target group, health check thresholds and intervals should be configured with reasonable values.
**Validates: Requirements 10.3**

### Property 42: DynamoDB On-Demand Billing
*For any* DynamoDB table, billing mode should be set to PAY_PER_REQUEST for automatic scaling.
**Validates: Requirements 10.7**

### Property 43: Environment Resource Tagging
*For any* AWS resource, an "Environment" tag should be present with the environment name (dev, staging, production).
**Validates: Requirements 12.3**

### Property 44: Production Deployment Confirmation
*For any* production deployment script execution, explicit approval and confirmation should be required before proceeding.
**Validates: Requirements 12.5**

### Property 45: Environment Indication in Scripts
*For any* deployment script execution, the script should clearly display the target environment and prevent accidental cross-environment operations.
**Validates: Requirements 12.6**

## Error Handling

### Terraform Errors

**State Lock Conflicts:**
- Detection: Terraform detects existing state lock
- Handling: Display lock information and provide commands to force-unlock if necessary
- Prevention: Use DynamoDB for state locking with automatic cleanup

**Resource Creation Failures:**
- Detection: Terraform apply fails with resource-specific error
- Handling: Display detailed error message with AWS error code
- Recovery: Terraform automatically rolls back partial changes
- Prevention: Use terraform plan before apply to catch issues early

**Dependency Violations:**
- Detection: Resource deletion fails due to dependencies
- Handling: Display dependency chain and suggest resolution order
- Recovery: Manual intervention to remove dependencies first
- Prevention: Use depends_on meta-argument to enforce correct order

### Deployment Script Errors

**Missing Prerequisites:**
- Detection: Script checks for AWS CLI, Terraform, required permissions
- Handling: Display specific missing prerequisite with installation instructions
- Recovery: User installs missing tools and re-runs script
- Prevention: Comprehensive prerequisite checking at script start

**Invalid Environment Parameter:**
- Detection: Script validates environment parameter against allowed values
- Handling: Display error message with valid environment options
- Recovery: User re-runs script with correct environment
- Prevention: Use parameter validation and provide clear usage examples

**AWS API Errors:**
- Detection: AWS CLI or SDK returns error response
- Handling: Parse error code and display user-friendly message
- Recovery: Retry with exponential backoff for transient errors
- Prevention: Implement proper error handling and retry logic

### Load Testing Errors

**Connection Failures:**
- Detection: Locust cannot connect to target endpoint
- Handling: Display connection error with endpoint URL
- Recovery: Verify ALB DNS name and security group rules
- Prevention: Validate endpoint accessibility before starting load test

**High Error Rates:**
- Detection: Error rate exceeds threshold (e.g., 5%)
- Handling: Display error distribution and sample error responses
- Recovery: Investigate application logs and infrastructure health
- Prevention: Start with low user count and gradually increase

**Resource Exhaustion:**
- Detection: Instances reach CPU/memory limits
- Handling: Monitor CloudWatch metrics and trigger alarms
- Recovery: Auto Scaling adds capacity automatically
- Prevention: Configure appropriate scaling policies and thresholds

### Infrastructure Runtime Errors

**Health Check Failures:**
- Detection: ALB marks instance as unhealthy
- Handling: Remove instance from load balancer rotation
- Recovery: Auto Scaling launches replacement instance
- Prevention: Configure appropriate health check grace period

**Scaling Failures:**
- Detection: Auto Scaling cannot launch new instances
- Handling: CloudWatch alarm triggers, SNS notification sent
- Recovery: Investigate capacity limits, quotas, or configuration issues
- Prevention: Monitor service quotas and request increases proactively

**Service Unavailability:**
- Detection: All instances fail health checks
- Handling: ALB returns 503 Service Unavailable
- Recovery: Investigate application logs, restart services if needed
- Prevention: Implement proper application health endpoints

## Testing Strategy

### Unit Testing

Unit tests will verify individual components and configurations in isolation:

**Terraform Configuration Tests:**
- Validate Terraform syntax with `terraform validate`
- Check formatting with `terraform fmt -check`
- Lint with tflint for best practices and potential errors
- Verify variable types and constraints
- Test resource naming conventions
- Validate tag presence and values

**Script Tests:**
- Validate shell script syntax with shellcheck
- Test PowerShell scripts with PSScriptAnalyzer
- Verify prerequisite checking logic
- Test error handling paths
- Validate output formatting

**Documentation Tests:**
- Check markdown syntax with markdownlint
- Verify code blocks are properly formatted
- Test that all links are valid
- Ensure consistent terminology usage
- Validate command examples are executable

### Property-Based Testing

Property-based tests will verify universal properties across all inputs using **Terratest** (Go-based testing framework for Terraform):

**Testing Framework:** Terratest (https://terratest.gruntwork.io/)
- Minimum iterations: 100 per property test
- Language: Go
- Integration with Go testing framework

**Property Test Implementation:**
Each property-based test will:
1. Generate random but valid Terraform configurations
2. Apply the configuration to a test AWS account
3. Verify the property holds
4. Clean up resources

**Test Organization:**
- Tests located in `test/` directory
- One test file per Terraform module
- Each test tagged with property number from design doc

**Example Property Test Structure:**
```go
// Feature: ollama-infrastructure-refactor, Property 1: Resource Naming Consistency
func TestProperty1_ResourceNamingConsistency(t *testing.T) {
    // Run 100 iterations
    for i := 0; i < 100; i++ {
        // Generate random configuration
        terraformOptions := generateRandomConfig(t)
        
        // Apply Terraform
        defer terraform.Destroy(t, terraformOptions)
        terraform.InitAndApply(t, terraformOptions)
        
        // Verify all resources have ollama- prefix
        resources := terraform.Show(t, terraformOptions)
        for _, resource := range resources {
            assert.True(t, strings.HasPrefix(resource.Name, "ollama-"))
        }
    }
}
```

### Integration Testing

Integration tests will verify components work together correctly:

**Infrastructure Integration Tests:**
- Deploy complete infrastructure to test AWS account
- Verify all resources are created successfully
- Test connectivity between components (ALB → EC2 → DynamoDB)
- Validate security group rules allow required traffic
- Test Auto Scaling triggers and behavior
- Verify CloudWatch alarms trigger correctly

**End-to-End Tests:**
- Deploy infrastructure
- Install Ollama and Open-WebUI
- Test Ollama API endpoints
- Verify model inference works
- Test load balancer distribution
- Validate monitoring and logging
- Clean up all resources

**Load Testing Integration:**
- Run baseline load test (50 users, 5 minutes)
- Verify no errors under normal load
- Test Auto Scaling triggers at high load
- Validate performance metrics meet requirements
- Test scale-down after load decreases

### Smoke Testing

Smoke tests will verify basic functionality after deployment:

**Post-Deployment Smoke Tests:**
- Verify ALB responds to HTTP requests
- Test Ollama API health endpoint
- Verify Open-WebUI is accessible
- Check CloudWatch logs are being written
- Validate DynamoDB table is accessible
- Test S3 bucket operations
- Verify CloudFront distribution is active

**Automated Smoke Test Script:**
```bash
#!/bin/bash
# smoke-test.sh

ALB_URL=$1

echo "Running smoke tests..."

# Test ALB health
curl -f $ALB_URL/ || exit 1

# Test Ollama API
curl -f $ALB_URL/api/tags || exit 1

# Test Open-WebUI
curl -f $ALB_URL:8080/ || exit 1

echo "All smoke tests passed!"
```

### Performance Testing

Performance tests will validate system meets performance requirements:

**Load Test Scenarios:**
1. **Baseline Test:** 50 users, 5 minutes - establish baseline metrics
2. **Stress Test:** 200 users, 10 minutes - test Auto Scaling triggers
3. **Spike Test:** 0 → 500 users in 1 minute - test rapid scaling
4. **Endurance Test:** 100 users, 1 hour - test stability over time

**Performance Metrics:**
- Response time p50 < 2 seconds
- Response time p95 < 5 seconds
- Response time p99 < 10 seconds
- Error rate < 1%
- Throughput > 100 requests/second
- Auto Scaling response time < 5 minutes

### Security Testing

Security tests will verify infrastructure follows security best practices:

**Automated Security Scans:**
- Run tfsec to scan Terraform for security issues
- Use Checkov for policy-as-code validation
- Scan for hardcoded secrets with git-secrets
- Validate IAM policies with IAM Access Analyzer
- Check security group rules for overly permissive access

**Manual Security Review:**
- Review IAM policies for least privilege
- Verify encryption at rest and in transit
- Check S3 bucket policies and ACLs
- Validate network segmentation
- Review CloudWatch alarm coverage

### Continuous Testing

Tests will be integrated into CI/CD pipeline:

**On Pull Request:**
- Run Terraform validate and fmt check
- Execute unit tests
- Run tfsec security scan
- Generate Terraform plan for review

**On Merge to Main:**
- Deploy to dev environment
- Run integration tests
- Execute smoke tests
- Run baseline load test
- Deploy to staging if all tests pass

**Scheduled Tests:**
- Daily: Run full test suite in dev environment
- Weekly: Run endurance tests
- Monthly: Run disaster recovery tests

## Implementation Notes

### Terraform Best Practices

**Module Organization:**
- Separate modules for logical components (networking, compute, storage, monitoring)
- Use consistent file naming (main.tf, variables.tf, outputs.tf)
- Keep modules focused and reusable
- Document module inputs and outputs

**Variable Management:**
- Use variables for all configurable values
- Provide sensible defaults
- Use validation blocks for input validation
- Document variable purpose and constraints

**State Management:**
- Use remote state backend (S3 + DynamoDB)
- Enable state locking to prevent concurrent modifications
- Use workspaces for environment separation
- Enable state versioning for rollback capability

**Resource Naming:**
- Use name_prefix for resources that need unique names
- Include environment in resource names
- Use consistent naming patterns across all resources
- Tag all resources with standard tags

### Security Hardening

**Network Security:**
- Use private subnets for sensitive resources
- Implement security groups with least privilege
- Use VPC endpoints to avoid internet routing
- Enable VPC Flow Logs for network monitoring

**Data Security:**
- Enable encryption at rest for all data stores
- Use AWS KMS for key management
- Enable encryption in transit (TLS/SSL)
- Implement S3 bucket policies to restrict access

**Access Control:**
- Use IAM roles instead of access keys
- Implement least privilege IAM policies
- Enable MFA for sensitive operations
- Use AWS Organizations for account management

**Monitoring and Auditing:**
- Enable CloudTrail for API logging
- Configure CloudWatch alarms for security events
- Implement log aggregation and analysis
- Set up SNS notifications for critical alerts

### Cost Optimization

**Compute Optimization:**
- Use appropriate instance types for workload
- Implement Auto Scaling to match demand
- Consider Reserved Instances for baseline capacity
- Use Spot Instances for fault-tolerant workloads

**Storage Optimization:**
- Implement S3 lifecycle policies
- Use intelligent tiering for variable access patterns
- Enable S3 compression
- Clean up old snapshots and AMIs

**Network Optimization:**
- Use CloudFront to reduce data transfer costs
- Implement VPC endpoints to avoid NAT Gateway costs
- Optimize data transfer between regions
- Use AWS Direct Connect for high-volume transfers

**Monitoring Costs:**
- Set up billing alarms
- Use AWS Cost Explorer for analysis
- Tag resources for cost allocation
- Review and optimize regularly

### Disaster Recovery

**Backup Strategy:**
- Enable automated backups for all data stores
- Use cross-region replication for critical data
- Test backup restoration regularly
- Document backup and restore procedures

**High Availability:**
- Deploy across multiple availability zones
- Use Auto Scaling for automatic recovery
- Implement health checks and automatic failover
- Design for graceful degradation

**Recovery Procedures:**
- Document step-by-step recovery procedures
- Automate recovery where possible
- Test recovery procedures regularly
- Maintain runbooks for common scenarios

### Operational Excellence

**Monitoring and Alerting:**
- Implement comprehensive CloudWatch dashboards
- Configure alarms for all critical metrics
- Set up SNS notifications for alerts
- Use CloudWatch Insights for log analysis

**Logging:**
- Centralize logs in CloudWatch Logs
- Implement structured logging
- Set appropriate retention periods
- Use log aggregation for analysis

**Automation:**
- Automate infrastructure deployment
- Implement automated testing
- Use CI/CD for continuous delivery
- Automate operational tasks

**Documentation:**
- Maintain up-to-date architecture diagrams
- Document all operational procedures
- Create runbooks for common tasks
- Keep troubleshooting guides current
