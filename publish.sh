#!/bin/bash
# Automated cargo-release wrapper for playa-ffmpeg
# Usage: ./publish.sh [patch|minor|major] [--dry-run]
#
# This script uses cargo-release to automate version bumping and publishing.
# Install: cargo install cargo-release

set -e

LEVEL="${1:-patch}"
DRY_RUN=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        patch|minor|major)
            LEVEL="$arg"
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        *)
            echo "Usage: $0 [patch|minor|major] [--dry-run]"
            exit 1
            ;;
    esac
done

echo "=== playa-ffmpeg Release Script (cargo-release) ==="
echo ""

# Check if cargo-release is installed
echo "Checking for cargo-release..."
if ! command -v cargo-release &> /dev/null; then
    echo "cargo-release not found. Installing..."
    cargo install cargo-release

    if [ $? -ne 0 ]; then
        echo "❌ Failed to install cargo-release"
        exit 1
    fi

    echo "✅ cargo-release installed successfully"
else
    echo "✅ cargo-release is installed"
fi

echo ""

# Build cargo-release command
RELEASE_ARGS=("$LEVEL")

if [ "$DRY_RUN" = true ]; then
    echo "⚠ Running in DRY-RUN mode (no actual changes)"
    echo ""
else
    RELEASE_ARGS+=("--execute")
fi

# Show what will happen
echo "Running: cargo release ${RELEASE_ARGS[*]}"
echo ""

# Run cargo-release
cargo release "${RELEASE_ARGS[@]}"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Release completed successfully!"

    if [ "$DRY_RUN" = false ]; then
        echo ""
        echo "View on crates.io: https://crates.io/crates/playa-ffmpeg"
        echo "View on docs.rs:   https://docs.rs/playa-ffmpeg"
    fi
else
    echo ""
    echo "❌ Release failed!"
    exit 1
fi
