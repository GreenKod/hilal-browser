#!/usr/bin/env bash
# Build an AppImage from the current packaged Hilal/Firefox Linux build.

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

require_firefox_src

usage() {
  cat <<'EOF'
Usage:
  scripts/build-appimage.sh                # create AppImage from the active packaged build
  scripts/build-appimage.sh package        # run ./mach package first, then create AppImage
  scripts/build-appimage.sh --arm64-name linux-arm64
  scripts/build-appimage.sh --output FILE  # write AppImage to a specific path
  scripts/build-appimage.sh --help

Environment:
  APPIMAGETOOL=/path/to/appimagetool   Override the appimagetool binary to use.
  HILAL_APPIMAGE_OUT_DIR=/path         Default output directory (default: ./dist)

Notes:
  This script expects a packaged Linux build in firefox/<objdir>/dist/firefox.
  Create that first with ./mach package or scripts/build-linux*.sh package.
EOF
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

resolve_objdir() {
  (
    cd "$HILAL_FIREFOX_SRC"
    ./mach environment --format json | python3 -c 'import json, sys; print(json.load(sys.stdin)["topobjdir"])'
  )
}

detect_arch() {
  local platform_ini="$1/platform.ini"
  if [ -f "$platform_ini" ]; then
    case "$(awk -F= '/^BuildTarget=/{print $2; exit}' "$platform_ini")" in
      aarch64-*-linux-gnu) printf '%s\n' "aarch64"; return ;;
      x86_64-*-linux-gnu) printf '%s\n' "x86_64"; return ;;
    esac
  fi

  local bin="$1/firefox-bin"
  if command -v file >/dev/null 2>&1 && [ -f "$bin" ]; then
    case "$(file -b "$bin")" in
      *aarch64*|*ARM\ aarch64*) printf '%s\n' "aarch64"; return ;;
      *x86-64*|*x86_64*) printf '%s\n' "x86_64"; return ;;
    esac
  fi

  printf '%s\n' "unknown"
}

release_version() {
  if repo_release_tag >/dev/null 2>&1; then
    repo_release_tag
    return 0
  fi

  awk -F= '/^Version=/{print $2; exit}' "$1/application.ini"
}

copy_tree() {
  local src="$1"
  local dest="$2"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$src/" "$dest/"
  else
    mkdir -p "$dest"
    cp -a "$src"/. "$dest"/
  fi
}

map_arch_name() {
  local arch="$1"
  case "$arch" in
    aarch64) printf '%s\n' "${arm64_name:-$arch}" ;;
    x86_64) printf '%s\n' "${x64_name:-$arch}" ;;
    *) printf '%s\n' "$arch" ;;
  esac
}

package_first=0
output_path=""
arm64_name=""
x64_name=""

while [ $# -gt 0 ]; do
  case "$1" in
    package)
      package_first=1
      shift
      ;;
    --arm64-name)
      [ $# -ge 2 ] || die "--arm64-name requires a value"
      arm64_name="$2"
      shift 2
      ;;
    --x64-name)
      [ $# -ge 2 ] || die "--x64-name requires a value"
      x64_name="$2"
      shift 2
      ;;
    --output)
      [ $# -ge 2 ] || die "--output requires a path"
      output_path="$2"
      shift 2
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

need python3

APPIMAGETOOL_BIN="${APPIMAGETOOL:-$(command -v appimagetool || true)}"
[ -n "$APPIMAGETOOL_BIN" ] || die "appimagetool not found. Install it or set APPIMAGETOOL=/path/to/appimagetool"

obj_dir="$(resolve_objdir)"
dist_dir="$obj_dir/dist"
package_root="$dist_dir/firefox"

if [ "$package_first" -eq 1 ]; then
  log "Packaging Hilal Browser..."
  (cd "$HILAL_FIREFOX_SRC" && ./mach package)
fi

[ -d "$package_root" ] || die "Packaged app not found at $package_root. Run ./mach package or scripts/build-linux*.sh package first."

arch="$(detect_arch "$package_root")"
arch_name="$(map_arch_name "$arch")"
version="$(release_version "$package_root")"
[ -n "$version" ] || die "Could not resolve a release version from repo tags or $package_root/application.ini"

out_dir="${HILAL_APPIMAGE_OUT_DIR:-$HILAL_REPO_ROOT/dist}"
mkdir -p "$out_dir"

if [ -z "$output_path" ]; then
  output_path="$out_dir/hilal-browser-$version-$arch_name.AppImage"
fi

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/hilal-appimage.XXXXXX")"
appdir="$tmp_root/Hilal.AppDir"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

mkdir -p "$appdir/usr/bin" "$appdir/usr/lib" "$appdir/usr/share/applications" "$appdir/usr/share/icons/hicolor/128x128/apps"

log "Preparing AppDir..."
copy_tree "$package_root" "$appdir/usr/lib/hilal"

cat > "$appdir/usr/bin/hilal" <<'EOF'
#!/usr/bin/env sh
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec "$HERE/../lib/hilal/firefox" "$@"
EOF
chmod +x "$appdir/usr/bin/hilal"

cat > "$appdir/AppRun" <<'EOF'
#!/usr/bin/env sh
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec "$HERE/usr/bin/hilal" "$@"
EOF
chmod +x "$appdir/AppRun"

cat > "$appdir/usr/share/applications/org.hilal.browser.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Hilal Browser
GenericName=Web Browser
Comment=Browse the web with Hilal Browser
Exec=hilal %u
Icon=org.hilal.browser
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
StartupWMClass=hilal
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
EOF

cp "$appdir/usr/lib/hilal/browser/chrome/icons/default/default128.png" \
  "$appdir/usr/share/icons/hicolor/128x128/apps/org.hilal.browser.png"
ln -s usr/share/applications/org.hilal.browser.desktop "$appdir/org.hilal.browser.desktop"
ln -s usr/share/icons/hicolor/128x128/apps/org.hilal.browser.png "$appdir/org.hilal.browser.png"

log "Building AppImage..."
ARCH="$arch" "$APPIMAGETOOL_BIN" "$appdir" "$output_path"

log "AppImage created:"
log "  $output_path"
