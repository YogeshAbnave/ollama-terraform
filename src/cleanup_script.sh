#!/bin/bash

# Ollama and Open-WebUI Cleanup Script
# This script provides cleanup and troubleshooting options

echo "🧹 Ollama and Open-WebUI Cleanup Script"
echo "======================================="
echo ""
echo "Choose an option:"
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
        echo "🛑 Stopping Open-WebUI container..."
        sudo docker stop open-webui
        echo "✅ Open-WebUI container stopped"
        ;;
    2)
        echo "▶️  Starting Open-WebUI container..."
        sudo docker start open-webui
        echo "✅ Open-WebUI container started"
        echo "📍 Access at: http://$(hostname -I | awk '{print $1}'):8080/"
        ;;
    3)
        echo "🗑️  Removing Open-WebUI container..."
        sudo docker rm -f open-webui
        echo "✅ Open-WebUI container removed"
        ;;
    4)
        echo "🛑 Stopping Ollama service..."
        sudo snap stop ollama
        echo "✅ Ollama service stopped"
        ;;
    5)
        echo "▶️  Starting Ollama service..."
        sudo snap start ollama
        echo "✅ Ollama service started"
        ;;
    6)
        echo "📋 Available models:"
        ollama list
        echo ""
        read -p "Enter model name to remove (e.g., deepseek-r1:8b): " model_name
        if [[ -n "$model_name" ]]; then
            echo "🗑️  Removing model: $model_name"
            ollama rm "$model_name"
            echo "✅ Model $model_name removed"
        else
            echo "❌ No model name provided"
        fi
        ;;
    7)
        echo "🔍 Checking Ollama status..."
        echo ""
        echo "Ollama process check:"
        if sudo ss -tnlp | grep ollama; then
            echo "✅ Ollama is running on port 11434"
        else
            echo "❌ Ollama is not running on port 11434"
        fi
        echo ""
        echo "Ollama API test:"
        if curl -s http://localhost:11434/api/tags; then
            echo "✅ Ollama API is responding"
        else
            echo "❌ Ollama API is not responding"
        fi
        echo ""
        echo "Docker containers:"
        sudo docker ps -a --filter name=open-webui
        ;;
    8)
        echo "⚠️  This will remove everything! Are you sure? (y/N)"
        read -p "Continue? " confirm
        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            echo "🗑️  Performing full cleanup..."
            
            # Stop and remove Open-WebUI container
            echo "Removing Open-WebUI..."
            sudo docker rm -f open-webui 2>/dev/null || true
            
            # Remove Docker volume
            echo "Removing Docker volume..."
            sudo docker volume rm open-webui 2>/dev/null || true
            
            # Remove any installed models
            echo "Removing installed models..."
            ollama list | grep -v "NAME" | awk '{print $1}' | while read model; do
                if [[ -n "$model" ]]; then
                    ollama rm "$model" 2>/dev/null || true
                fi
            done
            
            # Stop Ollama
            echo "Stopping Ollama..."
            sudo snap stop ollama 2>/dev/null || true
            
            # Optional: Remove Ollama and Docker (uncomment if needed)
            # echo "Removing Ollama and Docker..."
            # sudo snap remove ollama
            # sudo snap remove docker
            
            echo "✅ Full cleanup completed"
        else
            echo "❌ Cleanup cancelled"
        fi
        ;;
    9)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid option. Please choose 1-9."
        exit 1
        ;;
esac

echo ""
echo "🔧 Troubleshooting Tips:"
echo "• If Ollama is not responding, try: sudo snap restart ollama"
echo "• If Open-WebUI won't start, check Docker logs: sudo docker logs open-webui"
echo "• If port 8080 is busy, the container might already be running"
echo "• Check available models with: ollama list"
echo "• Monitor system resources with: htop or docker stats"