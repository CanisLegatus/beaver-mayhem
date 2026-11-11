# BEAVER MAYHEM — REVENGE OF THE FOREST

Current design: v0.3.0. The original runner rules below remain unless superseded by
[LEVELS.md](LEVELS.md), which specifies chapter weather, events, hordes and bosses.
The ten chapter slots share saved sequential progression; chapters 1 and 2 now have
distinct enemies, opening scenes and finales. Chapters 3–10 share forest combat
with different weather presets.

Offline portrait 3D arcade runner/shooter for Android. A cartoon beaver defends the
forest against lumberjacks, engineers and a rocket-launching parody of Elon Musk.
The run lasts 150 seconds before the approaching DEFORESTATOR bulldozer finale.

## Game flow
Campaign map → optional first-chapter cinematic → Playing → Victory or Game Over.
Play Again retries the current chapter; Level Map returns to chapter selection.
Victory unlocks only the next chapter and offers Next Chapter. Chapter one is human forest combat; chapter two is Moonfall/hordes.
The remaining chapters currently reuse forest combat with weather variations. A fresh save unlocks chapter one.
Progress is atomically saved in user://progress.cfg; cash/upgrades reset per attempt. Pause/resume is available
from the HUD, Escape, Android Back, or application backgrounding. Gameplay is frozen
on pause and result screens; purchases never pause. Restart clears health, cash,
upgrades, ownership, heat, cooldowns, actors, loot, effects, gates and spawn timers.

## Movement and combat
The road has five lanes at x = −4, −2, 0, 2, 4 metres. Movement is continuous,
clamped to ±4.6 m, with a maximum lateral speed of 8 m/s (one lane in 0.25 s).
Forward progress is automatic from 10 to 15 m/s, represented by scrolling terrain around a
floating origin. Drag horizontally with one finger; desktop supports mouse drag,
A/D and arrows. HUD interaction does not steer. No jump, dash or invulnerability.

Shots fire automatically. Base logs, heavy logs, twin logs and fixed fan rays keep
their spawn trajectory; they do not target enemies. Ground-plane swept collision
is authoritative. Normal rounds hit the nearest intersecting live target once.
Heavy rounds hit up to three distinct targets once each. Fast laser bolts travel
straight along the firing line and use the same swept collision logic.
The beaver starts with 100 HP. Hostile hits consume their projectile; 0 HP loses.
Screen flash, recoil, particles and sounds give hit feedback.

## Enemies and progression
| Type | HP | Attack / interval | Reward | Breach |
|---|---:|---|---:|---:|
| Lumberjack | 24 | straight axe, 2 HP / 3.5 s | $10 | −$5 |
| Engineer | 55 | fast aimed-at-launch paper, 4 HP / 1.8 s | $25 | −$10 |
| Elon parody | 120 | staged rocket, 12 HP / 3.2 s | $55 | −$18 |

The director spawns continuously with 1.35 → 0.65 s intervals. Engineers enter from
22 s, elites from 35 s. Active threat costs 1/3/7 and is limited by 8 + 17 × progress.
Attacks have a 0.65 s preparation animation. Near gates spawn intervals grow by
25% and enemy attack clocks slow to 65%, without stopping the encounter.
Living enemies crossing behind the runner deduct money once, without HP damage.

Rockets first travel sideways at 5 m/s. At 0.22 s the engine lights with flash,
flame, trailing sparks and sound. Guidance is limited to 2.8 rad/s until age 1.65 s;
after that trajectory locks. Guided acceleration is capped at 34 m/s. Lifetime
is twelve seconds; rockets can miss, exit the road and expire. Axes and paper do not guide.

## Cash, debt and choices
Start with $40. Kills drop three physical rotating coins with an exact total equal
to the reward. They scatter slightly, bounce and scroll with the road. A 1.15 m
local magnet helps pickup; collection requires 0.55 m proximity. Distant lanes
never credit money. Passed coins expire.

