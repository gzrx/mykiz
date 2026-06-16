# MyKIZ Deploy Script
# Usage: .\deploy.ps1 [message]
# Pushes to git, SSHs to server, pulls and rebuilds

param([string]$msg = "deploy")

Write-Host "==> Pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m $msg --allow-empty
git push

Write-Host "==> Deploying on server..." -ForegroundColor Cyan
ssh isaac@ssh.isaacfurqan.me "bash ~/mykiz/deploy.sh"

Write-Host "==> Done!" -ForegroundColor Green
