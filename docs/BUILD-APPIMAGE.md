# Build Hilal as an AppImage

Use the packaged Linux build under `firefox/<objdir>/dist/firefox` to create a
portable AppImage artifact.

## Prerequisites

Install `appimagetool` and make sure it is on your `PATH`, or point the helper
script at it:

```bash
APPIMAGETOOL=/path/to/appimagetool scripts/build-appimage.sh
```

The browser itself must already be packaged first:

```bash
scripts/build-linux.sh package
# or
scripts/build-linux-x64-to-arm64.sh package
```

## Create the AppImage

If the packaged build already exists:

```bash
scripts/build-appimage.sh
```

To package first and then build the AppImage in one step:

```bash
scripts/build-appimage.sh package
```

The default output path is:

```text
dist/hilal-browser-<version>-<arch>.AppImage
```

For release-friendly Linux naming, especially on ARM64:

```bash
scripts/build-appimage.sh --arm64-name linux-arm64
```

That produces names like:

```text
dist/hilal-browser-152.0a1-linux-arm64.AppImage
```

Override it if you want a specific filename:

```bash
scripts/build-appimage.sh --output dist/hilal-browser-linux-arm64.AppImage
```

## Notes

- The script reads the active Firefox object directory via `./mach environment`.
- It builds the AppImage from the packaged `dist/firefox` directory, not from
  loose `dist/bin` build outputs.
- The detected architecture is emitted as `x86_64` or `aarch64` by default, and
  can be remapped with `--arm64-name` or `--x64-name`.
