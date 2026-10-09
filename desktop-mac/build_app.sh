#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESKTOP="$ROOT/desktop-mac"
APP="$DESKTOP/build/Free My Mac Desktop.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

mkdir -p "$MACOS" "$RESOURCES"

swiftc \
  -framework SwiftUI \
  -framework AppKit \
  -framework WebKit \
  "$DESKTOP"/Sources/*.swift \
  "$DESKTOP"/Sources/Models/*.swift \
  "$DESKTOP"/Sources/Services/*.swift \
  "$DESKTOP"/Sources/Views/*.swift \
  -o "$MACOS/FreeMyMacDesktop"

cp "$DESKTOP/Info.plist" "$CONTENTS/Info.plist"
printf 'APPL????' > "$CONTENTS/PkgInfo"

if [[ -f "$DESKTOP/Resources/AppIcon.icns" ]]; then
  cp "$DESKTOP/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi

chmod +x "$MACOS/FreeMyMacDesktop"
touch "$APP"

echo "$APP"
