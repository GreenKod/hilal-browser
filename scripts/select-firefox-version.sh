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

FIREFOX_REMOTE_URL="https://github.com/mozilla-firefox/firefox.git"

# -------------------------------------------------------------------------
# Helper: fetch all stable tags from upstream Firefox repo without cloning
# -------------------------------------------------------------------------
fetch_tags() {
  git ls-remote --tags --refs "$FIREFOX_REMOTE_URL" 'refs/tags/FIREFOX_*_RELEASE' \
    | awk '{ sub("refs/tags/", "", $2); print $2 }' \
    | sort -uV
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
