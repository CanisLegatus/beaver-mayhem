# BEAVER MAYHEM — REVENGE OF THE FOREST

Offline portrait 3D arcade runner/shooter for Android. A cartoon beaver defends the
forest against lumberjacks, engineers and a rocket-launching parody of Elon Musk.
The run lasts 90 seconds before the approaching DEFORESTATOR bulldozer finale.

## Game flow
Main menu → Playing → Victory or Game Over → Play Again. Pause/resume is available
from the HUD, Escape, Android Back, or application backgrounding. Gameplay is frozen
on pause and result screens; purchases never pause. Restart clears health, cash,
upgrades, ownership, heat, cooldowns, actors, loot, effects, gates and spawn timers.

## Movement and combat
The road has five lanes at x = −4, −2, 0, 2, 4 metres. Movement is continuous,
clamped to ±4.6 m, with a maximum lateral speed of 6 m/s (one lane in 0.33 s).
Forward progress is automatic at 8 m/s, represented by scrolling terrain around a
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
| Lumberjack | 24 | straight axe, 4 HP / 3.5 s | $7 | −$12 |
| Engineer | 55 | fast aimed-at-launch paper, 10 HP / 1.8 s | $16 | −$22 |
| Elon parody | 120 | staged rocket, 24 HP / 5 s | $45 | −$40 |

The director spawns continuously with 2.4 → 1.35 s intervals. Engineers enter from
22 s, elites from 35 s. Active threat costs 1/3/7 and is limited by 4 + 12 × progress.
Attacks have a 0.65 s preparation animation. Near gates spawn intervals grow by
25% and enemy attack clocks slow to 65%, without stopping the encounter.
Living enemies crossing behind the runner deduct money once, without HP damage.

Rockets first travel sideways at 5 m/s. At 0.45 s the engine lights with flash,
flame, trailing sparks and sound. Guidance is limited to 2 rad/s until age 1.65 s;
after that trajectory locks. Guided acceleration is capped at 18 m/s. Lifetime
is six seconds; rockets can miss, exit the road and expire. Axes and paper do not guide.

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
Groups spawn at 10, 23, 37, 51, 65 and 79 seconds, 48 m (six seconds) ahead.
The central three lanes each display one unique answer; the outer lanes and gaps
bypass the group without reward or penalty. The HUD repeats the expression,
left-to-right choices and time to crossing so the problem is readable at distance.
Crossing selects at most one answer once. Early tasks use addition/subtraction
(+$30/−$20); middle tasks multiplication/exact division (+$55/−$35); late tasks
add a final term (+$80/−$55). Choices are shuffled independently and contain
exactly one correct result. No zero division or rounding questions.

## Finale
At 90 seconds ordinary spawning stops. Survivors still attack and may breach.
A 600 HP procedural bulldozer appears 38 m ahead, approaches at 1.35 m/s, and
collides at 4.2 m (~25 s deadline). All weapons can hit it. Zero boss HP triggers
stopping, fragmentation/smoke particles, explosion sound and Victory. The dozer
reaching the beaver ends the run regardless of player HP.

## Presentation
Original low-poly forest, five reusable road chunks, trees, stumps, rocks, grass
and distant hills. Beaver has face, eyes, teeth, ears, paws and flat patterned tail.
Enemies have distinct outfits, tools and headgear; the engineer wears a white
helmet. Characters bob, swing feet and prepare attacks. The dozer has tracks,
wheels, cabin, windows, lights, blade and smoking exhaust. Audio is synthesized
locally with eight bounded voices and can be muted. No ads, account, network,
analytics, paid assets or persistent metaprogression in this release.
