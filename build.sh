#!/bin/bash
# Unified vcpkg setup script for rust-ffmpeg
# Works on Linux and macOS
#
# Usage: ./build.sh

set -e

echo "=== rust-ffmpeg vcpkg setup ==="
echo ""

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux*)
        PLATFORM="linux"
        TRIPLET="x64-linux"
        ;;
    Darwin*)
        PLATFORM="macos"
        if [ "$ARCH" = "arm64" ]; then
            TRIPLET="arm64-osx"
        else
            TRIPLET="x64-osx"
        fi
        ;;
    *)
        echo "❌ Unsupported OS: $OS"
        exit 1
        ;;
esac

echo "Detected: $OS ($ARCH)"
echo "vcpkg triplet: $TRIPLET"
echo ""

# Check if vcpkg is already installed
if [ -d "$HOME/vcpkg" ]; then
    echo "✓ vcpkg already installed at $HOME/vcpkg"
    VCPKG_ROOT="$HOME/vcpkg"
else
    echo "📦 Installing vcpkg..."
    git clone https://github.com/microsoft/vcpkg.git "$HOME/vcpkg"
    cd "$HOME/vcpkg"
    ./bootstrap-vcpkg.sh
    VCPKG_ROOT="$HOME/vcpkg"
    echo "✓ vcpkg installed"
fi

export VCPKG_ROOT

# Install system dependencies
echo ""
echo "📦 Installing system dependencies..."

if [ "$PLATFORM" = "linux" ]; then
    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        DISTRO="unknown"
    fi

    case "$DISTRO" in
        ubuntu|debian)
            echo "Installing dependencies for Ubuntu/Debian..."
            sudo apt update
            sudo apt install -y curl zip unzip tar pkg-config clang git nasm
            ;;
        fedora|rhel|centos)
            echo "Installing dependencies for Fedora/RHEL..."
            sudo dnf install -y curl zip unzip tar pkg-config clang git nasm
            ;;
        arch|manjaro)
            echo "Installing dependencies for Arch Linux..."
            sudo pacman -S --needed curl zip unzip tar pkg-config clang git nasm
            ;;
        *)
            echo "⚠ Unknown distribution: $DISTRO"
            echo "Please install manually: curl zip unzip tar pkg-config clang git nasm"
            ;;
    esac

elif [ "$PLATFORM" = "macos" ]; then
    # Check if Homebrew is installed
    if command -v brew &> /dev/null; then
        echo "Installing dependencies via Homebrew..."
        brew install curl zip unzip gnu-tar pkg-config llvm git
    else
        echo "⚠ Homebrew not found. Please install dependencies manually:"
        echo "  curl zip unzip gnu-tar pkg-config llvm git"
    fi
fi

echo "✓ System dependencies installed"

# Install FFmpeg via vcpkg
echo ""
echo "📦 Installing FFmpeg $TRIPLET via vcpkg..."
echo "This may take 30-60 minutes on first run..."

"$VCPKG_ROOT/vcpkg" install ffmpeg:$TRIPLET

echo "✓ FFmpeg installed"

# Set environment variables
echo ""
echo "Setting up environment variables..."

SHELL_RC=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

if [ -n "$SHELL_RC" ]; then
    # Check if VCPKG_ROOT already in rc file
    if ! grep -q "VCPKG_ROOT" "$SHELL_RC"; then
        echo "" >> "$SHELL_RC"
        echo "# vcpkg for rust-ffmpeg" >> "$SHELL_RC"
        echo "export VCPKG_ROOT=\"$HOME/vcpkg\"" >> "$SHELL_RC"
        echo "export PATH=\"\$VCPKG_ROOT:\$PATH\"" >> "$SHELL_RC"
        echo "✓ Added VCPKG_ROOT to $SHELL_RC"
    else
        echo "✓ VCPKG_ROOT already in $SHELL_RC"
    fi
fi

# Build rust-ffmpeg
echo ""
echo "🦀 Building rust-ffmpeg library and examples..."
export VCPKG_ROOT="$HOME/vcpkg"
cargo build --release --examples

echo ""
echo "✅ Setup complete!"
echo ""
echo "Binary location: target/release/"
echo "Binary sizes:"
ls -lh target/release/libffmpeg_next.* 2>/dev/null || echo "  (library built)"
ls -lh target/release/examples/video-info 2>/dev/null || true

echo ""
echo "To use in new terminal:"
echo "  export VCPKG_ROOT=\"$HOME/vcpkg\""
echo ""
echo "Or source your shell config:"
if [ -n "$SHELL_RC" ]; then
    echo "  source $SHELL_RC"
fi
