#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUNDLE_DIR="$ROOT_DIR/build/linux/x64/release/bundle"
OUT_DIR="$ROOT_DIR/packaging/linux/output"
DEB_DIR="$ROOT_DIR/packaging/linux/debian"
PKG_NAME="brightness"
PKG_VERSION="1.0.0"
ARCH="amd64"

mkdir -p "$OUT_DIR"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# create filesystem layout
mkdir -p "$TMP_DIR/opt/$PKG_NAME"
cp -r "$BUNDLE_DIR/"* "$TMP_DIR/opt/$PKG_NAME/"

# helper: create a symlink in /usr/bin
mkdir -p "$TMP_DIR/usr/bin"
cat > "$TMP_DIR/usr/bin/$PKG_NAME" <<'EOF'
#!/bin/bash
exec /opt/brightness/brightness "$@"
EOF
chmod +x "$TMP_DIR/usr/bin/$PKG_NAME"

# desktop entry
mkdir -p "$TMP_DIR/usr/share/applications"
# If an icon is provided at packaging/linux/icon.png, install it into the
# hicolor icon theme so the desktop entry can reference it by name.
ICON_SRC="$ROOT_DIR/packaging/linux/icon.png"
if [ -f "$ICON_SRC" ]; then
  # install icons in a couple of sizes (256 and 48)
  mkdir -p "$TMP_DIR/usr/share/icons/hicolor/256x256/apps"
  mkdir -p "$TMP_DIR/usr/share/icons/hicolor/48x48/apps"
  cp "$ICON_SRC" "$TMP_DIR/usr/share/icons/hicolor/256x256/apps/$PKG_NAME.png"
  cp "$ICON_SRC" "$TMP_DIR/usr/share/icons/hicolor/48x48/apps/$PKG_NAME.png"
fi

mkdir -p "$TMP_DIR/usr/share/applications"
cat > "$TMP_DIR/usr/share/applications/$PKG_NAME.desktop" <<EOF
[Desktop Entry]
Name=brightness
Exec=/opt/brightness/brightness
Icon=$PKG_NAME
Type=Application
Categories=Utility;
EOF

# Copy control and maintainer scripts
mkdir -p "$TMP_DIR/DEBIAN"
cp "$DEB_DIR/control" "$TMP_DIR/DEBIAN/control"
if [ -f "$DEB_DIR/postinst" ]; then
  cp "$DEB_DIR/postinst" "$TMP_DIR/DEBIAN/postinst"
  # Ensure correct executable permissions for maintainer scripts
  chmod 0755 "$TMP_DIR/DEBIAN/postinst"
fi
if [ -f "$DEB_DIR/prerm" ]; then
  cp "$DEB_DIR/prerm" "$TMP_DIR/DEBIAN/prerm"
  chmod 0755 "$TMP_DIR/DEBIAN/prerm"
fi

# fix ownership and permissions
find "$TMP_DIR" -type d -exec chmod 755 {} +
find "$TMP_DIR" -type f -exec chmod 644 {} +
chmod 755 "$TMP_DIR/opt/$PKG_NAME/brightness"

# build the deb
OUTPUT_FILE="$OUT_DIR/${PKG_NAME}_${PKG_VERSION}_${ARCH}.deb"

# Ensure maintainer scripts are executable (dpkg-deb requires modes between 0555 and 0775)
if [ -d "$TMP_DIR/DEBIAN" ]; then
  chmod 0755 "$TMP_DIR/DEBIAN/postinst" 2>/dev/null || true
  chmod 0755 "$TMP_DIR/DEBIAN/prerm" 2>/dev/null || true
fi

# Prefer direct dpkg-deb build; fakeroot can sometimes cause unexpected permission
# checks in certain environments. If dpkg-deb fails, show instructions for manual build.
if command -v dpkg-deb >/dev/null 2>&1; then
  dpkg-deb --build "$TMP_DIR" "$OUTPUT_FILE"
  RC=$?
  if [ $RC -ne 0 ]; then
    echo "dpkg-deb failed with exit code $RC. You can try building manually:" >&2
    echo "  TMP_DIR=\$(mktemp -d)" >&2
    echo "  cp -r build/linux/x64/release/bundle/* \"\$TMP_DIR/opt/$PKG_NAME/\"" >&2
    echo "  mkdir -p \"\$TMP_DIR/DEBIAN\" && cp packaging/linux/debian/* \"\$TMP_DIR/DEBIAN/\" && chmod 0755 \"\$TMP_DIR/DEBIAN/postinst\" \"\$TMP_DIR/DEBIAN/prerm\"" >&2
    echo "  dpkg-deb --build \"\$TMP_DIR\" packaging/linux/output/${PKG_NAME}_${PKG_VERSION}_${ARCH}.deb" >&2
    exit $RC
  fi
else
  echo "dpkg-deb not found. Install dpkg (Debian/Ubuntu) or build the package manually." >&2
  exit 1
fi

echo "Created $OUTPUT_FILE"
