# playa-ffmpeg - Modern FFmpeg Wrapper with vcpkg Integration

**Modified by:** Alex Joss (joss13@gmail.com)

This is a modernized fork with cross-platform build improvements and vcpkg integration.

## Key Modifications

- **vcpkg Integration**: Automatic FFmpeg installation and static linking on all platforms
- **NVENC Support**: Hardware encoding with NVIDIA NVENC/NVDEC (Windows/Linux, enabled by default)
- **Static Linking**: Single standalone binary, no external FFmpeg dependencies required
- **Rust 2024 Edition**: Updated to latest Rust edition with modern syntax
- **FFmpeg 7.1+ Support**: Full support for FFmpeg 7.1 APIs via vcpkg
- **Unified Bootstrap Script**: Single script for building and publishing across all platforms
- **Improved CI/CD**: GitHub Actions with vcpkg caching for fast builds
- **Enhanced Examples**: New video-info tool, improved frame dumping
- **Visual Studio Setup**: Automatic MSVC environment configuration on Windows

## Prerequisites

### vcpkg Installation

This crate uses [vcpkg](https://vcpkg.io/) for FFmpeg dependency management with static linking.

#### Install vcpkg

**Windows:**
```powershell
git clone https://github.com/microsoft/vcpkg.git C:\vcpkg
cd C:\vcpkg
.\bootstrap-vcpkg.bat
setx VCPKG_ROOT "C:\vcpkg"
```

**Linux/macOS:**
```bash
git clone https://github.com/microsoft/vcpkg.git /usr/local/share/vcpkg
cd /usr/local/share/vcpkg
./bootstrap-vcpkg.sh
export VCPKG_ROOT=/usr/local/share/vcpkg
# Add to ~/.bashrc or ~/.zshrc for persistence
```

### Install FFmpeg via vcpkg

**Windows (MSVC):**
```powershell
vcpkg install ffmpeg[core,avcodec,avdevice,avfilter,avformat,swresample,swscale,nvcodec]:x64-windows-static-md
```

**Linux:**
```bash
vcpkg install ffmpeg[core,avcodec,avdevice,avfilter,avformat,swresample,swscale,nvcodec]:x64-linux-release
```

**macOS (Intel):**
```bash
vcpkg install ffmpeg[core,avcodec,avdevice,avfilter,avformat,swresample,swscale]:x64-osx-release
```

**macOS (Apple Silicon):**
```bash
vcpkg install ffmpeg[core,avcodec,avdevice,avfilter,avformat,swresample,swscale]:arm64-osx-release
```

**Note:** `nvcodec` feature is not available on macOS (NVENC is NVIDIA-only). macOS uses VideoToolbox for hardware encoding.

## Quick Start

### Windows
```cmd
bootstrap.cmd build
```

### Linux/macOS
```bash
./bootstrap.sh build
```

See [examples/README.md](examples/README.md) for detailed usage examples.

### Quick Test: List Available Codecs

```bash
# Build and run video-info example
cargo build --example video-info --release

# List all available codecs (hardware + software)
cargo run --example video-info --release -- ls
```

**Output:**
- Video decoders: H264, H265, VP9, AV1, MPEG4, etc.
- Video encoders: libx264, libx265, NVENC (if GPU available), etc.
- Audio decoders: AAC, MP3, Opus, Vorbis, etc.
- Audio encoders: AAC, MP3, Opus, etc.

**Why use this:**
- Verify NVENC is available on your system
- Check which codecs are enabled
- Confirm FFmpeg is properly configured

## Build Options

```bash
bootstrap build           # Build release (default)
bootstrap build --release # Build release (explicit)
bootstrap build --debug   # Build debug
bootstrap test           # Run all tests
```

### Testing

Run tests to verify FFmpeg integration:

```bash
# All tests
bootstrap test

# Or directly with cargo
cargo test --examples
```

**What it does:**
- Verifies FFmpeg libraries are properly linked
- Tests basic codec functionality
- Validates video/audio decoding
- Checks frame extraction and color space conversion

**Test output location:** `target/debug/` or `target/release/`

## Publishing (Maintainers)

```bash
bootstrap crate          # Dry-run (preview changes)
bootstrap crate publish  # Publish to crates.io
```

Uses [cargo-release](https://github.com/crate-ci/cargo-release) - automatically installed on first use.

---

[![Crates.io](https://img.shields.io/crates/v/playa-ffmpeg.svg)](https://crates.io/crates/playa-ffmpeg)
[![Documentation](https://docs.rs/playa-ffmpeg/badge.svg)](https://docs.rs/playa-ffmpeg)
[![build](https://github.com/ssoj13/playa-ffmpeg/workflows/build/badge.svg)](https://github.com/ssoj13/playa-ffmpeg/actions)
[![License](https://img.shields.io/crates/l/playa-ffmpeg.svg)](LICENSE)

This is a fork of [ffmpeg-next](https://crates.io/crates/ffmpeg-next) (originally based on the [ffmpeg](https://crates.io/crates/ffmpeg) crate by [meh.](https://github.com/meh/rust-ffmpeg)).

This fork focuses on modern Rust (2024 edition) with FFmpeg 8.0 support and simplified cross-platform builds via vcpkg.

## Hardware Encoding Support

### NVENC (NVIDIA GPUs)

NVENC support is **enabled by default** on Windows and Linux builds.

**Requirements:**
- NVIDIA GPU with NVENC support (GTX 600+, Quadro Kxxx+, Tesla Kxx+)
- NVIDIA drivers (no CUDA SDK required for compilation)
- `nvcodec` feature in vcpkg FFmpeg installation

**Runtime behavior:**
- On systems **with** NVIDIA GPU: Hardware encoding available
- On systems **without** GPU: Gracefully falls back to CPU encoders
- Headers-only dependency - no runtime CUDA requirement

**Not available on macOS** (NVENC is NVIDIA-specific hardware).

### Platform-Specific Hardware Encoding

- **Windows/Linux**: NVENC via `nvcodec` feature
- **macOS**: VideoToolbox (built into macOS, no additional setup)
- **Intel GPUs**: QuickSync (optional, not enabled by default)

## CI/CD Setup

For GitHub Actions or other CI environments:

### Required Environment Variables

```yaml
env:
  VCPKG_ROOT: /usr/local/share/vcpkg  # Linux/macOS
  # or C:\vcpkg on Windows
  PKG_CONFIG_PATH: /usr/local/share/vcpkg/installed/{triplet}/lib/pkgconfig
```

### Example GitHub Actions Workflow

```yaml
- name: Install FFmpeg via vcpkg
  run: |
    vcpkg install ffmpeg[core,avcodec,avdevice,avfilter,avformat,swresample,swscale,nvcodec]:x64-linux-release

- name: Set environment variables
  run: |
    echo "PKG_CONFIG_PATH=/usr/local/share/vcpkg/installed/x64-linux-release/lib/pkgconfig" >> $GITHUB_ENV
    echo "VCPKG_ROOT=/usr/local/share/vcpkg" >> $GITHUB_ENV

- name: Build
  run: cargo build --release
```

### vcpkg Caching

Speed up CI builds with vcpkg caching:

```yaml
- name: Cache vcpkg
  uses: actions/cache@v4
  with:
    path: |
      /usr/local/share/vcpkg/installed
      ~/.cache/vcpkg
    key: ${{ runner.os }}-vcpkg-x64-linux-release-${{ hashFiles('.github/workflows/build.yml') }}
    restore-keys: |
      ${{ runner.os }}-vcpkg-x64-linux-release-
```

**Result:** First build ~30-40 min, cached builds ~3-5 min.

## Cargo Features

```toml
[features]
default = ["codec", "device", "filter", "format", "software-resampling", "software-scaling", "nvenc"]

# Hardware encoding (nvenc enabled by default)
nvenc = []           # NVIDIA NVENC/NVDEC
vaapi = []           # Linux VA-API (optional)
videotoolbox = []    # macOS VideoToolbox (optional)
qsv = []             # Intel QuickSync (optional)
```

Build without NVENC:
```bash
cargo build --no-default-features --features codec,device,filter,format,software-resampling,software-scaling
```

## Triplet Reference

| Platform | Triplet | Static Linking | NVENC |
|----------|---------|----------------|-------|
| Windows MSVC | `x64-windows-static-md` | ✅ | ✅ |
| Windows MinGW | `x64-mingw-static` | ✅ | ✅ |
| Linux x64 | `x64-linux-release` | ✅ | ✅ |
| macOS Intel | `x64-osx-release` | ✅ | ❌ |
| macOS ARM64 | `arm64-osx-release` | ✅ | ❌ |

## Documentation

- [API docs](https://docs.rs/playa-ffmpeg/) - Rust API documentation
- [FFmpeg user manual](https://ffmpeg.org/ffmpeg-all.html) - Official FFmpeg manual
- [FFmpeg Doxygen](https://ffmpeg.org/doxygen/trunk/) - C API reference
- [vcpkg FFmpeg port](https://github.com/microsoft/vcpkg/tree/master/ports/ffmpeg) - vcpkg FFmpeg features

See [CHANGELOG.md](CHANGELOG.md) for version history and upgrade notes.
