# Verification — 2026-11-12

## Commands

```sh
./tools/check.sh
~/.local/bin/godot --path . --script res://tests/gui_input.gd
~/.local/bin/godot --path . --script res://tests/capture_v2.gd
~/.local/bin/godot --path . --script res://tests/profile.gd
ANDROID_HOME="$HOME/.local/share/beaver-android-sdk" ./tools/build_android.sh
python3 tools/report_balance.py
```

`check.sh` imports classes/resources, rejects script errors, runs the independent
rules/integration suite and 27 deterministic full-scene simulations. It treats
failures, runtime errors and leaked-object warnings as failures. Logs are written
to ignored builds/. Tests do not require a third-party framework.

## Results and scope
- **2819 assertions passed**, zero failures: movement bounds/speed/reset; independent
  straight shots; actual swept hits; ordinary vs heavy penetration and per-target
  hit guards; HP/death once; all three enemy attacks; rocket side launch, engine,
  angular bound and final lock; offscreen expiry; physical coin collection vs distant
  coins; exact drop totals; breach once without HP; purchase affordability/caps;
  signed debt, ten-second seizures, recovery and protected base weapon; 450 independent
  arithmetic questions with unique answers; gate crossing once, skip, wrong/correct;
  laser overheat/cooling; real boss damage, collision defeat and projectile victory;
  complete restart, repeated restart, pause/resume and continuing live purchases.
- **27 deterministic simulations**, real scene and projectiles, no player health/cash
  overrides. Nine strategies × three seeds. Object-cap invariants pass. Detailed
  outcomes are recorded in BALANCE.md and simulation-results.json. These are bot
  probes, not claims that a human tester played 27 sessions.
- **7 graphical viewport input checks passed** on Linux: chapter selection/story skip, mouse drag,
  live upgrade button, HUD input isolation, resume, restart. They exercise GUI input
  propagation in a rendered window. Synthetic ScreenTouch/ScreenDrag ownership and
  suppression of emulated duplicate mouse input are tested separately by the rules suite.
- Linux editor opened successfully with OpenGL 4.6/Mesa 26.2.6 on AMD Lucienne.
  The game was launched in a real graphical session. Captured and visually inspected
  menu, 3D gameplay/gates, boss and victory at an internal portrait 432×864 viewport.
  Captures are scripted fixtures; they are not screenshots of human-earned victories.
- APK export completed using matching 4.7.2 native Android templates. Signature
  verification passed, and manifest reports package org.canislegatus.beavermayhem,
  version 0.2.0/code 2, ARM64 only, min API 24, target API 36, GLES 3.0, portrait.
  APK contents were inspected and SHA256SUMS generated. After repairing the pinned
  native exporter's duplicate-provider authorities, the APK was re-aligned (16 KiB),
  re-signed and independently parsed by aapt. Structural checks verify unique
  authorities, launcher alias, packaged game, offline policy and absence of keys. This is a real signed APK,
  not a renamed archive or source-only delivery.

## Graphical checks and performance
See screenshots/ and profile-results.json. For 600 measured frames at 432×864,
Metrics for the current character batching pass are recorded in profile-results.json.
This is a frame-paced Linux sample, not a GPU-only benchmark or Android result. The profile uses a deliberately dense
rendered fixture (12 initial enemies, fan, gate) with elevated test-only HP so the
measurement is not interrupted by defeat. This fixture is separate from balance
simulations, which never grant extra HP. Timing describes this Linux machine only.
The five scenery chunks batch static geometry with MultiMesh, share primitives and
materials, and reuse positions. Actors/projectiles/coins/VFX and audio are capped.

## Not verified
No authorized device appeared in `adb devices`. Consequently Android installation,
real touch gestures, cutout/navigation safe areas, background/resume on hardware,
thermal behavior and 60 FPS on Poco X7 Pro are **not measured**. APK structural and
signature verification do not establish those device results. No automated Android
emulator result is claimed. Audio streams are generated and playback calls run;
subjective speaker loudness and mix still need phone listening tests.

## Recommended phone acceptance pass
Install the release APK; start a run; drag across every lane; buy while steering;
check pause/back/background; hit and skip gates; take projectile damage; trigger
negative cash and seizure; win/lose and restart repeatedly. Check text, safe areas,
rocket telegraphs and heat on the actual display. Measure a full run with device
profiling tools, including frame pacing and temperature. Report device/build/OS
with each observation. Do not mark these steps passed without performing them.

## v0.2 additional coverage
Tests verify fresh saves, sequential unlocks, locked-level guards, persisted reload,
corrupt-value bounds, chapter-10 cap and replay stability. Actual projectile boss
victory unlocks the next chapter. Opening-map state, family visibility, cinematic
pause/time isolation and final camera position are checked. Speed endpoints,
integrated distance, speed-dependent preview distance, horizon births, immediate
elite launch, far rocket survival, repeat interval and night lighting are checked.
Screenshots now include roadmap (locked/unlocked), family, hero orbit, day/night,
combat, boss and victory. Captures remain scripted fixtures rather than human runs.
Music/samples load and play in the rendered session; subjective mixing and phone
loudness remain unverified. Ten chapters intentionally reuse content, as requested.
