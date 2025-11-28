#!/bin/bash
################################################################################
# EC2 User Data Script for Ollama + Open-WebUI Deployment
# This script runs on first boot to clone the repository and install everything
################################################################################

set -e  # Exit on any error
set -u  # Exit on undefined variables
set -o pipefail  # Catch pipe failures

# Configuration from Terraform variables
GIT_REPO_URL="${git_repo_url}"
GIT_BRANCH="${git_branch}"
DEFAULT_MODEL="${default_model}"
DEPLOY_DIR="/home/ubuntu"
LOG_FILE="/var/log/user-data.log"
STATUS_FILE="/home/ubuntu/deployment-status.txt"

# Redirect all output to log file
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# Color codes for output (work in logs too)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# LOGGING FUNCTIONS
################################################################################

log_message() {
    local level="$1"
    local component="$2"
    local message="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$timestamp] [$level] [$component] $message"
}

log_info() {
    log_message "INFO" "$1" "$2"
}

log_success() {
    log_message "SUCCESS" "$1" "$2"
}

log_error() {
    log_message "ERROR" "$1" "$2"
}

log_warning() {
    log_message "WARNING" "$1" "$2"
}

################################################################################
# STATUS FILE FUNCTIONS
################################################################################

create_status_file() {
    local status="$1"
    local failed_component="$2"
    local error_message="$3"
    
    cat > "$STATUS_FILE" <<EOF
{
  "status": "$status",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "failed_component": "$failed_component",
  "error_message": "$error_message",
  "components": {
    "git_clone": "$${GIT_CLONE_STATUS:-not_started}",
    "ollama_install": "$${OLLAMA_STATUS:-not_started}",
    "docker_install": "$${DOCKER_STATUS:-not_started}",
    "model_download": "$${MODEL_STATUS:-not_started}",
    "webui_deploy": "$${WEBUI_STATUS:-not_started}"
  },
  "webui_url": "$${WEBUI_URL:-not_available}",
  "log_file": "$LOG_FILE"
}
EOF
    chown ubuntu:ubuntu "$STATUS_FILE"
}

################################################################################
# GIT CLONE FUNCTION WITH RETRY LOGIC
################################################################################

clone_repository() {
    log_info "GIT" "Starting repository clone from $GIT_REPO_URL (branch: $GIT_BRANCH)"
    
    local max_attempts=3
    local delay=10
    local attempt=1
    
    cd "$DEPLOY_DIR"
    
    while [ $attempt -le $max_attempts ]; do
        log_info "GIT" "Clone attempt $attempt of $max_attempts"
        
        if git clone -b "$GIT_BRANCH" "$GIT_REPO_URL" deployment 2>&1; then
            log_success "GIT" "Repository cloned successfully"
            
            # Set proper ownership
            chown -R ubuntu:ubuntu deployment
            log_success "GIT" "File ownership set to ubuntu:ubuntu"
            
            GIT_CLONE_STATUS="success"
            return 0
        else
            log_error "GIT" "Clone attempt $attempt failed"
            
            if [ $attempt -lt $max_attempts ]; then
                log_info "GIT" "Waiting $delay seconds before retry..."
                sleep $delay
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "GIT" "All clone attempts failed after $max_attempts tries"
    log_error "GIT" "Recovery suggestion: Verify repository URL and ensure it is publicly accessible"
    GIT_CLONE_STATUS="failed"
    create_status_file "failed" "git_clone" "Failed to clone repository after $max_attempts attempts"
    return 1
}

################################################################################
# DEPLOYMENT SCRIPT EXECUTION
################################################################################

