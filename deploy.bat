@echo off
REM One-Command Deployment for Ollama + Open-WebUI
REM Double-click this file to deploy!

echo.
echo ========================================
echo   Ollama + Open-WebUI Deployment
echo ========================================
echo.

powershell -ExecutionPolicy Bypass -File deploy.ps1

pause
