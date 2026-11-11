# Architecture

`scenes/main.tscn` instantiates BeaverGame, the composition root. Systems are
separate Node3D children, pure rules are RefCounted classes, and view objects are
created procedurally. Global class names are imported by Godot before CLI tests.

| File | Responsibility |
|---|---|
| config/balance.json | one authoritative balance/configuration source |
| core/rules.gd | weapon stats, upgrade costs, difficulty, math, movement, swept intersections, rocket steering |
| core/health.gd | clamped HP and exactly-once death signal |
| core/economy.gd | signed money, ownership, purchasing, debt clocks, seizures |
| systems/player_controller.gd | bounded movement, drag ownership, mouse/keyboard mapping |
| systems/combat.gd | firing cadence, configuration, laser heat |
| systems/projectiles.gd | bounded shots, straight/guided motion, physical collision, lifetime and target hit sets |
| systems/enemies.gd | director, enemy attack clocks/animation, health, breaches, boss lifecycle |
| systems/loot.gd | physical pickup, local magnet, exact rewards, expiry |
| systems/gates.gd | gate schedule, generated questions, once-only crossing |
| view/art.gd | shared primitive meshes/materials, character/weapon/dozer geometry |
| view/world.gd | sky, light, scenery, road chunks and static MultiMesh batching |
| view/hud.gd | responsive UI, safe-area offsets, live shop and screen states |
| view/effects.gd | capped short-lived mesh debris/sparks |
| view/audio.gd | generated PCM assets, eight reusable voices, cleanup |
| main.gd | signal wiring, run states and ordered simulation |

## Signals and data
Enemy attacks emit spawn data to ProjectileSystem. Projectile impacts damage Health
and emit VFX/audio events; hostile intersections emit player_hit. EnemySystem
consumes deaths once and emits loot drops, breaches or boss_destroyed. Loot pickup
and gate crossing credit Economy. Economy emits debt_started, confiscated and
changed. HUD actions invoke purchases, weapon cycling and state transitions.
No visual label is the source of game state.

Actors/shots/coins/gates use system-owned records containing stable IDs, positions,
health or one-shot state and a visual Node3D. They are not physics bodies: authoritative
collisions use a swept segment against circles on the x/z plane, matching the
single projectile height. Ground-plane position is independent from bobbing/roll.
Friendly targets are sorted nearest-first. A projectile remembers hit IDs, and
penetration consumes a finite hit count. Death and breach remove records before
they can reward/penalize again. Node deletion is queued for frame-safe teardown.

## Frame order
Input → forward/lateral movement → world/character → firing → gates → spawning →
projectile sweeps → enemy motion/deaths/attacks → loot → debt → effects → HUD.
The result state is checked between combat phases. Moving targets are sampled once
per 60 Hz physics tick; they cannot cross a full target diameter in one tick at
configured speeds. Pause/result screens do not advance simulation clocks.

## Bounded resources and reset
Five road chunks wrap rather than allocate indefinitely. Shared mesh/material
caches and scenery MultiMeshes reduce allocation and draw calls. Caps: 22 ordinary
enemies (+boss), 160 projectiles, 90 coin objects (a drop may add up to two over the
threshold), 96 particles and eight audio voices. Off-road/old shots and passed
loot/gates expire. There is no unbounded enemy HP scaling.

Restart clears all actor collections, player state, weapon heat, economy and
schedules. World chunks are reused; their scroll phase is cosmetic. The director
and gate RNG continue a random stream for new questions/encounters; tests seed them
explicitly. Audio voices stop and release streams when leaving the scene tree.
