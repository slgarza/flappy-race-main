#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PROJECT_PATH="${PROJECT_PATH:-$ROOT_DIR/ios/FlappyRace.xcodeproj}"
SCHEME="${SCHEME:-FlappyRace}"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/builds/ios}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$BUILD_DIR/FlappyRace.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$BUILD_DIR/export}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-$BUILD_DIR/export_options.generated.plist}"
INFO_PLIST="${INFO_PLIST:-$ROOT_DIR/ios/FlappyRace/FlappyRace-Info.plist}"
EXPORT_METHOD="${EXPORT_METHOD:-app-store-connect}"
IOS_BUILD_NUMBER="${IOS_BUILD_NUMBER:-$(date -u +%Y%m%d%H%M)}"

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: $name" >&2
    exit 1
  fi
}

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing required command: $name" >&2
    exit 1
  fi
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "iOS archives and App Store uploads need macOS with Xcode installed." >&2
  exit 1
fi

require_env ASC_KEY_ID
require_env ASC_ISSUER_ID
require_env ASC_KEY_PATH

if [[ ! -f "$ASC_KEY_PATH" ]]; then
  echo "ASC_KEY_PATH does not exist: $ASC_KEY_PATH" >&2
  exit 1
fi

require_command xcodebuild
require_command xcrun

mkdir -p "$BUILD_DIR" "$EXPORT_PATH"

restore_info_plist=""
if [[ -z "${IPA_PATH:-}" ]]; then
  require_env APPLE_TEAM_ID
  require_command /usr/libexec/PlistBuddy

  restore_info_plist="$(mktemp)"
  cp "$INFO_PLIST" "$restore_info_plist"
  trap 'if [[ -n "$restore_info_plist" && -f "$restore_info_plist" ]]; then cp "$restore_info_plist" "$INFO_PLIST"; rm -f "$restore_info_plist"; fi' EXIT

  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $IOS_BUILD_NUMBER" "$INFO_PLIST"
  if [[ -n "${IOS_VERSION:-}" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $IOS_VERSION" "$INFO_PLIST"
  fi

  cat >"$EXPORT_OPTIONS_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>$EXPORT_METHOD</string>
  <key>destination</key>
  <string>export</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>$APPLE_TEAM_ID</string>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
PLIST

  echo "Archiving $SCHEME ($CONFIGURATION) with build number $IOS_BUILD_NUMBER..."
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk iphoneos \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$ASC_KEY_PATH" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_STYLE=Automatic \
    clean archive

  echo "Exporting IPA..."
  rm -rf "$EXPORT_PATH"
  mkdir -p "$EXPORT_PATH"
  xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$ASC_KEY_PATH" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID"

  IPA_PATH="$(find "$EXPORT_PATH" -maxdepth 1 -name "*.ipa" -print -quit)"
fi

if [[ -z "${IPA_PATH:-}" || ! -f "$IPA_PATH" ]]; then
  echo "IPA not found. Set IPA_PATH=/path/to/App.ipa or check the export output." >&2
  exit 1
fi

echo "Validating $IPA_PATH..."
xcrun altool \
  --validate-app \
  --type ios \
  --file "$IPA_PATH" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID" \
  --p8-file-path "$ASC_KEY_PATH"

echo "Uploading $IPA_PATH to App Store Connect..."
xcrun altool \
  --upload-app \
  --type ios \
  --file "$IPA_PATH" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID" \
  --p8-file-path "$ASC_KEY_PATH"

echo "Upload finished. App Store Connect still needs to process the build before it appears in TestFlight."
