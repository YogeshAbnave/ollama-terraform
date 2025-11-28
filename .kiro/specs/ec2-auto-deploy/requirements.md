# Requirements Document

## Introduction

This feature automates the deployment of Ollama and Open-WebUI on AWS EC2 instances by integrating git repository cloning and automated installation into the Terraform infrastructure-as-code setup. The system will ensure that when an EC2 instance is provisioned, it automatically clones the deployment code from a git repository, executes the installation script, and provides the user with a final accessible URL for the web interface.

## Glossary

- **EC2 Instance**: Amazon Elastic Compute Cloud virtual server
- **Terraform**: Infrastructure-as-code tool for provisioning cloud resources
- **User Data Script**: Initialization script that runs when an EC2 instance first boots
- **Ollama**: Local AI model runtime service
- **Open-WebUI**: Web-based user interface for interacting with AI models
- **Git Repository**: Version control repository containing deployment scripts
- **Elastic IP (EIP)**: Static public IP address assigned to the EC2 instance
- **WebUI URL**: The HTTP endpoint where users access the Open-WebUI interface

## Requirements

### Requirement 1

**User Story:** As a DevOps engineer, I want the EC2 instance to automatically clone the deployment repository on first boot, so that the latest deployment scripts are always used without manual intervention.

#### Acceptance Criteria

1. WHEN the EC2 instance boots for the first time, THEN the system SHALL clone the git repository to the /home/ubuntu directory
2. WHEN the git clone operation completes, THEN the system SHALL set proper file ownership to ubuntu:ubuntu for all cloned files
3. WHEN the git repository is unavailable, THEN the system SHALL log the error and retry up to 3 times with 10-second intervals
4. WHEN all retry attempts fail, THEN the system SHALL log a failure message to /var/log/user-data.log

### Requirement 2

**User Story:** As a DevOps engineer, I want the deployment script to execute automatically after cloning, so that Ollama and Open-WebUI are installed without manual SSH access.

#### Acceptance Criteria

1. WHEN the git repository is successfully cloned, THEN the system SHALL make the ec2-deploy-ollama.sh script executable
2. WHEN the deployment script is made executable, THEN the system SHALL execute it with the install command as the ubuntu user
3. WHEN the deployment script requires user input for model selection, THEN the system SHALL provide default input (option 1 for deepseek-r1:8b)
4. WHEN the deployment script completes successfully, THEN the system SHALL log "Deployment complete!" to /var/log/user-data.log
5. WHEN the deployment script fails, THEN the system SHALL log the error details and exit code to /var/log/user-data.log

### Requirement 3

**User Story:** As a user, I want to receive the final WebUI URL immediately after Terraform completes, so that I know where to access my deployed AI assistant.

#### Acceptance Criteria

1. WHEN Terraform apply completes successfully, THEN the system SHALL output the WebUI URL in the format "http://<elastic-ip>:8080"
2. WHEN the deployment script runs, THEN the system SHALL save the WebUI URL to a file named PRODUCTION-URL.txt in the project directory
3. WHEN running on Windows with PowerShell, THEN the system SHALL copy the WebUI URL to the clipboard
4. WHEN running on Windows with PowerShell, THEN the system SHALL automatically open the WebUI URL in the default browser
5. WHEN the Elastic IP is assigned, THEN the system SHALL use the EIP in the WebUI URL output instead of the ephemeral public IP

### Requirement 4

**User Story:** As a DevOps engineer, I want the Terraform configuration to accept a git repository URL as a variable, so that I can deploy from different repositories or branches.

#### Acceptance Criteria

1. WHEN defining Terraform variables, THEN the system SHALL include a git_repo_url variable with a default value
2. WHEN the git_repo_url variable is provided, THEN the system SHALL use it in the user data script for cloning
3. WHEN the git_repo_url variable is not provided, THEN the system SHALL use a sensible default repository URL
4. WHEN the git repository requires authentication, THEN the system SHALL support HTTPS URLs with embedded credentials or SSH URLs with key-based authentication

### Requirement 5

**User Story:** As a system administrator, I want comprehensive logging of the deployment process, so that I can troubleshoot issues when the automated deployment fails.

#### Acceptance Criteria

1. WHEN the user data script executes, THEN the system SHALL redirect all stdout and stderr to /var/log/user-data.log
2. WHEN each deployment step begins, THEN the system SHALL log a timestamped message indicating the step name
3. WHEN each deployment step completes, THEN the system SHALL log a timestamped success or failure message
4. WHEN the deployment completes, THEN the system SHALL create a status file at /home/ubuntu/deployment-status.txt with the final result
5. WHEN accessing the EC2 instance via SSH, THEN the system SHALL display the deployment log location in the MOTD (message of the day)

### Requirement 6

**User Story:** As a user, I want the deployment to be idempotent, so that I can re-run the deployment script without causing errors or duplicate installations.

#### Acceptance Criteria

1. WHEN the deployment script runs and Ollama is already installed, THEN the system SHALL skip the Ollama installation step
2. WHEN the deployment script runs and Docker is already installed, THEN the system SHALL skip the Docker installation step
3. WHEN the deployment script runs and the Open-WebUI container already exists, THEN the system SHALL remove and recreate it with the latest configuration
4. WHEN the deployment script runs and a model is already downloaded, THEN the system SHALL skip the model download step
5. WHEN checking for existing installations, THEN the system SHALL verify the service is functional before skipping installation

### Requirement 7

**User Story:** As a DevOps engineer, I want the Terraform outputs to include SSH connection details and deployment status, so that I can quickly access and verify the instance.

#### Acceptance Criteria

1. WHEN Terraform apply completes, THEN the system SHALL output the SSH command with the correct key file and IP address
2. WHEN Terraform apply completes, THEN the system SHALL output the instance ID for AWS console reference
3. WHEN Terraform apply completes, THEN the system SHALL output the security group ID for network troubleshooting
4. WHEN Terraform apply completes, THEN the system SHALL output instructions for checking deployment logs via SSH
5. WHEN the Elastic IP is assigned, THEN the system SHALL use the EIP in all output commands and URLs
