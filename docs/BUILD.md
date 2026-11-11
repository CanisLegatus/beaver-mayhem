# Build and install

Pinned engine: **Godot 4.7.2.stable.official.ed1daf0bf**, standard GDScript edition.
Official [engine release](https://godotengine.org/download/archive/4.7.2-stable/)
and matching export templates are required. See the official
[Android export guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html).

## Toolchain
- Linux x86_64; OpenJDK 17 (verified 17.0.21).
- Godot executable in `$HOME/.local/bin/godot` or `GODOT_BIN`.
- Android command-line tools; Build Tools **36.0.0**, Platform **36**, platform-tools.
  The official precompiled 4.7.2 Android template targets API 36; inspect the APK
  manifest rather than assuming the API version from an older documentation sample.
- Matching `android_debug.apk`, `android_release.apk` and `version.txt` in
  `$HOME/.local/share/godot/export_templates/4.7.2.stable/`.

Install the official SDK packages into a writable SDK directory, for example:

```sh
sdkmanager --sdk_root="$HOME/.local/share/beaver-android-sdk" \
  'platform-tools' 'platforms;android-36' 'build-tools;36.0.0'
```

Accept the Android SDK licenses when installing. On this development machine the
existing accepted licenses were reused. Android Studio and Gradle are unnecessary
for native-template debug export. No production signing key is created.

## Reproducible workflow

```sh
./tools/check.sh
ANDROID_HOME="$HOME/.local/share/beaver-android-sdk" ./tools/build_android.sh
```

`GODOT_BIN`, `ANDROID_HOME`/`ANDROID_SDK_ROOT` and `JAVA_HOME` override tool paths.
If a shell exports an older ANDROID_HOME, explicitly point it to the new SDK.
The build script imports the project, configures the two local Godot editor SDK
paths, exports, verifies the signature, prints manifest metadata and writes SHA256SUMS.
It preserves other editor settings and does not write SDK paths or secrets to Git.
Godot manages its conventional debug keystore outside the repository. APK bytes
may vary because of ZIP timestamps/debug signing; the process and source are pinned,
not claimed bit-for-bit reproducible across machines.

Output: `builds/beaver-mayhem-debug.apk` (ARM64, package
`org.canislegatus.beavermayhem`, version 0.2.0/code 2). Prebuilt template minimum
Android API 24; target API 36; OpenGL ES 3.0; portrait; no Internet permission.

```sh
adb devices
adb install -r builds/beaver-mayhem-debug.apk
adb shell am start -n org.canislegatus.beavermayhem/com.godot.game.GodotAppLauncher
```

Alternatively copy the APK to the phone and allow installation from that file
manager. This is a debug build for local testing, not a Play Store production
submission. APKs and keystores are excluded from source history. Release assets
are published on GitHub, with their checksum.

## Godot 4.7.2 native manifest workaround
The stock exporter replaces every provider authority with `<package>.fileprovider`,
including AndroidX Startup. `tools/fix_android_manifest.py` repairs the second
string-pool entry to `<package>.androidx-startup`, then the build script zipaligns
with 16 KiB page alignment and re-signs using the conventional local debug key.
`verify_apk.py` checks distinct authorities, exported launcher, offline permission
policy, ARM64 library and packaged project. The workaround fails closed if the
pinned template structure changes. It uses no production keys. When upgrading
Godot, recheck upstream before removing this workaround.
