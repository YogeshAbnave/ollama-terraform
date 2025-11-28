# Implementation Plan

- [x] 1. Update Terraform configuration with new variables


  - Add git_repo_url variable with default value
  - Add git_branch variable with default "main"
  - Add default_model variable with default "deepseek-r1:8b"
  - Update terraform.tfvars.example with new variables
  - _Requirements: 4.1, 4.2, 4.3_



- [ ] 2. Create user data template file
  - Create user-data.sh.tpl template file
  - Implement cloud-init wait logic
  - Implement git clone function with retry logic (3 attempts, 10s delay)
  - Implement file ownership setting (ubuntu:ubuntu)
  - Implement deployment script execution with default input
  - Add comprehensive logging to /var/log/user-data.log
  - Create deployment status file on completion
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 2.5, 5.1, 5.2, 5.3, 5.4_

- [ ]* 2.1 Write property test for git clone retry behavior
  - **Property 1: Git clone retry behavior**
  - **Validates: Requirements 1.3**

- [ ]* 2.2 Write property test for script failure logging
  - **Property 2: Script failure logging**
  - **Validates: Requirements 2.5**

- [ ]* 2.3 Write unit tests for user data script functions
  - Test file ownership setting function
  - Test executable permission setting function
  - Test default input provision
  - Test success logging



  - Test log redirection setup
  - _Requirements: 1.2, 2.1, 2.3, 2.4, 5.1_

- [ ] 3. Update Terraform to use template file
  - Replace inline user_data with templatefile function
  - Pass variables to template (git_repo_url, git_branch, default_model)
  - Verify template rendering works correctly
  - _Requirements: 4.2_

- [ ]* 3.1 Write property test for template variable substitution
  - **Property 4: Template variable substitution**


  - **Validates: Requirements 4.2**

- [ ]* 3.2 Write unit test for default repository URL
  - **Validates: Requirements 4.3**

- [ ] 4. Enhance deployment script with idempotency
  - Add check_existing_installation function for Ollama
  - Add check_existing_installation function for Docker
  - Add check_existing_installation function for models
  - Add functional verification for each component
  - Implement skip logic when component is already functional
  - Implement container recreation logic for Open-WebUI
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ]* 4.1 Write property test for installation idempotency
  - **Property 6: Installation idempotency**
  - **Validates: Requirements 6.1, 6.2, 6.4**

- [x]* 4.2 Write property test for container recreation


  - **Property 7: Container recreation**
  - **Validates: Requirements 6.3**

- [ ]* 4.3 Write property test for functional verification
  - **Property 8: Functional verification before skip**
  - **Validates: Requirements 6.5**

- [ ] 5. Implement structured logging system
  - Create log_message function with timestamp formatting (ISO 8601)

  - Create log_error function with error details
  - Create log_success function for completion messages
  - Update all script sections to use structured logging
  - _Requirements: 5.2, 5.3_

- [ ]* 5.1 Write property test for log message formatting
  - **Property 5: Log message formatting**
  - **Validates: Requirements 5.2, 5.3**

- [x] 6. Create deployment status file generator


  - Implement create_status_file function


  - Generate JSON status with all component states
  - Include error details on failure
  - Include recovery steps on failure
  - Write status file to /home/ubuntu/deployment-status.txt
  - _Requirements: 5.4_

- [ ]* 6.1 Write unit test for status file creation
  - **Validates: Requirements 5.4**

- [ ] 7. Update Terraform outputs
  - Add deployment_log_command output with SSH command to view logs
  - Add deployment_status_command output with SSH command to view status
  - Ensure all outputs use Elastic IP instead of ephemeral IP
  - Update webui_url output to use EIP
  - Update ssh_command output to use EIP
  - _Requirements: 3.1, 3.5, 7.1, 7.4, 7.5_

- [ ]* 7.1 Write property test for URL format consistency
  - **Property 3: URL format consistency**
  - **Validates: Requirements 3.1, 7.5**



- [ ]* 7.2 Write property test for SSH command formatting
  - **Property 9: SSH command formatting**
  - **Validates: Requirements 7.1**

- [ ]* 7.3 Write property test for Elastic IP preference
  - **Property 10: Elastic IP preference**
  - **Validates: Requirements 3.5, 7.5**

- [ ]* 7.4 Write unit tests for Terraform outputs
  - Test instance_id output exists

  - Test security_group_id output exists
  - Test log instructions output exists
  - _Requirements: 7.2, 7.3, 7.4_

- [ ] 8. Enhance PowerShell deployment script
  - Update deploy.ps1 to handle new variables
  - Add git_repo_url to terraform.tfvars generation
  - Implement URL saving to PRODUCTION-URL.txt
  - Add clipboard copy functionality (with error handling)

  - Add browser launch functionality (with error handling)
  - Display deployment status instructions
  - _Requirements: 3.2, 3.3, 3.4_

- [ ]* 8.1 Write unit test for URL file creation
  - **Validates: Requirements 3.2**

- [x] 9. Implement MOTD configuration


  - Create MOTD setup function in user data script
  - Add deployment log location to MOTD
  - Add deployment status file location to MOTD
  - Add WebUI URL to MOTD
  - _Requirements: 5.5_




- [ ]* 9.1 Write unit test for MOTD configuration
  - **Validates: Requirements 5.5**

- [ ] 10. Add comprehensive error handling
  - Implement error handling for git clone failures
  - Implement error handling for installation failures
  - Implement error handling for model download failures
  - Implement error handling for container deployment failures
  - Create detailed error status in status file for each failure type
  - Add recovery suggestions to error logs
  - _Requirements: 1.3, 1.4, 2.5_

- [ ] 11. Update documentation
  - Update README.md with new variables
  - Update COMPLETE-GUIDE.md with troubleshooting for new features
  - Update terraform.tfvars.example with all new variables
  - Add comments to user-data.sh.tpl explaining each section
  - Document deployment status file format
  - Document error recovery procedures

- [ ] 12. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Create test infrastructure
  - Set up bats testing framework
  - Create test directory structure (tests/unit, tests/property)
  - Create test helper functions for mocking
  - Create test fixtures for common scenarios
  - _Requirements: All testing requirements_

- [ ] 14. Final integration verification
  - Perform manual end-to-end deployment test
  - Verify all outputs are correct
  - Verify WebUI is accessible
  - Verify deployment status file is created
  - Verify logs are comprehensive
  - Verify idempotency by running deployment twice
  - Test error scenarios and recovery procedures
