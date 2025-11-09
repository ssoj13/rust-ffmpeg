# FFmpeg in CI: Hardware Encoding Support — Findings & Plan

This document summarizes how FFmpeg is sourced in CI vs local builds, whether those binaries include hardware encoders, how to verify, and recommended adjustments.

## 1) Sources of FFmpeg binaries

- Linux (GitHub Actions)
  - Source: SourceForge archive `ffmpeg-8.0-linux-clang-default`.
  - Workflow: `.github/workflows/build.yml` — downloads and extracts, sets `FFMPEG_DIR`.
  - Notes: Binary contents/flags depend on how that archive was built.

- macOS (GitHub Actions)
  - Source: Homebrew `brew install ffmpeg`.
  - Workflow: `.github/workflows/build.yml`.
  - Notes: Homebrew bottles typically include VideoToolbox support.

- Windows (GitHub Actions)
  - Source: gyan.dev `ffmpeg-release-full-shared.7z` ("full" shared build).
  - Workflow: `.github/workflows/build.yml` — unpacks, sets `FFMPEG_DIR`, adds `bin` to `PATH`.
  - Notes: These "full" builds usually include NVENC/QSV/AMF.

- Local builds
  - Source: vcpkg. `build.rs` attempts `vcpkg::find_package("ffmpeg")` and, if absent, runs `vcpkg install ffmpeg:<triplet>`.
  - Notes: No explicit vcpkg features enabled here; HW encoders are typically off unless features are specified during `vcpkg install`.

## 2) Hardware encoder support assessment (current setup)

- Windows (gyan.dev "full shared")
  - Likely YES: typically includes `h264_nvenc`, `hevc_nvenc`, `h264_qsv`/`hevc_qsv`, `h264_amf`/`hevc_amf`.
  - Caveat: CI runners don’t expose GPUs, so presence ≠ usable at runtime in CI.

- macOS (Homebrew)
  - YES (VideoToolbox): `h264_videotoolbox`, `hevc_videotoolbox` are normally available.

- Linux (SourceForge archive)
  - Unclear/likely limited: generic "clang-default" builds often exclude NVENC/AMF/QSV; VAAPI may or may not be present.

- Local via vcpkg (default call)
  - Typically NO dedicated HW encoders: need explicit features in `vcpkg install` (e.g., `nvcodec`, `qsv`, `amf`, `vaapi`).

## 3) How to verify in CI (add a diagnostic step)

Run after FFmpeg is installed to list encoders and hwaccels.

- Common (Linux/macOS):
  - `ffmpeg -hide_banner -encoders | grep -Ei "nvenc|qsv|amf|vaapi|videotoolbox"`
  - `ffmpeg -hide_banner -hwaccels`

- Windows (PowerShell):
  - `ffmpeg -hide_banner -encoders | findstr /R /I "nvenc qsv amf vaapi videotoolbox"`
  - `ffmpeg -hide_banner -hwaccels`

This yields a definitive yes/no per platform for the current binaries.

## 4) Recommendations

- Keep Windows CI source as-is (gyan "full"): good coverage of NVENC/QSV/AMF; use diagnostics to confirm.

- macOS: keep Homebrew; likely VideoToolbox-ready. Confirm with diagnostics.

- Linux: decide desired HW backends, then standardize source:
  - Option A (vcpkg everywhere): install with features:
    - NVIDIA: `vcpkg install ffmpeg[nvcodec,openssl,zlib]:x64-linux`
    - Intel QSV: add `qsv`/oneVPL feature as available in the current port.
    - VAAPI: add `vaapi` feature.
  - Option B (custom/prebuilt tarball): provide/build an FFmpeg archive with required flags (e.g., `--enable-nvenc`, `--enable-libmfx/onevpl`, `--enable-vaapi`).

- Local developer setup (Windows/Linux via vcpkg):
  - Example commands (feature names may vary with vcpkg port revisions):
    - Windows: `vcpkg install ffmpeg[nvcodec,qsv,amf,openssl,zlib]:x64-windows-static-md`
    - Linux: `vcpkg install ffmpeg[vaapi,qsv,openssl,zlib]:x64-linux`
  - Ensure drivers/runtime are installed on target machines (CUDA for NVENC, libva + DRM for VAAPI, Intel runtime for QSV).

- Licensing note
  - Enabling certain encoders/codecs can imply GPL or nonfree licensing. Review your distribution model before shipping linked binaries.

## 5) Optional workflow tweaks (diagnostics)

Add after FFmpeg install step in `.github/workflows/build.yml` for each job:

```yaml
- name: FFmpeg hardware encoders
  run: |
    ffmpeg -hide_banner -version
    ffmpeg -hide_banner -encoders | grep -Ei "nvenc|qsv|amf|vaapi|videotoolbox" || true
    ffmpeg -hide_banner -hwaccels || true
```

For Windows (PowerShell):

```yaml
- name: FFmpeg hardware encoders
  run: |
    ffmpeg -hide_banner -version
    ffmpeg -hide_banner -encoders | findstr /R /I "nvenc qsv amf vaapi videotoolbox"
    ffmpeg -hide_banner -hwaccels
  shell: pwsh
```

## 6) Key takeaways

- CI uses three different FFmpeg sources today; Windows/macOS likely include HW encoders, Linux is uncertain.
- Local vcpkg installs do not enable HW encoders by default; use features.
- Add simple CI diagnostics to lock in certainty and catch regressions.

