#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${APP_NAME:-C2CBar}"
BUNDLE_ID="${BUNDLE_ID:-com.murongg.C2CBar}"
VERSION="${VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-$(git -C "$ROOT_DIR" rev-list --count HEAD 2>/dev/null || date +%Y%m%d%H%M)}"
CONFIGURATION="${CONFIGURATION:-release}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION-macos.zip"
SIGNING_MODE="${SIGNING_MODE:-adhoc}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARIZE="${NOTARIZE:-0}"
APPLE_KEYCHAIN_PROFILE="${APPLE_KEYCHAIN_PROFILE:-}"
ICON_SOURCE="${ICON_SOURCE:-$ROOT_DIR/Sources/C2CBarAssets/Resources/Tokens/usdc.png}"

log() {
  printf '==> %s\n' "$*"
}

plist_escape() {
  printf '%s' "$1" \
    | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'
}

create_info_plist() {
  local plist_path="$CONTENTS_DIR/Info.plist"
  cat > "$plist_path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>zh_CN</string>
  <key>CFBundleDisplayName</key>
  <string>$(plist_escape "$APP_NAME")</string>
  <key>CFBundleExecutable</key>
  <string>$(plist_escape "$APP_NAME")</string>
  <key>CFBundleIconFile</key>
  <string>$(plist_escape "$APP_NAME")</string>
  <key>CFBundleIdentifier</key>
  <string>$(plist_escape "$BUNDLE_ID")</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$(plist_escape "$APP_NAME")</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$(plist_escape "$VERSION")</string>
  <key>CFBundleVersion</key>
  <string>$(plist_escape "$BUILD_NUMBER")</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.finance</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright © 2026 murongg</string>
</dict>
</plist>
PLIST
}

create_app_icon() {
  if [[ ! -f "$ICON_SOURCE" ]] || ! command -v iconutil >/dev/null 2>&1 || ! command -v sips >/dev/null 2>&1; then
    log "Skipping app icon generation"
    return
  fi

  local iconset="$DIST_DIR/$APP_NAME.iconset"
  rm -rf "$iconset"
  mkdir -p "$iconset"

  sips -z 16 16 "$ICON_SOURCE" --out "$iconset/icon_16x16.png" >/dev/null
  sips -z 32 32 "$ICON_SOURCE" --out "$iconset/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$ICON_SOURCE" --out "$iconset/icon_32x32.png" >/dev/null
  sips -z 64 64 "$ICON_SOURCE" --out "$iconset/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$ICON_SOURCE" --out "$iconset/icon_128x128.png" >/dev/null
  sips -z 256 256 "$ICON_SOURCE" --out "$iconset/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$ICON_SOURCE" --out "$iconset/icon_256x256.png" >/dev/null
  sips -z 512 512 "$ICON_SOURCE" --out "$iconset/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$ICON_SOURCE" --out "$iconset/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$ICON_SOURCE" --out "$iconset/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "$iconset" -o "$RESOURCES_DIR/$APP_NAME.icns"
  rm -rf "$iconset"
}

copy_resource_bundles() {
  local bin_path="$1"
  while IFS= read -r bundle; do
    cp -R "$bundle" "$RESOURCES_DIR/"
  done < <(find "$bin_path" -maxdepth 1 -name "${APP_NAME}_*.bundle" -type d | sort)
}

sign_app() {
  case "$SIGNING_MODE" in
    none)
      log "Skipping code signing"
      ;;
    adhoc)
      log "Ad-hoc signing app"
      codesign --force --deep --sign - "$APP_DIR"
      ;;
    identity)
      if [[ -z "$SIGN_IDENTITY" ]]; then
        printf 'SIGN_IDENTITY is required when SIGNING_MODE=identity\n' >&2
        exit 1
      fi
      log "Signing app with identity: $SIGN_IDENTITY"
      codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR"
      ;;
    *)
      printf 'Unknown SIGNING_MODE: %s\n' "$SIGNING_MODE" >&2
      exit 1
      ;;
  esac

  if [[ "$SIGNING_MODE" != "none" ]]; then
    codesign --verify --deep --strict --verbose=2 "$APP_DIR"
  fi
}

create_zip() {
  rm -f "$ZIP_PATH"
  ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"
  log "Created $ZIP_PATH"
}

notarize_app() {
  if [[ "$NOTARIZE" != "1" ]]; then
    return
  fi
  if [[ -z "$APPLE_KEYCHAIN_PROFILE" ]]; then
    printf 'APPLE_KEYCHAIN_PROFILE is required when NOTARIZE=1\n' >&2
    exit 1
  fi

  log "Submitting app for notarization"
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$APPLE_KEYCHAIN_PROFILE" --wait
  log "Stapling notarization ticket"
  xcrun stapler staple "$APP_DIR"
  xcrun stapler validate "$APP_DIR"
  create_zip
}

log "Building $APP_NAME ($CONFIGURATION)"
swift build -c "$CONFIGURATION" --product "$APP_NAME"
BIN_PATH="$(swift build -c "$CONFIGURATION" --show-bin-path)"
EXECUTABLE_PATH="$BIN_PATH/$APP_NAME"
RESOURCE_BUNDLE="$BIN_PATH/${APP_NAME}_C2CBarAssets.bundle"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  printf 'Executable not found: %s\n' "$EXECUTABLE_PATH" >&2
  exit 1
fi
if [[ ! -d "$RESOURCE_BUNDLE" ]]; then
  printf 'Resource bundle not found: %s\n' "$RESOURCE_BUNDLE" >&2
  exit 1
fi

log "Creating app bundle"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$EXECUTABLE_PATH" "$MACOS_DIR/$APP_NAME"
copy_resource_bundles "$BIN_PATH"
create_info_plist
create_app_icon
sign_app
create_zip
notarize_app

log "Package ready: $ZIP_PATH"
