#!/bin/zsh
# vcpkg setup script for rust-ffmpeg on macOS
# Optimized for zsh (default shell on macOS)
#
# Usage: ./setup-vcpkg-mac.sh

set -e

echo "=== rust-ffmpeg vcpkg setup (macOS) ==="
echo ""

# Detect architecture
ARCH="$(uname -m)"
if [ "$ARCH" = "arm64" ]; then
    TRIPLET="arm64-osx"
    echo "Detected: Apple Silicon (ARM64)"
else
    TRIPLET="x64-osx"
    echo "Detected: Intel Mac (x64)"
fi

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

# Install system dependencies via Homebrew
echo ""
echo "📦 Installing system dependencies..."

if command -v brew &> /dev/null; then
    echo "Installing dependencies via Homebrew..."
    brew install curl zip unzip gnu-tar pkg-config llvm git nasm
    echo "✓ Dependencies installed"
else
    echo "⚠ Homebrew not found!"
    echo "Please install Homebrew first:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo ""
    echo "Or install dependencies manually:"
    echo "  curl zip unzip gnu-tar pkg-config llvm git nasm"
    exit 1
fi

# Install FFmpeg via vcpkg
echo ""
echo "📦 Installing FFmpeg ${TRIPLET} via vcpkg..."
echo "This may take 30-60 minutes on first run..."

"$VCPKG_ROOT/vcpkg" install ffmpeg:$TRIPLET

echo "✓ FFmpeg installed"

# Set environment variables
echo ""
echo "Setting up environment variables..."

ZSHRC="$HOME/.zshrc"

# Check if VCPKG_ROOT already in .zshrc
if ! grep -q "VCPKG_ROOT" "$ZSHRC"; then
    echo "" >> "$ZSHRC"
    echo "# vcpkg for rust-ffmpeg" >> "$ZSHRC"
    echo "export VCPKG_ROOT=\"$HOME/vcpkg\"" >> "$ZSHRC"
    echo "export PATH=\"\$VCPKG_ROOT:\$PATH\"" >> "$ZSHRC"
    echo "✓ Added VCPKG_ROOT to $ZSHRC"
else
    echo "✓ VCPKG_ROOT already in $ZSHRC"
fi

# Build rust-ffmpeg
echo ""
echo "🦀 Building rust-ffmpeg..."
export VCPKG_ROOT="$HOME/vcpkg"
cargo build --release

echo ""
echo "✅ Setup complete!"
echo ""
echo "Binary location: target/release/"
echo "Binary size:"
ls -lh target/release/libffmpeg_next.* 2>/dev/null || echo "  (library built)"

echo ""
echo "To use in new terminal:"
echo "  export VCPKG_ROOT=\"$HOME/vcpkg\""
echo ""
echo "Or reload your shell config:"
echo "  source $ZSHRC"
echo ""
echo "📝 Note: This script is optimized for zsh (macOS default shell)"