execute_deployment() {
    log_info "DEPLOY" "Preparing deployment script"
    
    local script_path="$DEPLOY_DIR/deployment/ec2-deploy-ollama.sh"
    
    if [ ! -f "$script_path" ]; then
        log_error "DEPLOY" "Deployment script not found at $script_path"
        create_status_file "failed" "deployment_script" "Deployment script not found in repository"
        return 1
    fi
    
    # Make script executable
    chmod +x "$script_path"
    log_success "DEPLOY" "Deployment script made executable"
    
    # Install directly without using the interactive script
    log_info "DEPLOY" "Installing Ollama and Open-WebUI directly"
    
    # Install Ollama
    log_info "DEPLOY" "Installing Ollama..."
    if ! command -v ollama &> /dev/null; then
        snap install ollama
        sleep 5
        log_success "DEPLOY" "Ollama installed"
    else
        log_info "DEPLOY" "Ollama already installed"
    fi
    
    # Install Docker
    log_info "DEPLOY" "Installing Docker..."
    if ! command -v docker &> /dev/null; then
        snap install docker
        sleep 5
        log_success "DEPLOY" "Docker installed"
    else
        log_info "DEPLOY" "Docker already installed"
    fi
    
    # Wait for services
    sleep 10
    
    # Map model choice to model name
    case "$DEFAULT_MODEL" in
        1) MODEL_NAME="deepseek-r1:8b" ;;
        2) MODEL_NAME="deepseek-r1:14b" ;;
        3) MODEL_NAME="deepseek-r1:32b" ;;
        4) MODEL_NAME="llama3.2:3b" ;;
        5) MODEL_NAME="llama3.2:8b" ;;
        6) MODEL_NAME="qwen2.5:7b" ;;
        *) MODEL_NAME="deepseek-r1:8b" ;;
    esac
    
    # Download model
    log_info "DEPLOY" "Downloading AI model: $MODEL_NAME (this may take 5-10 minutes)"
    if ! ollama list 2>/dev/null | grep -q "$MODEL_NAME"; then
        echo "exit" | ollama run "$MODEL_NAME" || true
        sleep 5
        log_success "DEPLOY" "Model downloaded"
    else
        log_info "DEPLOY" "Model already downloaded"
    fi
    
    # Remove existing container
    if docker ps -a --filter name=open-webui --format '{{.Names}}' | grep -q open-webui; then
        log_info "DEPLOY" "Removing existing Open-WebUI container"
        docker rm -f open-webui
    fi
    
    # Deploy Open-WebUI
    log_info "DEPLOY" "Deploying Open-WebUI container..."
    docker run -d \
      --network host \
      --name open-webui \
      -p 8080:8080 \
      -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
      -v open-webui:/app/backend/data \
      --add-host=host.docker.internal:host-gateway \
      --restart always \
      ghcr.io/open-webui/open-webui:main
    
    sleep 10
    
    # Verify deployment
    if docker ps | grep -q open-webui; then
        log_success "DEPLOY" "Open-WebUI container is running"
        return 0
    else
        log_error "DEPLOY" "Open-WebUI container failed to start"
        docker logs open-webui 2>&1 | tail -20
        return 1
    fi
}

################################################################################
# MOTD CONFIGURATION
################################################################################

setup_motd() {
    log_info "MOTD" "Configuring message of the day"
    
    cat > /etc/update-motd.d/99-ollama-deployment <<'EOF'
#!/bin/bash
echo ""
echo "=========================================="
echo "  Ollama + Open-WebUI Deployment Info"
echo "=========================================="
echo ""
echo "Deployment Log: /var/log/user-data.log"
echo "Status File: /home/ubuntu/deployment-status.txt"
echo ""
if [ -f /home/ubuntu/deployment-status.txt ]; then
    echo "Deployment Status:"
    cat /home/ubuntu/deployment-status.txt | grep -E '"status"|"webui_url"' | sed 's/^/  /'
    echo ""
fi
echo "View logs: sudo tail -f /var/log/user-data.log"
echo "Check status: cat /home/ubuntu/deployment-status.txt"
echo ""
EOF
    
    chmod +x /etc/update-motd.d/99-ollama-deployment
    log_success "MOTD" "Message of the day configured"
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    log_info "MAIN" "=========================================="
    log_info "MAIN" "Starting Ollama + Open-WebUI Deployment"
    log_info "MAIN" "=========================================="
    log_info "MAIN" "Git Repository: $GIT_REPO_URL"
    log_info "MAIN" "Git Branch: $GIT_BRANCH"
    log_info "MAIN" "Default Model: $DEFAULT_MODEL"
    log_info "MAIN" "=========================================="
    
    # Wait for cloud-init to complete
    log_info "MAIN" "Waiting for cloud-init to complete..."
    cloud-init status --wait
    log_success "MAIN" "Cloud-init completed"
    
    # Update system and install git
    log_info "MAIN" "Updating system packages..."
    apt-get update -y
    log_success "MAIN" "System packages updated"
    
    log_info "MAIN" "Installing git..."
    apt-get install -y git
    log_success "MAIN" "Git installed successfully"
    
    # Clone repository
    if ! clone_repository; then
        log_error "MAIN" "Deployment failed at git clone stage"
        exit 1
    fi
    
    # Execute deployment script
    if ! execute_deployment; then
        log_error "MAIN" "Deployment failed at script execution stage"
        exit 1
    fi
    
    # Setup MOTD
    setup_motd
    
    # Get machine IP for final status
    MACHINE_IP=$(curl -s ifconfig.me || echo "unknown")
    WEBUI_URL="http://$MACHINE_IP:8080"
    
    # Create success status file
    GIT_CLONE_STATUS="success"
    OLLAMA_STATUS="success"
    DOCKER_STATUS="success"
    MODEL_STATUS="success"
    WEBUI_STATUS="success"
    create_status_file "success" "" ""
    
    log_success "MAIN" "=========================================="
    log_success "MAIN" "Deployment Complete!"
    log_success "MAIN" "=========================================="
    log_success "MAIN" "WebUI URL: $WEBUI_URL"
    log_success "MAIN" "Access the interface at: $WEBUI_URL"
    log_success "MAIN" "First user to register becomes admin"
    log_success "MAIN" "=========================================="
}

# Run main function
main
