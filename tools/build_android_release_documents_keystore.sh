#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT:-/tmp/godot-3.6.2/Godot_v3.6.2-stable_linux_headless.64}"
JAVA_HOME="${JAVA_HOME:-/home/sergiolozano/.local/jdks/jdk-17.0.19+10}"
KEYSTORE_FILE="${RELEASE_KEYSTORE_FILE:-/home/sergiolozano/Documents/Keystore.jks}"
KEY_ALIAS="${RELEASE_KEY_ALIAS:-key0}"
VERSION_CODE="${1:-201}"
VERSION_NAME="${2:-0.20.1}"
EXPECTED_SHA1="${EXPECTED_SHA1:-EC:24:33:14:46:29:71:D1:4C:B0:2B:86:D0:4D:D4:FF:EC:6F:86:B5}"

if [[ ! -f "$KEYSTORE_FILE" ]]; then
  echo "Missing keystore: $KEYSTORE_FILE" >&2
  exit 1
fi

read -rsp "Keystore password for $KEYSTORE_FILE: " STORE_PASS
echo
read -rsp "Key password for alias $KEY_ALIAS (press Enter if same): " KEY_PASS
echo
if [[ -z "$KEY_PASS" ]]; then
  KEY_PASS="$STORE_PASS"
fi

export GODOT="$GODOT_BIN"
export JAVA_HOME

cd "$ROOT_DIR"

./tools/export_game.sh android

rm -rf /tmp/flappy-apk-assets android/build/assets
mkdir -p /tmp/flappy-apk-assets
unzip -q builds/android/FlappyRace.apk 'assets/*' -d /tmp/flappy-apk-assets
mv /tmp/flappy-apk-assets/assets android/build/assets

android/build/gradlew -p android/build clean bundleRelease --no-daemon \
  -Pperform_signing=true \
  -Prelease_keystore_file="$KEYSTORE_FILE" \
  -Prelease_keystore_password="$STORE_PASS" \
  -Prelease_key_password="$KEY_PASS" \
  -Prelease_keystore_alias="$KEY_ALIAS" \
  -Pexport_version_code="$VERSION_CODE" \
  -Pexport_version_name="$VERSION_NAME"

OUT="$ROOT_DIR/android/build/build/outputs/bundle/release/build-release.aab"
FINAL="$ROOT_DIR/FlappyRace-v${VERSION_CODE}-signed-documents-keystore.aab"
cp "$OUT" "$FINAL"

ACTUAL_SHA1="$(keytool -printcert -jarfile "$FINAL" | awk -F'SHA1: ' '/SHA1:/{print $2; exit}')"
echo "Generated: $FINAL"
echo "SHA1: $ACTUAL_SHA1"

if [[ "$ACTUAL_SHA1" != "$EXPECTED_SHA1" ]]; then
  echo "ERROR: Expected SHA1 $EXPECTED_SHA1, but generated $ACTUAL_SHA1" >&2
  exit 2
fi

echo "OK: bundle is signed with the expected Play upload key."
