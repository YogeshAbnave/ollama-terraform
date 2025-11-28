#!/bin/bash

################################################################################
# Ollama and Open-WebUI EC2 Deployment Script
# Consolidated script for installing and managing Ollama with Open-WebUI
# Usage: ./ec2-deploy-ollama.sh [install|cleanup|status]
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages with timestamps
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$timestamp] [$level] $message"
}

print_info() { 
    log_message "INFO" "$1"
    echo -e "${BLUE}ℹ️  $1${NC}"; 
}

print_success() { 
    log_message "SUCCESS" "$1"
    echo -e "${GREEN}✅ $1${NC}"; 
}

print_warning() { 
    log_message "WARNING" "$1"
    echo -e "${YELLOW}⚠️  $1${NC}"; 
}

print_error() { 
    log_message "ERROR" "$1"
    echo -e "${RED}❌ $1${NC}"; 
}

################################################################################
# IDEMPOTENCY CHECK FUNCTIONS
################################################################################

check_ollama_installed() {
    if command -v ollama &> /dev/null; then
        # Check if Ollama is functional
        if ollama --version &> /dev/null; then
            print_info "Ollama is already installed and functional"
            return 0
        else
            print_warning "Ollama is installed but not functional, will reinstall"
            return 1
        fi
    fi
    return 1
}

check_docker_installed() {
    if command -v docker &> /dev/null; then
        # Check if Docker is functional
        if sudo docker ps &> /dev/null; then
            print_info "Docker is already installed and functional"
            return 0
        else
            print_warning "Docker is installed but not functional, will reinstall"
            return 1
        fi
    fi
    return 1
}

check_model_installed() {
    local model_name="$1"
    if ollama list 2>/dev/null | grep -q "$model_name"; then
        print_info "Model $model_name is already installed"
        return 0
    fi
    return 1
}

check_webui_container() {
    if sudo docker ps -a --filter name=open-webui --format '{{.Names}}' | grep -q open-webui; then
        print_info "Open-WebUI container already exists"
        return 0
    fi
    return 1
}

################################################################################
# INSTALLATION FUNCTIONS
################################################################################

