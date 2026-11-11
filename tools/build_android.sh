#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-$HOME/.local/bin/godot}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk}"
export ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
mkdir -p builds
"$GODOT_BIN" --headless --editor --import --quit
"$GODOT_BIN" --headless --export-debug Android builds/beaver-mayhem-debug.apk
"$ANDROID_HOME/build-tools/35.0.0/apksigner" verify --verbose builds/beaver-mayhem-debug.apk
"$ANDROID_HOME/build-tools/35.0.0/aapt" dump badging builds/beaver-mayhem-debug.apk
sha256sum builds/beaver-mayhem-debug.apk > builds/SHA256SUMS
