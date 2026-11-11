# BEAVER MAYHEM
### REVENGE OF THE FOREST

An offline **3D runner shooter for Android**, built in Godot 4.7.2 with GDScript.
One beaver, five lanes, flying logs, angry lumberjacks, weapon seizures, arithmetic
and a very large bulldozer. MIT licensed. Asset sources and free licenses are recorded in [ASSETS.md](docs/ASSETS.md).

[Download the debug APK](https://github.com/CanisLegatus/beaver-mayhem/releases/tag/v0.2.0)

<img src="docs/screenshots/roadmap.png" width="230" alt="Saved ten-chapter roadmap"> <img src="docs/screenshots/family.png" width="230" alt="Opening family cinematic">

<img src="docs/screenshots/gameplay.png" width="270" alt="Five-lane forest battle and math gate"> <img src="docs/screenshots/boss.png" width="270" alt="The DEFORESTATOR boss">

- A saved vertical roadmap of ten chapters; each unlocks after the previous victory.
- A skippable family-at-the-dam story and 360° hero camera orbit before chapter one.
- Day/night lighting and varied forest, river and rock scenery.
- A complete 150-second accelerating run followed by a destructible bulldozer boss.
- Three attacking enemy types, straight shots and staged, dodgeable guided rockets.
- Physical cash pickups, breach penalties, negative balance and ten-second seizures.
- Five weapons, capped upgrades and a shop that stays live while you run.
- Procedural math gates: three answers and two neutral bypass lanes.
- Main menu, pause, victory, defeat, full restart and mute.

## Play
Choose an unlocked chapter on the roadmap (scroll vertically to explore). The first
chapter opens with a twelve-second story; Skip Story begins gameplay immediately.
After victory, continue to the next chapter or return to the map.

Android: drag horizontally to dodge and line up shots. Shooting is automatic.
Collect coins locally. Choose a math answer by crossing its gate; outer lanes skip.
Buy upgrades/weapon tiles at the bottom; tap an owned weapon to equip it, or use ↻
to cycle. Keep cash in reserve: ten seconds in debt costs a purchased asset.

Desktop: mouse drag, A/D or arrow keys. Escape pauses. No jump or dash.

## Develop and build
Open `project.godot` in **Godot 4.7.2 standard** and press F6/F5, or run:

```sh
~/.local/bin/godot --path .
./tools/check.sh
ANDROID_HOME="$HOME/.local/share/beaver-android-sdk" ./tools/build_android.sh
```

Android export needs JDK 17, official Android SDK with Build Tools 36.0.0/Platform
36 and matching Godot templates. Output: `builds/beaver-mayhem-debug.apk`.
See [build/install details](docs/BUILD.md) for setup and ADB commands.

## Status
Version 0.2.0 is a playable Android debug release, with headless rules/integration
checks, deterministic full-scene simulations and graphical Linux checks. Real-device
Android touch, installation and Poco X7 Pro 60 FPS performance are **not verified**.
The ten chapters currently share one ruleset and encounter structure. Progress saves
locally; money and upgrades reset per run. This is not an endless runner or a live-service game. There are no ads, accounts or online requirements.

[Design](docs/GDD.md) · [Architecture](docs/ARCHITECTURE.md) ·
[Balance](docs/BALANCE.md) · [Testing](docs/TESTING.md) ·
[Decisions](docs/DECISIONS.md) · [Итоговый отчёт](docs/DELIVERY.md) · [Plan](PLAN.md) · [MIT license](LICENSE)

Godot Engine is MIT licensed; see the [Godot license and third-party notices](https://godotengine.org/license/).
