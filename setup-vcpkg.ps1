# Unified vcpkg setup script for rust-ffmpeg on Windows
# Usage: .\setup-vcpkg.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== rust-ffmpeg vcpkg setup ===" -ForegroundColor Cyan
Write-Host ""

$VCPKG_ROOT = "C:\vcpkg"
$TRIPLET = "x64-windows-static-md"

Write-Host "Detected: Windows"
Write-Host "vcpkg triplet: $TRIPLET"
Write-Host ""

# Check if vcpkg is already installed
if (Test-Path $VCPKG_ROOT) {
    Write-Host "✓ vcpkg already installed at $VCPKG_ROOT" -ForegroundColor Green
} else {
    Write-Host "📦 Installing vcpkg..." -ForegroundColor Yellow
    git clone https://github.com/microsoft/vcpkg.git $VCPKG_ROOT
    Set-Location $VCPKG_ROOT
    .\bootstrap-vcpkg.bat
    Write-Host "✓ vcpkg installed" -ForegroundColor Green
}

# Set environment variable
Write-Host ""
Write-Host "Setting up environment variables..." -ForegroundColor Yellow

$currentVcpkgRoot = [Environment]::GetEnvironmentVariable("VCPKG_ROOT", "User")
if ($currentVcpkgRoot -ne $VCPKG_ROOT) {
    [Environment]::SetEnvironmentVariable("VCPKG_ROOT", $VCPKG_ROOT, "User")
    $env:VCPKG_ROOT = $VCPKG_ROOT
    Write-Host "✓ Set VCPKG_ROOT=$VCPKG_ROOT" -ForegroundColor Green
} else {
    Write-Host "✓ VCPKG_ROOT already set" -ForegroundColor Green
}

# Check for LLVM (required for bindgen)
Write-Host ""
Write-Host "Checking for LLVM..." -ForegroundColor Yellow

$llvmPath = Get-Command clang -ErrorAction SilentlyContinue
if ($null -eq $llvmPath) {
    Write-Host "⚠ LLVM not found. Installing via Chocolatey..." -ForegroundColor Yellow

    # Check if Chocolatey is installed
    $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
    if ($null -eq $chocoPath) {
        Write-Host "❌ Chocolatey not found. Please install LLVM manually:" -ForegroundColor Red
        Write-Host "  https://releases.llvm.org/download.html" -ForegroundColor Red
        Write-Host "  Or install Chocolatey: https://chocolatey.org/install" -ForegroundColor Red
        exit 1
    }

    choco install llvm -y
    Write-Host "✓ LLVM installed" -ForegroundColor Green

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
} else {
    Write-Host "✓ LLVM found: $($llvmPath.Source)" -ForegroundColor Green
}

# Install FFmpeg via vcpkg
Write-Host ""
Write-Host "📦 Installing FFmpeg ${TRIPLET} via vcpkg..." -ForegroundColor Yellow
Write-Host "This may take 30-60 minutes on first run..." -ForegroundColor Yellow

& "$VCPKG_ROOT\vcpkg.exe" install ffmpeg:$TRIPLET

Write-Host "✓ FFmpeg installed" -ForegroundColor Green

# Return to project directory
Set-Location $PSScriptRoot

# Build rust-ffmpeg
Write-Host ""
Write-Host "🦀 Building rust-ffmpeg..." -ForegroundColor Yellow

cargo build --release

Write-Host ""
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""

# Show binary info
$exePath = "target\release\examples\video_info.exe"
if (Test-Path $exePath) {
    $size = (Get-Item $exePath).Length / 1MB
    Write-Host "Binary example: $exePath"
    Write-Host "Binary size: $([math]::Round($size, 2)) MB"
}

Write-Host ""
Write-Host "Environment:"
Write-Host "  VCPKG_ROOT=$env:VCPKG_ROOT"
Write-Host ""
Write-Host "You can now build with: cargo build --release"
