#!/usr/bin/env bash
# scripts/build-linux.sh
#
# Thin convenience wrapper around `./mach build` and `./mach package` for Hilal on Linux.
#
# Usage:
#   scripts/build-linux.sh                 # full build
#   scripts/build-linux.sh faster          # front-end only
#   scripts/build-linux.sh binaries        # C++/Rust only
#   scripts/build-linux.sh run             # build and run
#   scripts/build-linux.sh package         # build and package
#   scripts/build-linux.sh -- <args>       # pass arguments to mach build

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

require_firefox_src

if [ "$(uname -s)" != "Linux" ]; then
  warn "This script is tuned for Linux. On macOS, please use build-macos.sh."
fi

# Ensure patches/branding are applied
bash "$(dirname "$0")/apply.sh"

# Copy Linux mozconfig
if [ -f "$(dirname "$0")/../mozconfigs/linux" ]; then
  log "Copying mozconfigs/linux -> firefox/mozconfig"
  cp "$(dirname "$0")/../mozconfigs/linux" "$HILAL_FIREFOX_SRC/mozconfig"
fi

# If '--no-lag' is passed, limit parallel jobs (default 4).
# Otherwise, let mach decide the number of jobs.
if [ "$1" = "--no-lag" ]; then
  NO_LAG=1
  shift
else
  NO_LAG=0
fi

if [ "$NO_LAG" -eq 1 ]; then
  MAX_JOBS=${MAX_JOBS:-4}
  cmd=("./mach" "build" "-j" "$MAX_JOBS")
else
  cmd=("./mach" "build")
fi
run_after=0
package_after=0

if [ $# -gt 0 ]; then
  case "$1" in
    faster)   cmd=("./mach" "build" "faster") ;;
    binaries) cmd=("./mach" "build" "binaries") ;;
    run)
      run_after=1
      ;;
    package)
      package_after=1
      ;;
    --) shift; cmd=("./mach" "build" "$@") ;;
    *)
  if [ "$NO_LAG" -eq 1 ]; then
    cmd=("./mach" "build" "-j" "$MAX_JOBS" "$@")
  else
    cmd=("./mach" "build" "$@")
  fi
  ;;

  esac
fi

log "Building in $HILAL_FIREFOX_SRC: ${cmd[*]}"
log "(this can take 10-40 minutes on a first full build)"
(cd "$HILAL_FIREFOX_SRC" && "${cmd[@]}")

if [ "$run_after" = 1 ]; then
  log "Launching Hilal Browser..."
  (cd "$HILAL_FIREFOX_SRC" && ./mach run)
elif [ "$package_after" = 1 ]; then
  log "Packaging Hilal Browser..."
  (cd "$HILAL_FIREFOX_SRC" && ./mach package)
  log "Package created. Look in:"
  log "  $HILAL_FIREFOX_SRC/obj-x86_64-pc-linux-gnu/dist/"
fi

log "Done."