Money can be negative. Continuous debt starts BANKRUPTCY ALERT, a flashing red
balance, alarm and ten-second countdown. Every ten seconds a randomly selected
eligible upgrade loses one level or one owned non-base weapon is seized. If the
active weapon is seized the beaver equips base logs. No eligible purchases is
safe; debt does not directly end the run. Recovery to zero resets the timer.

The compact live shop offers DAMAGE and FIRE RATE, four levels each. Price rises
per level. Insufficient cash and negative balance block purchases. Owned weapons
can be selected by tapping their tile; the current-weapon button cycles ownership.
Only one configuration fires at a time. Heat persists across switching.

## Weapons
| Weapon | Cost | Role |
|---|---:|---|
| Logs | free, protected | reliable one-line fire |
| Fan | $100 | three fixed directions, reduced per-shot damage |
| Heavy | $130 | slow high damage, three-target penetration |
| Twin | $155 | two parallel lines offset ±0.5 m, reduced damage |
| Laser | $190 | fast straight energy bolts, ~2.2 s heat then ~2 s cooling |

Exact values and DPS are in BALANCE.md and config/balance.json.

## Math gates
Groups spawn at 14, 31, 49, 67, 85, 103, 121 and 139 seconds. Their initial
distance integrates the next seven seconds of accelerating speed (about 71–105 m).
The central three lanes each display one unique answer; the outer lanes and gaps
bypass the group without reward or penalty. The HUD repeats the expression,
left-to-right choices and time to crossing so the problem is readable at distance.
Crossing selects at most one answer once. Early tasks use addition/subtraction
(+$30/−$20); middle tasks multiplication/exact division (+$55/−$35); late tasks
add a final term (+$80/−$55). Choices are shuffled independently and contain
exactly one correct result. No zero division or rounding questions.

## Finale
At 150 seconds ordinary spawning stops. Remaining enemies remain dangerous.
The chapter-one dozer has 1500 HP and a smaller silhouette; it holds position,
fires missile fans, telegraphs targeted rams and throws dirt into marked lanes.
The chapter-two Titan has 2100 HP, tree/house throws, lane slams and directional
QTE cinematic dodges. There is no passive boss collision countdown. Physical
projectile damage is required to win. See LEVELS.md for exact attack and QTE rules.

## Presentation
Atmospheric forest, seven reusable road chunks, trees, stumps, rocks, grass
and distant hills. Beaver has face, eyes, teeth, ears, paws and flat patterned tail.
Enemies have distinct outfits, tools and headgear; the engineer wears a white
helmet. Characters bob, swing feet and prepare attacks. The dozer has tracks,
wheels, cabin, windows, lights, blade and smoking exhaust. Original cues are mixed with downloaded CC0 recordings and a chapter/boss action
soundtrack; eight bounded SFX voices plus one music voice can be muted. No ads, account, network,
analytics or paid assets. Chapter unlocks persist locally.

## v0.2 presentation and opening story
The first chapter starts with the mother beaver and kit seated at their damaged
dam, reaching toward its logs and crying. They carry no weapons. The hero walks
forward while the camera completes a 360° orbit, then eases to the gameplay view.
The story lasts twelve seconds, freezes run clocks/spawns, can be skipped and
pauses correctly when backgrounded. Retrying a failed run starts gameplay directly;
selecting chapter one from the map replays the story.

Enemies spawn 115 m ahead in horizon haze. Elites prime a rocket at 0.12 s from
birth and repeat every 3.2 s. Friendly projectiles remain straight; the extended
projectile bounds allow those far-away rockets to survive their initial flight.
Daylight, dusk, night and dawn cycle over 110 seconds. Moonlight and ambient fill
preserve visibility at night. Pine and broadleaf groves alternate with rivers,
flowers, fallen logs, stumps and rock formations. Detailed smooth character meshes
use procedural fur/cloth materials; downloaded CC0 textures supply smoke, sparks
and flashes. The photorealistic beaver icon is AI generated; see ASSETS.md.
