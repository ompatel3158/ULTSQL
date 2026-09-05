# UltSQL Windows 1-Line Installer (PowerShell)
# Automatically downloads ultsql.exe and adds it to User PATH

$ErrorActionPreference = 'Stop'

Write-Host "Installing UltSQL CLI for Windows..." -ForegroundColor Cyan

# Define installation target directory
$installDir = "$env:LocalAppData\UltSQL\bin"
if (!(Test-Path $installDir)) {
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
}

$exePath = Join-Path $installDir "ultsql.exe"
$downloadUrl = "https://github.com/ompatel3158/ULTSQL/releases/latest/download/ultsql-windows.exe"

Write-Host "Downloading latest ultsql.exe binary..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath -UseBasicParsing
} catch {
    Write-Error "Failed to download UltSQL binary from $downloadUrl. Please check https://github.com/ompatel3158/ULTSQL/releases/latest or compile with 'dart compile exe bin/ultsql_cli.dart'."
    exit 1
}

Write-Host "Configuring System User PATH environment variable..." -ForegroundColor Yellow
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$installDir*") {
    $newPath = "$userPath;$installDir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = "$env:Path;$installDir"
    Write-Host "Added $installDir to User PATH." -ForegroundColor Green
} else {
    Write-Host "$installDir is already in User PATH." -ForegroundColor Gray
}

Write-Host ""
Write-Host "UltSQL CLI installed successfully!" -ForegroundColor Green
Write-Host "Type 'ultsql serve' or 'ultsql --help' in any terminal window to begin." -ForegroundColor Cyan
