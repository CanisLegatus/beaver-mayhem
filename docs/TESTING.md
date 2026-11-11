# Verification — v0.3.0

## Commands

```sh
./tools/check.sh
~/.local/bin/godot --path . --script res://tests/gui_input.gd
~/.local/bin/godot --path . --script res://tests/capture_v3.gd
~/.local/bin/godot --path . --script res://tests/profile_v3.gd
ANDROID_HOME="$HOME/.local/share/beaver-android-sdk" ./tools/build_android.sh
python3 tools/report_balance.py
```

`check.sh` imports resources, runs the original 2819 assertions, 100 new geometry/
weather/events/QTE assertions, two physical boss fights and 33 full-scene simulations.
It rejects failed assertions, script/runtime errors and leaked-object warnings.
Headless tests load audio assets but avoid starting asynchronous audio decoders;
playback is exercised in graphical checks instead. Generated logs/metrics/APKs stay in ignored builds/. Tests use isolated campaign
save paths; they do not overwrite the player's progress.

## Coverage
The original suite covers bounded movement/touch ownership, fixed player-shot
trajectories, swept hits, damage/death/loot once, piercing, physical coin collection,
purchases, signed debt/seizures, math generation/answers, health, restart, campaign
unlock persistence, pause and story handoff. Boss expectations were changed from
passive collision to the new stationary attack model.

The v3 suite checks outward sculpt normals, opaque body shaders, stable road
material identity, continuous lighting, chapter-specific rain/snow/night, strike
windups/safe lanes/once-only damage, swept truck contact and expiry, comet shards,
horde composition/cap, runner/crawler speeds, spitter-only ranged attacks, zombie
contact/breach guards, smaller stronger dozer, missile fan count, warned charge,
ram damage once, titan health, QTE success/failure/timeout/pause/button guards,
nonrepeating camera selection, combat-time freeze, lens/player restoration,
moon-impact story handoff and complete reset of every new subsystem.

Boss-fight fixtures use a declared pre-funded heavy build to exercise the entire
attack state machines through physical shots; they do not claim that this build was
earned in a normal run. Both bosses were defeated. Full-run simulations do not
receive extra HP or money; their bot can dodge and answer QTEs. The chapter-two
horde remains demanding, and these bot outcomes are not human win rates. Exact
outcomes and seeds are recorded in simulation-results.json/BALANCE.md.

## Graphical and APK checks
Thirteen graphical viewport input checks cover map/story/skip, drag, live purchase,
HUD isolation, pause/retry, offline credits, chapter-two selection, moon skip and
QTE button/cinematic return. Captures show opaque beaver backs, traffic, dozer,
falling Moon, uprising, rain/horde, titan, QTE, dodge and snow. They are real rendered
scripted fixtures; they are not screenshots of human-earned victories.

Dense Linux profiles use 16 human enemies or 64 zombies with storm at internal
432×864. The test-only HP increase prevents profile interruption; it is separate
from normal balance simulations. Exact frame/draw-call measurements are in
profile-results.json. These are desktop frame intervals, not Android or GPU-only
benchmarks. Shader/material identity is stable across time and chunk recycling.

Android output is debug-signed ARM64, package org.canislegatus.beavermayhem,
version 0.3.0/code 3, minimum API 24, target API 36, GLES 3, portrait. Build validation
checks 16 KiB ZIP alignment, signature, unique repaired provider authorities,
launcher alias, bundled game and absence of private signing keys. Music/license
credits ship in the APK and can be opened offline with the map's i button.

## Limits
No authorized Android device is attached. Real-device installation, gestures,
cutouts, thermal behavior and sustained Poco X7 Pro 60 FPS are not verified.
Desktop/bot/structural APK checks do not establish those results. Music was
loudness-normalized and ducking added for recorded speech, but subjective phone
speaker intelligibility still needs listening and playtesting. Device acceptance
remains tracked in issue #1.
