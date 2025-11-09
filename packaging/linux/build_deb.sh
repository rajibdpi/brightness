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
cat > "$TMP_DIR/usr/share/applications/$PKG_NAME.desktop" <<EOF
[Desktop Entry]
Name=brightness
Exec=/opt/brightness/brightness
Icon=
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
fakeroot dpkg-deb --build "$TMP_DIR" "$OUTPUT_FILE"

echo "Created $OUTPUT_FILE"
