# Environment Setup Script for Typhoon OCR
# Run this script once per machine to set up all required environment variables

param(
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("debug", "production")]
    [string]$Mode = "production"
)

Write-Host "🔧 Typhoon OCR Environment Setup" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# API Key Setup
if ([string]::IsNullOrEmpty($ApiKey)) {
    Write-Host "⚠️  No API Key provided" -ForegroundColor Yellow
    Write-Host "💡 Usage: .\setup-env.ps1 -ApiKey 'sk-your-api-key-here'" -ForegroundColor Gray
    Write-Host "💡 Or run interactively:" -ForegroundColor Gray
    $ApiKey = Read-Host "Enter your OpenTyphoon API Key"
}

if ([string]::IsNullOrEmpty($ApiKey)) {
    Write-Host "❌ API Key is required!" -ForegroundColor Red
    exit 1
}

# Set API Key (User Level - persists across reboots)
[Environment]::SetEnvironmentVariable("TYPHOON_API_KEY", $ApiKey, "User")
Write-Host "✅ TYPHOON_API_KEY set" -ForegroundColor Green

# Set Debug Mode
$debugValue = if ($Mode -eq "debug") { "true" } else { "false" }
[Environment]::SetEnvironmentVariable("OCR_DEBUG_MODE", $debugValue, "User")
Write-Host "✅ OCR_DEBUG_MODE set to: $debugValue" -ForegroundColor Green

# Optional: Set additional OCR settings
$timeout = Read-Host "Enter timeout in seconds (default: 30, press Enter to skip)"
if (![string]::IsNullOrEmpty($timeout)) {
    [Environment]::SetEnvironmentVariable("OCR_TIMEOUT", $timeout, "User")
    Write-Host "✅ OCR_TIMEOUT set to: $timeout" -ForegroundColor Green
}

$maxSize = Read-Host "Enter max image size (default: 10MB, press Enter to skip)"
if (![string]::IsNullOrEmpty($maxSize)) {
    [Environment]::SetEnvironmentVariable("OCR_MAX_SIZE", $maxSize, "User")
    Write-Host "✅ OCR_MAX_SIZE set to: $maxSize" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host "📝 Summary:" -ForegroundColor Cyan
Write-Host "   - API Key: $($ApiKey.Substring(0, 10))..." -ForegroundColor Gray
Write-Host "   - Debug Mode: $Mode" -ForegroundColor Gray
Write-Host ""
Write-Host "🔄 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Close and reopen PowerShell" -ForegroundColor Yellow
Write-Host "   2. Run: cd Typhoon.Console" -ForegroundColor Yellow
Write-Host "   3. Run: dotnet run" -ForegroundColor Yellow
Write-Host ""
Write-Host "✨ Your environment is now ready for Typhoon OCR!" -ForegroundColor Green