install_ollama_webui() {
    print_info "Starting Ollama and Open-WebUI setup..."
    
    # Update system packages
    print_info "Updating system packages..."
    sudo apt update
    
    # Install Ollama with idempotency check
    if check_ollama_installed; then
        print_success "Skipping Ollama installation (already installed)"
    else
        print_info "Installing Ollama..."
        sudo snap install ollama
        
        # Wait for Ollama to initialize
        sleep 3
        
        # Check Ollama version
        print_info "Checking Ollama installation..."
        ollama --version
        print_success "Ollama installed successfully"
    fi
    
    # Install Docker with idempotency check
    if check_docker_installed; then
        print_success "Skipping Docker installation (already installed)"
    else
        print_info "Installing Docker..."
        sudo snap install docker
        print_success "Docker installed successfully"
        
        # Wait for services to start
        print_info "Waiting for services to initialize..."
        sleep 5
    fi
    
    # Model selection
    echo ""
    print_info "Choose an Ollama model to install:"
    echo "1) deepseek-r1:8b (Recommended - 8B parameters, ~4.9GB)"
    echo "2) deepseek-r1:14b (Larger model - 14B parameters, ~8.9GB)"
    echo "3) deepseek-r1:32b (Large model - 32B parameters, ~20GB)"
    echo "4) llama3.2:3b (Lightweight - 3B parameters, ~2GB)"
    echo "5) llama3.2:8b (Balanced - 8B parameters, ~4.7GB)"
    echo "6) qwen2.5:7b (Alternative - 7B parameters, ~4.7GB)"
    echo "7) Custom model (enter manually)"
    echo "8) Skip model installation"
    echo ""
    
    while true; do
        read -p "Enter your choice (1-8): " model_choice
        
        case $model_choice in
            1) MODEL_NAME="deepseek-r1:8b"; break ;;
            2) MODEL_NAME="deepseek-r1:14b"; break ;;
            3) MODEL_NAME="deepseek-r1:32b"; break ;;
            4) MODEL_NAME="llama3.2:3b"; break ;;
            5) MODEL_NAME="llama3.2:8b"; break ;;
            6) MODEL_NAME="qwen2.5:7b"; break ;;
            7)
                read -p "Enter custom model name (e.g., llama3:7b): " MODEL_NAME
                if [[ -n "$MODEL_NAME" ]]; then
                    break
                else
                    print_error "Model name cannot be empty. Please try again."
                fi
                ;;
            8) MODEL_NAME=""; break ;;
            *) print_error "Invalid choice. Please enter 1-8." ;;
        esac
    done
    
    if [[ -n "$MODEL_NAME" ]]; then
        # Check if model is already installed
        if check_model_installed "$MODEL_NAME"; then
            print_success "Skipping model download (already installed)"
        else
            print_info "Downloading and running model: $MODEL_NAME"
            print_warning "This may take several minutes depending on model size..."
            ollama run "$MODEL_NAME" <<< "exit"
            print_success "Model $MODEL_NAME installed successfully"
        fi
    else
        print_warning "Skipping model installation"
    fi
    
    # Run Open-WebUI Docker container with recreation logic
    print_info "Setting up Open-WebUI..."
    
    # If container exists, remove it first to ensure latest configuration
    if check_webui_container; then
        print_info "Removing existing Open-WebUI container..."
        sudo docker rm -f open-webui
        print_success "Existing container removed"
    fi
    
    # Create new container
    print_info "Creating Open-WebUI container..."
    sudo docker run -d \
      --network host \
      --name open-webui \
      -p 3000:8080 \
      -e OLLAMA_BASE_URL=http://localhost:11434 \
      -v open-webui:/app/backend/data \
      --add-host=host.docker.internal:host-gateway \
      --restart always \
      ghcr.io/open-webui/open-webui:main
    
    # Wait for container to start
    print_info "Waiting for Open-WebUI to start..."
    sleep 10
    
    # Get machine IP address
    MACHINE_IP=$(curl -s ifconfig.me)
    
    # Verify Ollama is running
    print_info "Verifying Ollama service..."
    if sudo ss -tnlp | grep -q ollama; then
        print_success "Ollama is running on port 11434"
    else
        print_warning "Ollama might not be running properly"
    fi
    
    # Test Ollama API
    print_info "Testing Ollama API..."
    if curl -s http://localhost:11434/api/tags > /dev/null; then
        print_success "Ollama API is responding"
    else
        print_warning "Ollama API is not responding"
    fi
    
    echo ""
    print_success "Installation complete!"
    echo "📍 Access Open-WebUI at: http://$MACHINE_IP:8080/"
    echo "📍 Or use: http://localhost:8080/"
    echo ""
    print_info "Run './ec2-deploy-ollama.sh cleanup' for management options"
}

################################################################################
# CLEANUP AND MANAGEMENT FUNCTIONS
################################################################################

