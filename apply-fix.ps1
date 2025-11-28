#!/usr/bin/env pwsh
# Simple one-command fix

Write-Host "`n🔧 Applying Security Group Fix...`n" -ForegroundColor Cyan

# Remove old security group from state
Write-Host "Removing old security group from Terraform state..." -ForegroundColor Yellow
terraform state rm aws_security_group.ollama_sg 2>$null

# Import existing or create new
Write-Host "Applying fixed configuration..." -ForegroundColor Yellow
terraform apply -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Fix applied successfully!" -ForegroundColor Green
    Write-Host "`nYour instance should now be accessible:" -ForegroundColor Cyan
    $ip = terraform output -raw instance_public_ip 2>$null
    if ($ip) {
        Write-Host "  SSH: ssh -i ollama-key.pem ubuntu@$ip" -ForegroundColor White
        Write-Host "  WebUI: http://$ip:8080`n" -ForegroundColor White
    }
} else {
    Write-Host "`n❌ Fix failed. You need to redeploy:" -ForegroundColor Red
    Write-Host "  .\redeploy-with-fix.ps1`n" -ForegroundColor Yellow
}
