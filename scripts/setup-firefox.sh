#!/usr/bin/env bash
# scripts/setup-firefox.sh
#
# Clone (or fast-forward) the upstream Firefox source tree into the
# location the rest of the scripts expect. This script does NOT touch
# the hilal-browser repo itself; it only manages the Firefox checkout.
#
# Default checkout location: <hilal-browser>/firefox
# Override with HILAL_FIREFOX_SRC=/some/path before running.
#
# Usage:
#   scripts/setup-firefox.sh              # clone if missing, fetch if present
#   scripts/setup-firefox.sh --pull       # also fast-forward main

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

# Determine Firefox commit (stable tag). This will be a tag like FIREFOX_124_0_RELEASE.
if [ -f "$FIREFOX_COMMIT_FILE" ]; then
  FIREFOX_COMMIT=$(cat "$FIREFOX_COMMIT_FILE" | tr -d " \n")
else
  log "Detecting latest stable Firefox tag for initial checkout..."
  latest_tag=$(git -C "$HILAL_FIREFOX_SRC" tag -l 'FIREFOX_*_RELEASE' | sort -V | tail -n1)
  if [ -z "$latest_tag" ]; then
    die "Could not find a stable Firefox tag in the upstream repository"
  fi
  FIREFOX_COMMIT=$latest_tag
  echo "$FIREFOX_COMMIT" > "$FIREFOX_COMMIT_FILE"
fi
DO_PULL=0
for arg in "$@"; do
  case "$arg" in
    --pull) DO_PULL=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *) die "Unknown argument: $arg" ;;
  esac
done

if [ ! -d "$HILAL_FIREFOX_SRC/.git" ]; then
  log "Cloning Firefox from $UPSTREAM_URL"
  log "  destination: $HILAL_FIREFOX_SRC"
  log "  this may take a long time (~5+ GB)..."
  git clone "$UPSTREAM_URL" "$HILAL_FIREFOX_SRC"
else
  log "Firefox checkout already present at $HILAL_FIREFOX_SRC"
  log "Fetching upstream..."
  git -C "$HILAL_FIREFOX_SRC" fetch origin
  # Ensure we have all tags to detect the latest stable release
  git -C "$HILAL_FIREFOX_SRC" fetch --tags

  # If the commit identifier is missing or set to "latest", compute the newest stable tag
  if [ -z "$FIREFOX_COMMIT" ] || [ "$FIREFOX_COMMIT" = "latest" ]; then
    log "Detecting latest stable Firefox tag..."
    # Tags are like FIREFOX_124_0_RELEASE; sort them naturally and take the newest
    latest_tag=$(git -C "$HILAL_FIREFOX_SRC" tag -l 'FIREFOX_*_RELEASE' | sort -V | tail -n1)
    if [ -z "$latest_tag" ]; then
      die "Could not find a stable Firefox tag in the upstream repository"
    fi
    FIREFOX_COMMIT=$latest_tag
    # Persist the resolved tag for reproducible builds
    echo "$FIREFOX_COMMIT" > "$FIREFOX_COMMIT_FILE"
  fi

  log "Checking out Firefox commit/tag $FIREFOX_COMMIT"
  git -C "$HILAL_FIREFOX_SRC" checkout "$FIREFOX_COMMIT"

fi

if [ "$DO_PULL" = 1 ]; then
  branch="$(git -C "$HILAL_FIREFOX_SRC" rev-parse --abbrev-ref HEAD)"
  log "Fast-forwarding $branch from origin/$branch"
  git -C "$HILAL_FIREFOX_SRC" merge --ff-only "origin/$branch"
fi

log "Firefox source ready at $HILAL_FIREFOX_SRC"
log "Next step: scripts/apply.sh"
