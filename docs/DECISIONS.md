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
