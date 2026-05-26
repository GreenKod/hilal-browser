#!/usr/bin/env bash
# scripts/apply.sh
#
# Apply all Hilal changes to a Firefox source tree:
#   1. Copy the branding/ assets into browser/branding/<name>/
#   2. Apply every patch listed in patches/series, in order, via `git apply`
#   3. Copy any extra preference files (prefs/) into the tree
#
# Idempotent-ish: if everything is already applied, `git apply --check`
# will fail and we'll skip the patch. Use --force to reapply unconditionally
# (this will reset tracked files to upstream first).
#
# Usage:
#   scripts/apply.sh
#   scripts/apply.sh --force      # reset Firefox tree to a clean state first
#   scripts/apply.sh --no-symlinks # copy instead of symlink (Windows CI)
#   HILAL_FIREFOX_SRC=/path/to/ff scripts/apply.sh

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

FORCE=0
NO_SYMLINKS=0
DISCARD_LOCAL=0
STASHED=0
for arg in "$@"; do
  case "$arg" in
    --force|-f) FORCE=1 ;;
    --no-symlinks) NO_SYMLINKS=1 ;;
    --discard-local) DISCARD_LOCAL=1 ;;
    -h|--help)
      sed -n '2,17p' "$0"
      exit 0
      ;;
    *) die "Unknown argument: $arg" ;;
  esac
done

require_firefox_src
# Determine expected Firefox commit from FIREFOX_COMMIT file
FIREFOX_COMMIT_FILE="${HILAL_ROOT:-$(dirname "$0")/../FIREFOX_COMMIT}"
if [ -f "$FIREFOX_COMMIT_FILE" ]; then
  EXPECTED_COMMIT=$(cat "$FIREFOX_COMMIT_FILE" | tr -d " \n")
else
  EXPECTED_COMMIT="main"
fi
CURRENT_COMMIT=$(git -C "$HILAL_FIREFOX_SRC" rev-parse HEAD 2>/dev/null || echo "")
if [ -n "$CURRENT_COMMIT" ] && [ "$CURRENT_COMMIT" != "$EXPECTED_COMMIT" ]; then
  log "Current Firefox source is at $CURRENT_COMMIT but expected $EXPECTED_COMMIT."
  if [ "$DISCARD_LOCAL" = "1" ]; then
    log "[hilal] Discarding local changes and updating to $EXPECTED_COMMIT..."
    git -C "$HILAL_FIREFOX_SRC" fetch --tags
    git -C "$HILAL_FIREFOX_SRC" reset --hard "$EXPECTED_COMMIT"
  else
    while true; do
      printf "[hilal] Update to expected version? (y/n): "
      read -r answer
      case "$answer" in
        y|Y) log "Updating Firefox source to $EXPECTED_COMMIT..."; git -C "$HILAL_FIREFOX_SRC" fetch --tags; git -C "$HILAL_FIREFOX_SRC" checkout "$EXPECTED_COMMIT"; break ;;
        n|N) log "Aborting apply due to version mismatch."; exit 1 ;;
        *) echo "Please answer y or n." ;;
      esac
    done
  fi
fi

get_patched_files() {
  local series_file="$HILAL_REPO_ROOT/patches/series"
  [ -f "$series_file" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -z "$line" ] && continue
    [ "${line:0:1}" = "#" ] && continue
    local patch_path="$HILAL_REPO_ROOT/patches/$line"
    if [ -f "$patch_path" ]; then
      grep -E "^diff --git a/" "$patch_path" | sed -E 's/^diff --git a\/(.+) b\/.+$/\1/' || true
    fi
  done < "$series_file" | sort -u
}

