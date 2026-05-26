#!/usr/bin/env bash
# scripts/select-firefox-version.sh
#
# Interactive helper that:
#   1. Retrieves the list of stable Firefox tags (FIREFOX_*_RELEASE).
#   2. Shows them as a numbered menu.
#   3. Lets the user pick a tag and confirm the choice.
#   4. Writes the selected tag into the repository‑wide FIREFOX_COMMIT file.
#
# Usage:
#   $ ./scripts/select-firefox-version.sh
#   (will prompt you interactively)
#
# This script does **not** commit any change; it only updates the plain text file.
# The file is read by scripts/setup-firefox.sh and scripts/apply.sh.

set -euo pipefail

# -------------------------------------------------------------------------
# Helper: fetch all stable tags from upstream Firefox repo (shallow, tags only)
# -------------------------------------------------------------------------
fetch_tags() {
  local workdir
  workdir=$(mktemp -d)
  # shallow clone, no checkout – only .git metadata
  git clone --depth 1 --filter=blob:none --no-checkout \
    https://github.com/mozilla-firefox/firefox.git "$workdir" >/dev/null 2>&1
  git -C "$workdir" fetch --tags --quiet
  # list only tags that match the stable pattern and sort them naturally
  git -C "$workdir" tag -l 'FIREFOX_*_RELEASE' | sort -V
  rm -rf "$workdir"
}

# -------------------------------------------------------------------------
# Main flow
# -------------------------------------------------------------------------
FIREFOX_COMMIT_FILE="${HILAL_ROOT:-$(dirname "${BASH_SOURCE[0]}")/../FIREFOX_COMMIT}"

# 1) Get list of tags
mapfile -t tags < <(fetch_tags)

if [ ${#tags[@]} -eq 0 ]; then
  echo "[hilal] No stable Firefox tags found. Exiting." >&2
  exit 1
fi

# 2) Show menu
echo "Available stable Firefox tags:"
for i in "${!tags[@]}"; do
  printf "  %3d) %s\n" $((i+1)) "${tags[i]}"
done

# 3) Prompt for selection
while true; do
  read -rp "Select a tag by number (1-${#tags[@]}): " choice
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#tags[@]} )); then
    SELECTED_TAG="${tags[choice-1]}"
    break
  else
    echo "Invalid choice – please enter a number between 1 and ${#tags[@]}"
  fi
done

echo "You selected: $SELECTED_TAG"

# 4) Confirmation
while true; do
  read -rp "Write this tag to FIREFOX_COMMIT (y/n)? " yn
  case "$yn" in
    [Yy]*)
      echo "$SELECTED_TAG" > "$FIREFOX_COMMIT_FILE"
      echo "Wrote $SELECTED_TAG to $FIREFOX_COMMIT_FILE"
      exit 0
      ;;
    [Nn]*)
      echo "Aborted – no changes made."
      exit 1
      ;;
    *) echo "Please answer y or n.";;
  esac
done
