# Design Document

## Overview

This design document outlines the automated EC2 deployment system for Ollama and Open-WebUI. The system enhances the existing Terraform infrastructure by integrating git repository cloning and automated script execution into the EC2 user data initialization process. The design ensures that deployment scripts are always current, installation is fully automated, and users receive immediate access to the WebUI URL upon completion.

The core improvement addresses the current limitation where the user data script references a non-existent GitHub URL. Instead, we'll make the git repository URL configurable and implement robust error handling, logging, and idempotent installation logic.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Workstation                          │
│  ┌──────────────┐      ┌──────────────┐                     │
│  │  Terraform   │─────▶│  AWS CLI     │                     │
│  │  CLI         │      │              │                     │
│  └──────────────┘      └──────────────┘                     │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ terraform apply
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                       AWS Cloud                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              EC2 Instance (Ubuntu 22.04)             │   │
│  │                                                      │   │
│  │  ┌────────────────────────────────────────────┐    │   │
│  │  │  User Data Script (cloud-init)             │    │   │
│  │  │  1. Wait for cloud-init                    │    │   │
│  │  │  2. Clone git repository                   │    │   │
│  │  │  3. Execute ec2-deploy-ollama.sh           │    │   │
│  │  │  4. Log all output                         │    │   │
│  │  └────────────────────────────────────────────┘    │   │
│  │                      │                              │   │
│  │                      ▼                              │   │
│  │  ┌────────────────────────────────────────────┐    │   │
│  │  │  Deployment Script                         │    │   │
│  │  │  - Install Ollama (snap)                   │    │   │
│  │  │  - Install Docker (snap)                   │    │   │
│  │  │  - Download AI model                       │    │   │
│  │  │  - Run Open-WebUI container                │    │   │
│  │  └────────────────────────────────────────────┘    │   │
│  │                      │                              │   │
│  │                      ▼                              │   │
│  │  ┌─────────────┐  ┌──────────────┐                │   │
│  │  │   Ollama    │  │  Open-WebUI  │                │   │
│  │  │  :11434     │◀─│   :8080      │                │   │
│  │  └─────────────┘  └──────────────┘                │   │
│  └──────────────────────────────────────────────────────┘   │
│                             │                                │
│  ┌──────────────────────────┴────────────────────────┐      │
│  │           Elastic IP (Static)                     │      │
│  │           http://<EIP>:8080                       │      │
│  └───────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
                             │
                             │ Access WebUI
                             ▼
                    ┌─────────────────┐
                    │  User Browser   │
                    └─────────────────┘
```

### Component Interaction Flow

1. **Terraform Execution**: User runs `terraform apply` which provisions AWS resources
2. **EC2 Initialization**: Instance boots with user data script
3. **Git Clone**: User data script clones the deployment repository
4. **Script Execution**: Deployment script installs all required software
5. **Service Startup**: Ollama and Open-WebUI services start automatically
6. **URL Output**: Terraform outputs the WebUI URL using the Elastic IP
7. **User Access**: User accesses the WebUI through their browser

## Components and Interfaces

### 1. Terraform Configuration Module

**File**: `terraform-ec2.tf`

**Responsibilities**:
- Define infrastructure resources (VPC, subnet, security groups, EC2 instance, EIP)
- Accept configuration variables including git repository URL
- Generate user data script with proper variable substitution
- Output connection details and WebUI URL

**New Variables**:
```hcl
variable "git_repo_url" {
  description = "Git repository URL containing deployment scripts"
  type        = string
  default     = "https://github.com/user/ollama-deployment.git"
}

variable "git_branch" {
  description = "Git branch to clone"
  type        = string
  default     = "main"
}