if [ "$FORCE" = 1 ]; then
  warn "--force: performing safe selective reset of patched files in $HILAL_FIREFOX_SRC to HEAD"
  warn "         and removing branding/hilal + prefs overlays."

  # Auto-stash developer modifications if present
  if ! git -C "$HILAL_FIREFOX_SRC" diff --quiet || ! git -C "$HILAL_FIREFOX_SRC" diff --cached --quiet || [ -n "$(git -C "$HILAL_FIREFOX_SRC" status --porcelain)" ]; then
    log "Stashing local changes in Firefox tree..."
    git -C "$HILAL_FIREFOX_SRC" stash push -u -m "hilal-apply-backup"
    STASHED=1
  fi

  # Reset and clean only the files touched by patches
  patched_files=$(get_patched_files)
  if [ -n "$patched_files" ]; then
    log "Resetting and cleaning patched files..."
    echo "$patched_files" | while read -r f; do
      [ -z "$f" ] && continue
      git -C "$HILAL_FIREFOX_SRC" checkout HEAD -- "$f" >/dev/null 2>&1 || true
      git -C "$HILAL_FIREFOX_SRC" clean -f -- "$f" >/dev/null 2>&1 || true
    done
  fi

  rm -rf "$HILAL_FIREFOX_SRC/browser/branding/hilal"
  rm -f "$HILAL_FIREFOX_SRC/.hilal-applied"
  # Remove untracked files created by Hilal patches (new files not tracked by Firefox git).
  git -C "$HILAL_FIREFOX_SRC" clean -fd \
    browser/components/preferences/hilal.inc.xhtml \
    browser/base/content/hilal/ \
    browser/themes/shared/hilal-ui-fix.css \
    browser/app/distribution/policies.json \
    browser/app/distribution/extensions/ \
    browser/modules/HilalBangs.sys.mjs \
    > /dev/null 2>&1 || true
fi