cleanup_menu() {
    echo ""
    print_info "Ollama and Open-WebUI Management Menu"
    echo "======================================="
    echo ""
    echo "1) Stop Open-WebUI container"
    echo "2) Start Open-WebUI container"
    echo "3) Remove Open-WebUI container completely"
    echo "4) Stop Ollama service"
    echo "5) Start Ollama service"
    echo "6) Remove specific model (free up storage)"
    echo "7) Check Ollama status and API"
    echo "8) Full cleanup (remove everything)"
    echo "9) Exit"
    echo ""
    
    read -p "Enter your choice (1-9): " choice
    
    case $choice in
        1)
            print_info "Stopping Open-WebUI container..."
            sudo docker stop open-webui
            print_success "Open-WebUI container stopped"
            ;;
        2)
            print_info "Starting Open-WebUI container..."
            sudo docker start open-webui
            print_success "Open-WebUI container started"
            MACHINE_IP=$(hostname -I | awk '{print $1}')
            echo "📍 Access at: http://$MACHINE_IP:8080/"
            ;;
        3)
            print_info "Removing Open-WebUI container..."
            sudo docker rm -f open-webui
            print_success "Open-WebUI container removed"
            ;;
        4)
            print_info "Stopping Ollama service..."
            sudo snap stop ollama
            print_success "Ollama service stopped"
            ;;
        5)
            print_info "Starting Ollama service..."
            sudo snap start ollama
            print_success "Ollama service started"
            ;;
        6)
            print_info "Available models:"
            ollama list
            echo ""
            read -p "Enter model name to remove (e.g., deepseek-r1:8b): " model_name
            if [[ -n "$model_name" ]]; then
                print_info "Removing model: $model_name"
                ollama rm "$model_name"
                print_success "Model $model_name removed"
            else
                print_error "No model name provided"
            fi
            ;;
        7)
            check_status
            ;;
        8)
            full_cleanup
            ;;
        9)
            print_info "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please choose 1-9."
            exit 1
            ;;
    esac
    
    echo ""
    print_info "Troubleshooting Tips:"
    echo "• If Ollama is not responding, try: sudo snap restart ollama"
    echo "• If Open-WebUI won't start, check Docker logs: sudo docker logs open-webui"
    echo "• If port 8080 is busy, the container might already be running"
    echo "• Check available models with: ollama list"
    echo "• Monitor system resources with: htop or docker stats"
}

check_status() {
    print_info "Checking Ollama status..."
    echo ""
    echo "Ollama process check:"
    if sudo ss -tnlp | grep ollama; then
        print_success "Ollama is running on port 11434"
    else
        print_error "Ollama is not running on port 11434"
    fi
    echo ""
    echo "Ollama API test:"
    if curl -s http://localhost:11434/api/tags; then
        print_success "Ollama API is responding"
    else
        print_error "Ollama API is not responding"
    fi
    echo ""
    echo "Docker containers:"
    sudo docker ps -a --filter name=open-webui
    echo ""
    echo "Installed models:"
    ollama list
}

full_cleanup() {
    print_warning "This will remove everything! Are you sure? (y/N)"
    read -p "Continue? " confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        print_info "Performing full cleanup..."
        
        # Stop and remove Open-WebUI container
        print_info "Removing Open-WebUI..."
        sudo docker rm -f open-webui 2>/dev/null || true
        
        # Remove Docker volume
        print_info "Removing Docker volume..."
        sudo docker volume rm open-webui 2>/dev/null || true
        
        # Remove any installed models
        print_info "Removing installed models..."
        ollama list | grep -v "NAME" | awk '{print $1}' | while read model; do
            if [[ -n "$model" ]]; then
                ollama rm "$model" 2>/dev/null || true
            fi
        done
        
        # Stop Ollama
        print_info "Stopping Ollama..."
        sudo snap stop ollama 2>/dev/null || true
        
        print_success "Full cleanup completed"
        print_info "To completely remove Ollama and Docker, run:"
        echo "  sudo snap remove ollama"
        echo "  sudo snap remove docker"
    else
        print_error "Cleanup cancelled"
    fi
}

################################################################################
# MAIN SCRIPT LOGIC
################################################################################

show_usage() {
    echo "Usage: $0 [install|cleanup|status]"
    echo ""
    echo "Commands:"
    echo "  install  - Install Ollama, Docker, and Open-WebUI"
    echo "  cleanup  - Show cleanup and management menu"
    echo "  status   - Check status of all services"
    echo ""
    echo "If no command is provided, installation will start."
}

# Main execution
case "${1:-install}" in
    install)
        install_ollama_webui
        ;;
    cleanup)
        cleanup_menu
        ;;
    status)
        check_status
        ;;
    -h|--help)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
