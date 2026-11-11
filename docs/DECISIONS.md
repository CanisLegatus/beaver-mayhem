# Decisions
- Godot 4.7.2 official standard build, Compatibility/OpenGL ES 3 renderer: widest mobile compatibility and uncomplicated procedural materials. Android native templates, no Gradle dependency.
- Floating origin: player longitudinal distance increases at 8 m/s; the world approaches a stable runner origin. This preserves precision, camera stability and straight projectile trajectories without endless scene growth.
- Swept 2D ground-plane collision is authoritative for the single-height runner. Radius includes projectile width; nearest intersections consume normal ammunition. Heavy ammunition remembers target IDs.
- Five lanes, continuous lateral movement limited to 6 m/s. Outer two lanes bypass math; the central three contain answers.
- Original procedural meshes and synthesized PCM sound require no external asset licenses or online runtime.
- Logic composition: pure Rules/Health/Economy; independent runtime systems; view-only art/HUD/audio/effects; main scene wires signals.
- Heat survives weapon switching; purchases never pause; pause stops the simulation without changing the SceneTree pause mode.
- Release uses debug signing only. Local SDK paths and keystore remain outside version control. Export needs ETC2 import enabled even though this release uses no bitmap textures.
- The prebuilt 4.7.2 template manifest targets Android API 36. Installed official
  SDK Platform 36 / Build Tools 36.0.0 in a user-owned SDK directory to avoid older
  build-tools fallback. Existing /opt SDK and JDK were preserved.
- The HUD repeats gate math and time to crossing: distant 3D text alone is too small
  on a phone. Only the central three lane answers can resolve a group.
- Emulated mouse input is ignored by the player controller while retained for GUI
  controls, preventing a physical touch from applying movement twice.

- Confirmed upstream native exporter issue: [4.7.2 provider authority replacement](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/export/export_plugin.cpp#L1383)
  rewrites both FileProvider and AndroidX Startup to the same authority. Repair only
  the manifest string pool after export, align and re-sign with the local debug key;
  validate using Android's independent aapt parser and apksigner. The public launcher
  is the GodotAppLauncher alias; GodotApp itself is intentionally not exported.

## v0.2 — player feedback
- Expand runs to 150 seconds and ramp speed 10 → 15 m/s. Steering rises to 8 m/s.
  Share the curve across all relative-world systems so coins and gates do not drift.
- Spawn enemies 115 m away in haze; integrate a seven-second gate approach. Extend
  projectile bounds/lifetime for immediate far elite launches (0.12 s / 3.2 s repeat).
- Lower breach penalties to 5/10/18 and raise rewards to 10/25/55, especially engineers.
- Ten identical chapters are a real saved progression, not ten unguarded menu links.
  Only next chapter unlocks on victory; reset cash/weapons per attempt.
- A twelve-second skippable 3D family/dam story runs before chapter one. Story time
  is independent of the run and background pause preserves its camera state.
- Use original smooth sculpted meshes/materials and downloaded CC0 audio/VFX. Keep
  sources/licenses in the repo and APK. Photorealism is reserved for the generated
  launcher icon; in-game models remain mobile-oriented semi-realistic 3D assets.
- Disable 3D while the roadmap is open. Merge static character parts by material
  while preserving named foot animation pivots; batch distant trees as well.
