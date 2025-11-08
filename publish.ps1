# Automated cargo-release wrapper for playa-ffmpeg
# Usage: .\publish.ps1 [patch|minor|major] [--dry-run]
#
# This script uses cargo-release to automate version bumping and publishing.
# Install: cargo install cargo-release

param(
    [Parameter(Position=0)]
    [ValidateSet('patch', 'minor', 'major')]
    [string]$Level = 'patch',

    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "=== playa-ffmpeg Release Script (cargo-release) ===" -ForegroundColor Cyan
Write-Host ""

# Check if cargo-release is installed
Write-Host "Checking for cargo-release..." -ForegroundColor Yellow
$cargoRelease = Get-Command cargo-release -ErrorAction SilentlyContinue

if (-not $cargoRelease) {
    Write-Host "cargo-release not found. Installing..." -ForegroundColor Yellow
    cargo install cargo-release

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install cargo-release" -ForegroundColor Red
        exit 1
    }

    Write-Host "cargo-release installed successfully" -ForegroundColor Green
} else {
    Write-Host "cargo-release is installed" -ForegroundColor Green
}

Write-Host ""

# Build cargo-release command
$releaseArgs = @($Level)

if ($DryRun) {
    Write-Host "Running in DRY-RUN mode (no actual changes)" -ForegroundColor Yellow
    Write-Host ""
} else {
    $releaseArgs += "--execute"
}

# Show what will happen
Write-Host "Running: cargo release $($releaseArgs -join ' ')" -ForegroundColor Cyan
Write-Host ""

# Run cargo-release
& cargo release @releaseArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Release completed successfully!" -ForegroundColor Green

    if (-not $DryRun) {
        Write-Host ""
        Write-Host "View on crates.io: https://crates.io/crates/playa-ffmpeg" -ForegroundColor Cyan
        Write-Host "View on docs.rs:   https://docs.rs/playa-ffmpeg" -ForegroundColor Cyan
    }
} else {
    Write-Host ""
    Write-Host "Release failed!" -ForegroundColor Red
    exit 1
}
