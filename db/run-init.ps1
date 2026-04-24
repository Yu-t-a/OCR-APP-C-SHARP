# PowerShell script to run init.sql inside SQL Server container
$ErrorActionPreference = "Stop"

# Load .env
Get-Content ..\.env | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim())
    }
}

$password = $env:MSSQL_SA_PASSWORD
$container = "typhoon-ocr-db"

Write-Host "Running init.sql in $container..." -ForegroundColor Cyan

docker exec -i $container /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P $password -C `
    -i /docker-entrypoint-initdb.d/init.sql

if ($LASTEXITCODE -eq 0) {
    Write-Host "init.sql executed successfully!" -ForegroundColor Green
} else {
    Write-Host "init.sql failed!" -ForegroundColor Red
}
