#!/bin/bash
# Publish playa-ffmpeg to crates.io
# Usage: ./publish.sh [patch|minor|major]

set -e

LEVEL="${1:-patch}"

# Run cargo-release
cargo release "$LEVEL" --execute