calculate_series_hash() {
  local series_file="$HILAL_REPO_ROOT/patches/series"
  [ -f "$series_file" ] || return 1

  stream_contents() {
    cat "$series_file"
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line#"${line%%[![:space:]]*}"}"
      line="${line%"${line##*[![:space:]]}"}"
      [ -z "$line" ] && continue
      [ "${line:0:1}" = "#" ] && continue
      if [ -f "$HILAL_REPO_ROOT/patches/$line" ]; then
        cat "$HILAL_REPO_ROOT/patches/$line"
      fi
    done < "$series_file"
  }

  if command -v sha256sum >/dev/null 2>&1; then
    stream_contents | sha256sum | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    stream_contents | shasum -a 256 | cut -d' ' -f1
  else
    stream_contents | python3 -c "import sys, hashlib; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest())"
  fi
}

if [ -d "$HILAL_FIREFOX_SRC/browser/branding/huma" ]; then
  warn "Removing stale pre-Hilal branding overlay: browser/branding/huma"
  rm -rf "$HILAL_FIREFOX_SRC/browser/branding/huma"
fi

# -- 1. Copy branding/* into browser/branding/* ------------------------------

if [ -d "$HILAL_REPO_ROOT/branding" ]; then
  for src in "$HILAL_REPO_ROOT/branding"/*/; do
    [ -d "$src" ] || continue
    name="$(basename "$src")"
    dst="$HILAL_FIREFOX_SRC/browser/branding/$name"
    log "Syncing branding: $name -> browser/branding/$name"
    mkdir -p "$dst"
    # Prefer rsync (macOS/Linux) for --delete semantics.
    # Fall back to rm + cp for environments without rsync (e.g. Git Bash on Windows).
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --delete "$src" "$dst/"
    else
      rm -rf "$dst"
      cp -r "$src" "$dst"
    fi
  done
fi

patch_already_present() {
  local patch_path="$1"
  local root="$2"
  local overlay_root="$HILAL_REPO_ROOT/prefs"
  python3 - "$patch_path" "$root" "$overlay_root" <<'PY'
import os, re, sys
patch_path = sys.argv[1]
root = sys.argv[2]
overlay_root = sys.argv[3]
added = {}
current = None
with open(patch_path, 'r', encoding='utf-8') as f:
    for line in f:
        if line.startswith('diff --git '):
            m = re.search(r'^diff --git a/(.+?) b/(.+)$', line)
            current = m.group(1) if m else None
            if current:
                added[current] = []
        elif current is None:
            continue
        elif line.startswith(('--- ', '+++ ', 'index ', 'new file mode ', 'deleted file mode ', 'similarity index ', 'rename from ', 'rename to ', 'copy from ', 'copy to ', '@@ ')):
            continue
        elif line.startswith('+') and not line.startswith('+++'):
            content = line[1:].rstrip('\n')
            if content.strip():
                added[current].append(content)
if not any(added.values()):
    sys.exit(1)
for file_path, lines in added.items():
    # Overlay-managed files under prefs/ may legitimately diverge from the
    # original patch content after later patches/localization updates.
    if os.path.exists(os.path.join(overlay_root, file_path)):
        continue
    full = os.path.join(root, file_path)
    if not os.path.exists(full):
        sys.exit(1)
    with open(full, 'r', encoding='utf-8', errors='ignore') as f:
        text = f.read()
    for line in lines:
        if line not in text:
            sys.exit(1)
sys.exit(0)
PY
}

# -- 2. Apply patches in series order ----------------------------------------

read_series
if [ "${#SERIES[@]}" -eq 0 ]; then
  warn "patches/series is empty; no patches to apply."
else
  # OS filtering: Remove OS-specific patches that don't match current platform
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  FILTERED_SERIES=()
  for p in "${SERIES[@]}"; do
    if [[ "$p" == *.macos.patch && "$OS" != "darwin" ]]; then continue; fi
    if [[ "$p" == *.linux.patch && "$OS" != "linux" ]]; then continue; fi
    if [[ "$p" == *.windows.patch && "$OS" != "mingw"* && "$OS" != "cygwin" ]]; then continue; fi
    FILTERED_SERIES+=("$p")
  done
  SERIES=("${FILTERED_SERIES[@]}")

  CURRENT_HASH=$(calculate_series_hash)
  STATE_FILE="$HILAL_FIREFOX_SRC/.hilal-applied"
  SKIP_PATCHES=0

  if [ "$FORCE" = 0 ] && [ -f "$STATE_FILE" ]; then
    STORED_HASH=$(head -n 1 "$STATE_FILE" 2>/dev/null || true)
    STORED_SHA=$(sed -n '2p' "$STATE_FILE" 2>/dev/null || true)
    if [ "$CURRENT_HASH" = "$STORED_HASH" ]; then
      log "Patches are already up-to-date (matching checksum: $CURRENT_HASH). Skipping patch application."
      SKIP_PATCHES=1
    else
      # If checksum has changed, check if we can perform a smart rollback of old patches
      if [ -n "$STORED_SHA" ] && git -C "$HILAL_REPO_ROOT" cat-file -e "$STORED_SHA^{commit}" >/dev/null 2>&1; then
        log "Detected patch changes. Attempting smart rollback of previously applied patches..."
        OLD_SERIES=()
        if git -C "$HILAL_REPO_ROOT" show "$STORED_SHA:patches/series" >/dev/null 2>&1; then
          while IFS= read -r line || [ -n "$line" ]; do
            line="${line#"${line%%[![:space:]]*}"}"
            line="${line%"${line##*[![:space:]]}"}"
            [ -z "$line" ] && continue
            [ "${line:0:1}" = "#" ] && continue
            OLD_SERIES+=("$line")
          done < <(git -C "$HILAL_REPO_ROOT" show "$STORED_SHA:patches/series")
        fi

        if [ "${#OLD_SERIES[@]}" -gt 0 ]; then
          tmp_patch=$(mktemp)
          for (( i=${#OLD_SERIES[@]}-1; i>=0; i-- )); do
            p="${OLD_SERIES[i]}"
            if git -C "$HILAL_REPO_ROOT" show "$STORED_SHA:patches/$p" > "$tmp_patch" 2>/dev/null; then
              if git -C "$HILAL_FIREFOX_SRC" apply --check --reverse "$tmp_patch" >/dev/null 2>&1; then
                log "  Reversing: $p"
                git -C "$HILAL_FIREFOX_SRC" apply --reverse --whitespace=nowarn "$tmp_patch" >/dev/null 2>&1 || true
              fi
            fi
          done
          rm -f "$tmp_patch"
        fi
      fi
    fi
  fi

  if [ "$SKIP_PATCHES" = 0 ]; then
    applied=0
    skipped=0
    for p in "${SERIES[@]}"; do
      patch_path="$HILAL_REPO_ROOT/patches/$p"
      [ -f "$patch_path" ] || die "Patch listed in series not found: $p"
      if git -C "$HILAL_FIREFOX_SRC" apply --check --reverse "$patch_path" >/dev/null 2>&1; then
        log "Skip (already applied): $p"
        skipped=$((skipped + 1))
        continue
      fi
      if patch_already_present "$patch_path" "$HILAL_FIREFOX_SRC"; then
        log "Skip (already applied): $p"
        skipped=$((skipped + 1))
        continue
      fi
      log "Applying: $p"
      if ! git -C "$HILAL_FIREFOX_SRC" apply --whitespace=nowarn "$patch_path"; then
        die "Failed to apply $p. Try: scripts/apply.sh --force, or refresh patches against current upstream."
      fi
      applied=$((applied + 1))
    done
    log "Patches: $applied applied, $skipped already in tree."
    {
      echo "$CURRENT_HASH"
      git -C "$HILAL_REPO_ROOT" rev-parse HEAD 2>/dev/null || echo ""
    } > "$STATE_FILE"
  fi
fi

# -- 3. Copy any prefs/ overlays ---------------------------------------------

if [ -d "$HILAL_REPO_ROOT/prefs" ] && [ "$(find "$HILAL_REPO_ROOT/prefs" -type f ! -name '.DS_Store' ! -name '.gitkeep' -print -quit 2>/dev/null)" ]; then
  log "Syncing prefs/ overlays into Firefox tree"
  # Convention: a file at prefs/<relative/path/in/firefox> is copied to that
  # path in the Firefox source. Subdirectories under prefs/ mirror the tree.
  (
    cd "$HILAL_REPO_ROOT/prefs"
    find . -type f ! -name '.DS_Store' ! -name '.gitkeep' -print0 | while IFS= read -r -d '' rel; do
      rel="${rel#./}"
      dst="$HILAL_FIREFOX_SRC/$rel"
      mkdir -p "$(dirname "$dst")"
      if [ "$NO_SYMLINKS" = 1 ]; then
        cp -f "$(pwd)/$rel" "$dst"
        log "  prefs -> $rel (copy)"
      else
        src_abs="$(pwd)/$rel"
        dst_dir="$(dirname "$dst")"
        rel_link="$(python3 -c 'import os.path; import sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$src_abs" "$dst_dir")"
        ln -sf "$rel_link" "$dst"
        log "  prefs -> $rel (symlink)"
      fi
    done
  )
fi

# -- 4. Download and copy default extensions ---------------------------------

UBO_VERSION="1.57.2"
UBO_URL="https://github.com/gorhill/uBlock/releases/download/${UBO_VERSION}/uBlock0_${UBO_VERSION}.firefox.signed.xpi"
UBO_SHA256="9928e79a52cecf7cfa231fdb0699c7d7a427660d94eb10d711ed5a2f10d2eb89"

EXT_DIR="$HILAL_FIREFOX_SRC/browser/app/distribution/extensions"
mkdir -p "$EXT_DIR"
UBO_PATH="$EXT_DIR/uBlock0@raymondhill.net.xpi"

get_sha256() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | cut -d' ' -f1
  else
    python3 -c "import hashlib; print(hashlib.sha256(open('$file','rb').read()).hexdigest())"
  fi
}

verify_ubo_checksum() {
  if [ -f "$UBO_PATH" ]; then
    local current_hash
    current_hash=$(get_sha256 "$UBO_PATH")
    if [ "$current_hash" = "$UBO_SHA256" ]; then
      return 0
    fi
  fi
  return 1
}

if ! verify_ubo_checksum; then
  log "Downloading uBlock Origin v${UBO_VERSION} extension..."
  if ! curl -L -f -s -o "$UBO_PATH" "$UBO_URL"; then
    die "Failed to download uBlock Origin from ${UBO_URL}."
  fi
  if ! verify_ubo_checksum; then
    rm -f "$UBO_PATH"
    die "CRITICAL: uBlock Origin checksum verification failed! Downloaded file is corrupt or compromised."
  fi
  log "uBlock Origin v${UBO_VERSION} successfully downloaded and verified."
else
  log "uBlock Origin v${UBO_VERSION} is already present and verified."
fi

if [ "${STASHED:-0}" = 1 ]; then
  log "Restoring your local changes from stash..."
  git -C "$HILAL_FIREFOX_SRC" stash pop || warn "Stash pop had conflicts. Please resolve them in the Firefox directory."
fi

log "All Hilal changes applied. Build with: scripts/build-macos.sh"
