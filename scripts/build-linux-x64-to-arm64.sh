#!/usr/bin/env bash
# scripts/build-linux-x64-to-arm64.sh
#
# Cross-compile Hilal Browser for Linux ARM64 (aarch64) from an x86_64 Linux host.
#
# Usage:
#   scripts/build-linux-x64-to-arm64.sh                 # full cross-build
#   scripts/build-linux-x64-to-arm64.sh faster          # front-end only
#   scripts/build-linux-x64-to-arm64.sh binaries        # C++/Rust only
#   scripts/build-linux-x64-to-arm64.sh package         # build and package
#   scripts/build-linux-x64-to-arm64.sh -- <args>       # pass arguments to mach build
#
# Notes:
# - This script is intended for x86_64 Linux hosts targeting Linux ARM64.
# - `run` is intentionally unsupported here; the produced ARM64 binary will not
#   run natively on the current x86_64 host without emulation.

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

require_firefox_src

need() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

check_host() {
  if [ "$(uname -s)" != "Linux" ]; then
    die "This script is only supported on Linux hosts."
  fi

  if [ "$(uname -m)" != "x86_64" ]; then
    die "This script expects an x86_64 host. Current host: $(uname -m)"
  fi
}

check_cross_prereqs() {
  need rustup
  need clang

  if ! rustup target list --installed | grep -qx 'aarch64-unknown-linux-gnu'; then
    die "Rust target aarch64-unknown-linux-gnu is missing. Run: rustup target add aarch64-unknown-linux-gnu"
  fi
}

has_arm64_build_outputs() {
  find "$HILAL_FIREFOX_SRC" -maxdepth 3 -path '*/obj-aarch64*/dist/bin/libxul.so' -print -quit | grep -q .
}

check_host
check_cross_prereqs

# Ensure patches/branding are applied
bash "$(dirname "$0")/apply.sh"

MOZCONFIG_SRC="$(dirname "$0")/../mozconfigs/linux-arm64"
if [ -f "$MOZCONFIG_SRC" ]; then
  log "Copying mozconfigs/linux-arm64 -> firefox/mozconfig"
  cp "$MOZCONFIG_SRC" "$HILAL_FIREFOX_SRC/mozconfig"
else
  die "Could not find ARM64 Linux configuration file: $MOZCONFIG_SRC"
fi

NO_LAG=0

if [ $# -gt 0 ] && [ "$1" = "--no-lag" ]; then
  NO_LAG=1
  shift
fi

if [ "$NO_LAG" -eq 1 ]; then
  CORES=$(nproc)
  if [ "$CORES" -ge 8 ]; then
    MAX_JOBS=6
  else
    if [ "$CORES" -gt 1 ]; then
      MAX_JOBS=$((CORES - 1))
    else
      MAX_JOBS=1
    fi
  fi
  cmd=("./mach" "build" "-j" "$MAX_JOBS")
else
  cmd=("./mach" "build")
fi

package_after=0
requested_mode=""

if [ $# -gt 0 ]; then
  case "$1" in
    faster)
      requested_mode="faster"
      cmd=("./mach" "build" "faster")
      ;;
    binaries)
      requested_mode="binaries"
      cmd=("./mach" "build" "binaries")
      ;;
    run)
      die "`run` is not supported for x64 -> ARM64 cross-builds on this host. Build/package first, then test on an ARM64 machine or emulator."
      ;;
    package)
      package_after=1
      ;;
    --)
      shift
      cmd=("./mach" "build" "$@")
      ;;
    *)
      if [ "$NO_LAG" -eq 1 ]; then
        cmd=("./mach" "build" "-j" "$MAX_JOBS" "$@")
      else
        cmd=("./mach" "build" "$@")
      fi
      ;;
  esac
fi

if [ "$requested_mode" = "faster" ] && ! has_arm64_build_outputs; then
  warn "No existing ARM64 build outputs were found. Falling back from 'faster' to a full build for the first cross-build."
  if [ "$NO_LAG" -eq 1 ]; then
    cmd=("./mach" "build" "-j" "$MAX_JOBS")
  else
    cmd=("./mach" "build")
  fi
fi

log "Cross-building Linux ARM64 in $HILAL_FIREFOX_SRC: ${cmd[*]}"
log "(first cross-build can take a while while toolchains/sysroots are prepared)"
(cd "$HILAL_FIREFOX_SRC" && "${cmd[@]}")

if [ "$package_after" = 1 ]; then
  log "Packaging Hilal Browser for Linux ARM64..."
  (cd "$HILAL_FIREFOX_SRC" && ./mach package)
  log "Package created. Look in:"
  log "  $HILAL_FIREFOX_SRC/obj-aarch64*-linux-gnu*/dist/"
fi

log "Done."
