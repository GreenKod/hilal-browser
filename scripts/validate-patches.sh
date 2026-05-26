#!/usr/bin/env bash
# scripts/validate-patches.sh
#
# Dry-run validate the current Hilal patches against a clean Firefox tree
# at the commit specified in FIREFOX_COMMIT, using a local shared clone.

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

require_firefox_src

FIREFOX_COMMIT_FILE="$HILAL_REPO_ROOT/FIREFOX_COMMIT"
[ -f "$FIREFOX_COMMIT_FILE" ] || die "Missing FIREFOX_COMMIT file in repo root."

TARGET_COMMIT=$(cat "$FIREFOX_COMMIT_FILE" | tr -d '[:space:]')
[ -n "$TARGET_COMMIT" ] || die "FIREFOX_COMMIT file is empty."

log "Validating patches against Firefox commit: $TARGET_COMMIT"

# Check if the commit exists in the firefox repo
if ! git -C "$HILAL_FIREFOX_SRC" cat-file -e "$TARGET_COMMIT" >/dev/null 2>&1; then
  log "Target commit not found in local Firefox tree. Fetching from origin..."
  git -C "$HILAL_FIREFOX_SRC" fetch origin "$TARGET_COMMIT" || die "Failed to fetch target commit $TARGET_COMMIT from origin."
fi

# Create a temporary directory inside the workspace for git sharing
TMP_DIR=$(mktemp -d "$HILAL_REPO_ROOT/validate-temp.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

log "Creating a local shared clone of Firefox in temporary directory..."
git clone --shared --no-checkout "$HILAL_FIREFOX_SRC" "$TMP_DIR" >/dev/null 2>&1

log "Checking out target commit $TARGET_COMMIT..."
git -C "$TMP_DIR" checkout -q "$TARGET_COMMIT"

read_series
if [ "${#SERIES[@]}" -eq 0 ]; then
  warn "patches/series is empty; no patches to validate."
  exit 0
fi

log "Verifying patch application sequence..."
failed=0
# Detect current OS (Darwin for macOS, Linux for Linux etc.)
CURRENT_OS=$(uname -s)
# Build filtered series respecting optional [os] prefix in series entries
FILTERED_SERIES=()
for entry in "${SERIES[@]}"; do
  # Pattern: [os] patchname or just patchname
  if [[ $entry =~ ^\[(.+)\][[:space:]]+(.*)$ ]]; then
    OS_PREFIX="${BASH_REMATCH[1]}"
    PATCH_NAME="${BASH_REMATCH[2]}"
    case "$OS_PREFIX" in
      mac)   [[ "$CURRENT_OS" == "Darwin" ]] && FILTERED_SERIES+=("$PATCH_NAME") || log "[SKIP] $PATCH_NAME (mac-only)" ;;
      linux) [[ "$CURRENT_OS" == "Linux" ]] && FILTERED_SERIES+=("$PATCH_NAME") || log "[SKIP] $PATCH_NAME (linux-only)" ;;
      *)     log "[SKIP] $entry (unknown OS prefix)" ;;
    esac
  else
    FILTERED_SERIES+=("$entry")
  fi
done

for p in "${FILTERED_SERIES[@]}"; do
  patch_path="${HILAL_REPO_ROOT}/patches/${p}"
  [ -f "$patch_path" ] || { warn "Patch file not found: $p"; failed=1; break; }
  if git -C "$TMP_DIR" apply --check --whitespace=nowarn "$patch_path" > /dev/null 2>&1; then
    log "  [OK] $p"
    git -C "$TMP_DIR" apply --whitespace=nowarn "$patch_path"
  else
    warn "  [FAIL] $p"
    failed=1
    git -C "$TMP_DIR" apply --check --whitespace=nowarn "$patch_path" || true
    break
  fi
done

if [ "$failed" = 0 ]; then
  log "SUCCESS: All patches applied cleanly against commit $TARGET_COMMIT!"
  exit 0
else
  die "VALIDATION FAILED: One or more patches could not be applied cleanly."
fi
