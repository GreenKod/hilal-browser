#!/usr/bin/env bash
# scripts/check-new-firefox.sh
#
# Periodically (hourly) checks the upstream Firefox repository for a newer
# stable release tag (FIREFOX_*_RELEASE). If a newer tag is found, the script
# updates the pinned version file (FIREFOX_COMMIT) and checks out the new
# commit in the local Firefox source tree.

set -euo pipefail

# Load shared helpers
. "$(dirname "$0")/lib.sh"

# Path to the file that stores the expected commit/tag
FIREFOX_COMMIT_FILE="${HILAL_ROOT:-$(dirname "$0")/../FIREFOX_COMMIT}"

# Resolve the current expected tag (or default to main if missing)
if [ -f "$FIREFOX_COMMIT_FILE" ]; then
  EXPECTED_TAG=$(cat "$FIREFOX_COMMIT_FILE" | tr -d " \n")
else
  EXPECTED_TAG="main"
fi

# Determine the latest stable tag from upstream
log "Fetching tags from upstream to detect latest stable Firefox version..."
# Ensure we have the latest tags in the local clone
if [ -d "$HILAL_FIREFOX_SRC/.git" ]; then
  git -C "$HILAL_FIREFOX_SRC" fetch --tags
else
  die "Firefox source tree not found at $HILAL_FIREFOX_SRC"
fi

LATEST_TAG=$(git -C "$HILAL_FIREFOX_SRC" tag -l 'FIREFOX_*_RELEASE' | sort -V | tail -n1)
if [ -z "$LATEST_TAG" ]; then
  die "Could not locate any stable Firefox tags in the upstream repository"
fi

log "Current pinned version: $EXPECTED_TAG"
log "Latest stable upstream tag: $LATEST_TAG"

if [ "$LATEST_TAG" != "$EXPECTED_TAG" ]; then
  log "New stable version detected – updating to $LATEST_TAG"
  echo "$LATEST_TAG" > "$FIREFOX_COMMIT_FILE"
  # Checkout the new tag in the local source tree
  git -C "$HILAL_FIREFOX_SRC" checkout "$LATEST_TAG"
  log "Firefox source updated to $LATEST_TAG"
else
  log "No new stable version – nothing to do"
fi