variable "default_model" {
  description = "Default Ollama model to install"
  type        = string
  default     = "deepseek-r1:8b"
}
```

**Interface**:
- Input: Variable values from `terraform.tfvars`
- Output: AWS resource IDs, WebUI URL, SSH command, deployment status instructions

### 2. User Data Script

**Embedded in**: `terraform-ec2.tf` as `data.template_file.user_data`

**Responsibilities**:
- Wait for cloud-init to complete
- Clone git repository with retry logic
- Set proper file permissions
- Execute deployment script with default inputs
- Log all operations to `/var/log/user-data.log`
- Create deployment status file

**Key Functions**:
```bash
clone_repository() {
  # Clone with retry logic (3 attempts, 10s delay)
  # Set ownership to ubuntu:ubuntu
  # Validate clone success
}

execute_deployment() {
  # Make script executable
  # Run as ubuntu user with default model selection
  # Capture exit code and log results
}

log_status() {
  # Write deployment status to file
  # Include timestamp, success/failure, errors
}
```

**Interface**:
- Input: Git repository URL, branch, default model (from Terraform variables)
- Output: Log file at `/var/log/user-data.log`, status file at `/home/ubuntu/deployment-status.txt`

### 3. Deployment Script

**File**: `ec2-deploy-ollama.sh`

**Responsibilities**:
- Check for existing installations (idempotency)
- Install Ollama via snap
- Install Docker via snap
- Download and run specified AI model
- Deploy Open-WebUI Docker container
- Verify services are running

**Enhanced Functions**:
```bash
check_existing_installation() {
  # Check if Ollama is installed and functional
  # Check if Docker is installed and functional
  # Check if Open-WebUI container exists
  # Return status for each component
}

install_with_idempotency() {
  # Skip installation if already present and functional
  # Reinstall if present but not functional
  # Fresh install if not present
}

verify_deployment() {
  # Test Ollama API endpoint
  # Test Open-WebUI container health
  # Return overall deployment status
}
```

**Interface**:
- Input: Command line argument (install/cleanup/status), model selection (via stdin or default)
- Output: Console output, service status, exit code

### 4. PowerShell Deployment Script

**File**: `deploy.ps1`

**Responsibilities**:
- Check prerequisites (Terraform, AWS CLI)
- Retrieve user's public IP
- Create/reuse SSH key pair
- Generate `terraform.tfvars` with proper configuration
- Execute Terraform deployment
- Display WebUI URL and save to file
- Copy URL to clipboard and open browser

**Enhanced Features**:
- Wait for deployment completion with progress indicator
- Poll deployment status via SSH (optional)
- Display estimated time remaining
- Handle errors gracefully with actionable messages

**Interface**:
- Input: Command line parameters (region, instance type, storage size)
- Output: Console messages, `PRODUCTION-URL.txt` file, browser launch

### 5. Logging and Monitoring Component

**Responsibilities**:
- Centralize all deployment logs
- Provide structured log format with timestamps
- Create deployment status file for programmatic access
- Update MOTD with deployment information

**Log Structure**:
```
[TIMESTAMP] [LEVEL] [COMPONENT] Message
[2025-11-29 10:15:23] [INFO] [USER-DATA] Starting deployment
[2025-11-29 10:15:25] [INFO] [GIT] Cloning repository from https://...
[2025-11-29 10:15:30] [SUCCESS] [GIT] Repository cloned successfully
[2025-11-29 10:15:35] [INFO] [DEPLOY] Executing deployment script
```

**Status File Format** (`/home/ubuntu/deployment-status.txt`):
```json
{
  "status": "success|failed|in_progress",
  "timestamp": "2025-11-29T10:20:45Z",
  "components": {
    "git_clone": "success",
    "ollama_install": "success",
    "docker_install": "success",
    "model_download": "success",
    "webui_deploy": "success"
  },
  "webui_url": "http://1.2.3.4:8080",
  "errors": []
}
```

## Data Models

### Terraform Variables Model

```hcl
{
  aws_region: string          # AWS region for deployment
  instance_type: string       # EC2 instance type
  storage_size: number        # Root volume size in GB
  key_name: string           # SSH key pair name
  allowed_ssh_cidr: string   # CIDR block for SSH access
  project_name: string       # Project name for tagging
  git_repo_url: string       # Git repository URL
  git_branch: string         # Git branch to clone
  default_model: string      # Default Ollama model
}
```

### Deployment Status Model

```typescript
interface DeploymentStatus {
  status: 'success' | 'failed' | 'in_progress';
  timestamp: string;  // ISO 8601 format
  components: {
    git_clone: ComponentStatus;
    ollama_install: ComponentStatus;
    docker_install: ComponentStatus;
    model_download: ComponentStatus;
    webui_deploy: ComponentStatus;
  };
  webui_url: string;
  errors: string[];
}

