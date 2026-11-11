#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-$HOME/.local/bin/godot}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk}"
if [[ -d "$HOME/.local/share/beaver-android-sdk/build-tools/36.0.0" ]]; then
  beaver_sdk_default="$HOME/.local/share/beaver-android-sdk"
else
  beaver_sdk_default=/opt/android-sdk
fi
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$beaver_sdk_default}}"
# Existing shells may point at an older SDK. Pass ANDROID_HOME explicitly to override.
if [[ ! -d "$ANDROID_HOME/build-tools/36.0.0" ]]; then
  echo 'Android Build Tools 36.0.0 required; see docs/BUILD.md.' >&2
  exit 1
fi
mkdir -p builds
"$GODOT_BIN" --headless --editor --import --quit
# Configure only the two export paths in the local editor settings, never in Git.
python3 - <<'PY'
import os, pathlib, re, json
base = pathlib.Path(os.environ.get('XDG_CONFIG_HOME', pathlib.Path.home()/'.config'))
p = base/'godot/editor_settings-4.7.tres'
s = p.read_text()
for key, value in [('export/android/java_sdk_path', os.environ['JAVA_HOME']),
                   ('export/android/android_sdk_path', os.environ['ANDROID_HOME'])]:
    line = key + ' = ' + json.dumps(value)
    if re.search(r'^'+re.escape(key)+r' = .*$', s, re.M):
        s = re.sub(r'^'+re.escape(key)+r' = .*$', lambda m: line, s, flags=re.M)
    else:
        s += '\n' + line + '\n'
p.write_text(s)
PY
"$GODOT_BIN" --headless --export-debug Android builds/beaver-mayhem-debug.apk
python3 tools/fix_android_manifest.py builds/beaver-mayhem-debug.apk builds/beaver-mayhem-unsigned.apk
"$ANDROID_HOME/build-tools/36.0.0/zipalign" -P 16 -f 4 builds/beaver-mayhem-unsigned.apk builds/beaver-mayhem-aligned.apk
"$ANDROID_HOME/build-tools/36.0.0/apksigner" sign \
  --ks "${BEAVER_DEBUG_KEYSTORE:-$HOME/.local/share/godot/keystores/debug.keystore}" \
  --ks-key-alias androiddebugkey --ks-pass pass:android --key-pass pass:android \
  --out builds/beaver-mayhem-debug.apk builds/beaver-mayhem-aligned.apk
rm builds/beaver-mayhem-unsigned.apk builds/beaver-mayhem-aligned.apk
"$ANDROID_HOME/build-tools/36.0.0/zipalign" -c -P 16 4 builds/beaver-mayhem-debug.apk
"$ANDROID_HOME/build-tools/36.0.0/apksigner" verify --verbose builds/beaver-mayhem-debug.apk
"$ANDROID_HOME/build-tools/36.0.0/aapt" dump badging builds/beaver-mayhem-debug.apk
"$ANDROID_HOME/build-tools/36.0.0/aapt" dump xmltree builds/beaver-mayhem-debug.apk AndroidManifest.xml > builds/manifest.txt
python3 tools/verify_apk.py builds/beaver-mayhem-debug.apk builds/manifest.txt
sha256sum builds/beaver-mayhem-debug.apk | sed 's@builds/@@' > builds/SHA256SUMS