type ComponentStatus = 'success' | 'failed' | 'skipped' | 'in_progress';
```

### Terraform Output Model

```hcl
{
  instance_id: string
  instance_public_ip: string
  instance_public_dns: string
  webui_url: string
  ssh_command: string
  security_group_id: string
  deployment_log_command: string
  deployment_status_command: string
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property Reflection

Before defining the final properties, let's identify and eliminate redundancy:

**Redundancy Analysis**:
- Properties 6.1, 6.2, and 6.4 all test idempotency for different components (Ollama, Docker, model). These can be combined into a single comprehensive idempotency property.
- Properties 5.2 and 5.3 both test log message formatting with timestamps. These can be combined into one property about log formatting.
- Properties 3.1 and 7.1 both test string formatting for outputs. While they format different strings, they test the same underlying concern and could be combined.
- Property 7.5 is about consistency of IP usage across outputs, which subsumes the individual output tests.

**Consolidated Properties**:
After reflection, we'll focus on unique, high-value properties that provide comprehensive validation without redundancy.

### Correctness Properties

Property 1: Git clone retry behavior
*For any* git clone operation that fails, the system should retry exactly 3 times with delays between attempts before giving up
**Validates: Requirements 1.3**

Property 2: Script failure logging
*For any* deployment script execution that fails, the system should log the exit code to the log file
**Validates: Requirements 2.5**

Property 3: URL format consistency
*For any* valid IP address, the WebUI URL should be formatted as "http://<ip>:8080" and this format should be consistent across all outputs
**Validates: Requirements 3.1, 7.5**

Property 4: Template variable substitution
*For any* git repository URL provided as a variable, the generated user data script should contain that exact URL in the clone command
**Validates: Requirements 4.2**

Property 5: Log message formatting
*For any* deployment step, log messages should include a timestamp in ISO 8601 format and the step name
**Validates: Requirements 5.2, 5.3**

Property 6: Installation idempotency
*For any* component (Ollama, Docker, model), if the component is already installed and functional, running the installation script should skip that component's installation
**Validates: Requirements 6.1, 6.2, 6.4**

Property 7: Container recreation
*For any* existing Open-WebUI container, running the deployment script should remove the old container before creating a new one
**Validates: Requirements 6.3**

Property 8: Functional verification before skip
*For any* installed component, the system should verify the component is functional (not just present) before skipping installation
**Validates: Requirements 6.5**

Property 9: SSH command formatting
*For any* key name and IP address, the SSH command output should be formatted as "ssh -i <keyname>.pem ubuntu@<ip>"
**Validates: Requirements 7.1**

Property 10: Elastic IP preference
*For any* deployment where both an Elastic IP and ephemeral IP exist, all outputs should use the Elastic IP
**Validates: Requirements 3.5, 7.5**

## Error Handling

### Error Categories and Handling Strategies

#### 1. Git Clone Failures

**Scenarios**:
- Repository URL is invalid or inaccessible
- Network connectivity issues
- Authentication failures
- Repository does not exist

**Handling**:
- Implement retry logic with exponential backoff (3 attempts, 10s delay)
- Log detailed error messages including git error output
- Create failure status file with error details
- Exit user data script with non-zero code to signal failure

**Recovery**:
- User can SSH into instance and manually clone repository
- User can check logs at `/var/log/user-data.log`
- User can re-run deployment script manually

#### 2. Installation Failures

**Scenarios**:
- Snap package installation fails (Ollama, Docker)
- Insufficient disk space
- Package repository unavailable
- Dependency conflicts

**Handling**:
- Check available disk space before installation
- Log snap error output
- Attempt to refresh snap cache and retry once
- Create detailed error status in status file

**Recovery**:
- User can SSH and manually install components
- User can increase instance storage
- User can check system logs for root cause

#### 3. Model Download Failures

**Scenarios**:
- Model not found in Ollama registry
- Insufficient disk space for model
- Network timeout during download
- Ollama service not running

**Handling**:
- Verify Ollama service is running before download
- Check available disk space against model size
- Set reasonable timeout for model download (30 minutes)
- Log download progress and errors

**Recovery**:
- User can SSH and manually download different model
- User can use smaller model
- User can increase storage

#### 4. Container Deployment Failures

**Scenarios**:
- Docker service not running
- Port 8080 already in use
- Insufficient memory
- Image pull failures

**Handling**:
- Verify Docker service is running
- Check if port 8080 is available
- Verify sufficient memory (at least 2GB free)
- Retry image pull once on failure

**Recovery**:
- User can SSH and manually start container
- User can stop conflicting services
- User can upgrade instance type

#### 5. Terraform Failures

**Scenarios**:
- AWS credentials invalid or expired
- Insufficient IAM permissions
- Resource quota exceeded
- Region unavailable

**Handling**:
- Validate AWS credentials before apply
- Provide clear error messages with required permissions
- Suggest alternative regions on quota errors
- Implement graceful rollback on partial failures

**Recovery**:
- User can fix credentials and re-run
- User can request quota increase
- User can choose different region

### Error Logging Format

All errors should be logged in a structured format:

```
[TIMESTAMP] [ERROR] [COMPONENT] Error message
[TIMESTAMP] [ERROR] [COMPONENT] Error details: <detailed error output>
[TIMESTAMP] [ERROR] [COMPONENT] Recovery suggestion: <actionable advice>
```

Example:
```
[2025-11-29T10:15:30Z] [ERROR] [GIT] Failed to clone repository
[2025-11-29T10:15:30Z] [ERROR] [GIT] Error details: fatal: repository 'https://github.com/user/repo.git' not found
[2025-11-29T10:15:30Z] [ERROR] [GIT] Recovery suggestion: Verify repository URL in terraform.tfvars and ensure it is publicly accessible
```

### Status File on Error

When errors occur, the status file should contain:

```json
{
  "status": "failed",
  "timestamp": "2025-11-29T10:15:30Z",
  "failed_component": "git_clone",
  "error_message": "Repository not found",
  "error_details": "fatal: repository 'https://github.com/user/repo.git' not found",
  "recovery_steps": [
    "Verify repository URL in terraform.tfvars",
    "Ensure repository is publicly accessible or add authentication",
    "Check /var/log/user-data.log for detailed logs",
    "Re-run deployment script manually: cd /home/ubuntu && ./ec2-deploy-ollama.sh install"
  ],
  "components": {
    "git_clone": "failed",
    "ollama_install": "not_started",
    "docker_install": "not_started",
    "model_download": "not_started",
    "webui_deploy": "not_started"
  }
}
```

## Testing Strategy

### Overview

The testing strategy employs a dual approach combining unit tests for specific examples and edge cases with property-based tests for universal properties that should hold across all inputs. This comprehensive approach ensures both concrete correctness and general behavioral guarantees.

### Unit Testing

**Framework**: Bash Automated Testing System (bats) for shell scripts, Jest for any JavaScript/TypeScript components

**Unit Test Coverage**:

1. **File Ownership Test**
   - Create test files with incorrect ownership
   - Run ownership-setting function
   - Verify all files have ubuntu:ubuntu ownership
   - **Validates**: Requirements 1.2

2. **Executable Permission Test**
   - Create test script file without execute permission
   - Run permission-setting function
   - Verify file has executable permission (755)
   - **Validates**: Requirements 2.1

3. **Default Input Test**
   - Mock interactive script execution
   - Verify default input "1" is provided
   - Verify script receives correct model selection
   - **Validates**: Requirements 2.3

4. **Success Logging Test**
   - Run deployment with mocked successful execution
   - Verify log contains "Deployment complete!" message
   - **Validates**: Requirements 2.4

5. **URL File Creation Test**
   - Run URL saving function with test URL
   - Verify PRODUCTION-URL.txt exists
   - Verify file contains correct URL
   - **Validates**: Requirements 3.2

6. **Elastic IP Preference Test**
   - Provide both EIP and ephemeral IP
   - Run URL generation function
   - Verify output uses EIP, not ephemeral IP
   - **Validates**: Requirements 3.5

7. **Default Repository URL Test**
   - Run template generation without git_repo_url variable
   - Verify template contains default repository URL
   - **Validates**: Requirements 4.3

8. **Log Redirection Test**
   - Verify user data script includes exec redirection
   - Verify redirection targets /var/log/user-data.log
   - **Validates**: Requirements 5.1

9. **Status File Creation Test**
   - Run deployment completion function
   - Verify deployment-status.txt exists
   - Verify file contains valid JSON with expected fields
   - **Validates**: Requirements 5.4

10. **MOTD Configuration Test**
    - Run MOTD setup function
    - Verify MOTD file contains log location
    - **Validates**: Requirements 5.5

11. **Instance ID Output Test**
    - Run Terraform output generation
    - Verify instance_id output exists
    - **Validates**: Requirements 7.2

12. **Security Group Output Test**
    - Run Terraform output generation
    - Verify security_group_id output exists
    - **Validates**: Requirements 7.3

13. **Log Instructions Output Test**
    - Run Terraform output generation
    - Verify output includes SSH command for viewing logs
    - **Validates**: Requirements 7.4

### Property-Based Testing

**Framework**: QuickCheck for Bash (if available) or custom property test harness using bats with randomized inputs

**Configuration**: Each property test should run a minimum of 100 iterations to ensure comprehensive coverage across the input space.

**Property Test Coverage**:

1. **Property Test: Git Clone Retry Behavior**
   - **Feature: ec2-auto-deploy, Property 1: Git clone retry behavior**
   - Generate random git URLs (some valid, some invalid)
   - Mock git clone to fail
   - Verify retry function is called exactly 3 times
   - Verify delays between retries
   - **Validates**: Requirements 1.3

2. **Property Test: Script Failure Logging**
   - **Feature: ec2-auto-deploy, Property 2: Script failure logging**
   - Generate random exit codes (1-255)
   - Mock script execution to fail with each exit code
   - Verify log file contains the exit code
   - **Validates**: Requirements 2.5

3. **Property Test: URL Format Consistency**
   - **Feature: ec2-auto-deploy, Property 3: URL format consistency**
   - Generate random valid IP addresses
   - Run URL formatting function for each IP
   - Verify all outputs match pattern "http://<ip>:8080"
   - Verify consistency across multiple output functions
   - **Validates**: Requirements 3.1, 7.5

4. **Property Test: Template Variable Substitution**
   - **Feature: ec2-auto-deploy, Property 4: Template variable substitution**
   - Generate random git repository URLs
   - Run template generation with each URL
   - Verify generated template contains exact URL in clone command
   - **Validates**: Requirements 4.2

5. **Property Test: Log Message Formatting**
   - **Feature: ec2-auto-deploy, Property 5: Log message formatting**
   - Generate random step names
   - Run logging function for each step
   - Verify all log messages include ISO 8601 timestamp
   - Verify all log messages include step name
   - **Validates**: Requirements 5.2, 5.3

6. **Property Test: Installation Idempotency**
   - **Feature: ec2-auto-deploy, Property 6: Installation idempotency**
   - For each component (Ollama, Docker, model):
     - Mock component as already installed and functional
     - Run installation script
     - Verify installation function is not called
     - Verify component remains functional
   - **Validates**: Requirements 6.1, 6.2, 6.4

7. **Property Test: Container Recreation**
   - **Feature: ec2-auto-deploy, Property 7: Container recreation**
   - Generate random container configurations
   - Mock existing container for each configuration
   - Run deployment script
   - Verify old container is removed before new one is created
   - **Validates**: Requirements 6.3

8. **Property Test: Functional Verification Before Skip**
   - **Feature: ec2-auto-deploy, Property 8: Functional verification before skip**
   - For each component:
     - Mock component as present but non-functional
     - Run installation script
     - Verify installation function IS called (not skipped)
   - **Validates**: Requirements 6.5

9. **Property Test: SSH Command Formatting**
   - **Feature: ec2-auto-deploy, Property 9: SSH command formatting**
   - Generate random key names and IP addresses
   - Run SSH command formatting function
   - Verify all outputs match pattern "ssh -i <keyname>.pem ubuntu@<ip>"
   - **Validates**: Requirements 7.1

10. **Property Test: Elastic IP Preference**
    - **Feature: ec2-auto-deploy, Property 10: Elastic IP preference**
    - Generate random EIP and ephemeral IP pairs
    - Run all output generation functions
    - Verify all outputs use EIP, none use ephemeral IP
    - **Validates**: Requirements 3.5, 7.5

### Integration Testing

While not part of the automated test suite, integration testing should be performed manually:

1. **End-to-End Deployment Test**
   - Run full Terraform deployment
   - Verify EC2 instance is created
   - Verify all services are running
   - Verify WebUI is accessible
   - Verify model responds to queries

2. **Idempotency Test**
   - Run deployment script twice on same instance
   - Verify second run completes without errors
   - Verify services remain functional

3. **Error Recovery Test**
   - Simulate various failure scenarios
   - Verify error logging is correct
   - Verify recovery instructions are accurate
   - Verify manual recovery procedures work

### Test Execution

**Local Testing**:
```bash
# Run unit tests
bats tests/unit/*.bats

# Run property tests
bats tests/property/*.bats

# Run all tests
bats tests/**/*.bats
```

**CI/CD Testing**:
- Unit and property tests run on every commit
- Integration tests run on pull requests
- Full deployment tests run nightly

### Test Coverage Goals

- Unit test coverage: 80% of functions
- Property test coverage: All identified correctness properties
- Integration test coverage: All major user workflows

## Implementation Notes

### Terraform Template Rendering

The user data script will be rendered using Terraform's `templatefile` function instead of inline template:

```hcl
data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh.tpl")
  vars = {
    git_repo_url   = var.git_repo_url
    git_branch     = var.git_branch
    default_model  = var.default_model
  }
}
```

### Bash Script Best Practices

All bash scripts should follow these practices:
- Use `set -e` to exit on errors
- Use `set -u` to exit on undefined variables
- Use `set -o pipefail` to catch pipe failures
- Implement proper error handling with trap
- Use functions for reusable logic
- Include comprehensive logging

### Security Considerations

1. **Credentials**: Never embed credentials in scripts or Terraform files
2. **SSH Keys**: Ensure proper permissions (400) on key files
3. **Security Groups**: Restrict SSH access to specific IPs
4. **HTTPS**: Consider adding SSL/TLS for production deployments
5. **Secrets Management**: Use AWS Secrets Manager for sensitive data

### Performance Considerations

1. **Parallel Installation**: Where possible, install components in parallel
2. **Model Download**: Use background download with progress monitoring
3. **Caching**: Cache downloaded models and Docker images
4. **Resource Monitoring**: Monitor CPU, memory, and disk during installation

### Maintenance Considerations

1. **Version Pinning**: Pin versions of Ollama, Docker, and models
2. **Update Strategy**: Provide clear upgrade path for existing deployments
3. **Backup**: Implement backup strategy for user data
4. **Monitoring**: Set up CloudWatch alarms for critical metrics

## Future Enhancements

1. **Multi-Region Support**: Deploy across multiple AWS regions
2. **Auto-Scaling**: Implement auto-scaling based on load
3. **HTTPS Support**: Add automatic SSL/TLS certificate provisioning
4. **Custom Models**: Support for custom model uploads
5. **Backup Automation**: Automated backup and restore functionality
6. **Monitoring Dashboard**: Web-based monitoring and management interface
7. **Cost Optimization**: Automatic spot instance management
8. **High Availability**: Multi-AZ deployment with load balancing
