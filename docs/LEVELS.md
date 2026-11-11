# Chapters and weather — v0.3

| Chapter | Set | Combat/content |
|---|---|---|
| 1 | Temperate; gradual daylight/dusk/night | Humans, TESLA/Cybertruck crossing events, night comet, attacking dozer |
| 2 | Fixed night, rain, lightning/thunder, slowly varying fog | Falling-moon story, zombie hordes, Moonborn Titan |
| 3 | Rain | Shared forest/human encounter rules |
| 4 | Snow/cold | Shared forest/human encounter rules |
| 5 | Blizzard/cold | Shared forest/human encounter rules |
| 6 | Fog | Shared forest/human encounter rules |
| 7 | Rain | Shared forest/human encounter rules |
| 8 | Snow/cold | Shared forest/human encounter rules |
| 9 | Night storm | Shared forest/human encounter rules |
| 10 | Blizzard/cold | Shared forest/human encounter rules |

Chapters 1 and 2 have distinct content. Chapters 3–10 currently reuse human combat
with their fixed weather presets, rather than claiming eight additional bespoke stories.
Chapter unlocks persist locally; cash and loadouts reset each attempt.

## Road events and fairness
Traffic gives two seconds of warning and marked central lanes, then crosses the
road horizontally. Collision uses its actual swept path, with at most one damage
event per vehicle. Outer lanes provide escape. A comet crosses the night sky,
impacts beyond the horizon, then spawns three warned shard strikes, leaving two
lanes clear. Other weather chapters can generate warned shard strikes.

Events are capped at twelve active records, expire and clear on restart. Random
events wait during gate windows and do not overlap the dedicated boss director.
Lane strikes show their danger footprint for at least 1.3 seconds. Each lane strike
can damage the player only once. Terrain throws have a separate falling prop for
every marked lane. Visuals never substitute for collision or the one-hit guard.

## Chapter 1 boss: DEFORESTATOR
1500 HP; model scaled to 67% of the previous size. It holds position instead of
closing on a collision deadline. The move cycle is a 2–4 missile fan, telegraphed
ram, then dirt thrown into two lanes. The ram snapshots the player's position,
warns for 1.65 seconds, charges at 32 m/s, can inflict one 30-HP hit, then reverses
to its combat position. It does not track the player indefinitely during the ram.

## Chapter 2 opening and horde
A fourteen-second skippable sequence frames the falling textured Moon, its impact,
and zombies rising from the ground. Run clocks, enemy generation and gates do not
advance during the sequence. Pause/backgrounding preserve the scene state.

Groups of five to eight zombies spawn with a reserved lane gap; up to 64 regular
zombies are active. Their relative advance is 65% of road speed plus their variant
speed. Shamblers dominate (65%), runners (16%) are faster, crawlers (14%) are low and
slower, spitters (5%) are the only ranged variant. Contact removes HP once; passing
behind deducts money once. A spitter fixes the trajectory when launching its spit.
All variants can be killed by physical log/projectile intersections and drop coins.

## Chapter 2 boss: THE MOONBORN TITAN
2100 HP. Alternates tree throws, lane slams, house throws and tree strikes. Special
throws show an incoming prop and a 1.6-second directional QTE: LEFT, DUCK or RIGHT.
Touch buttons, swipes and desktop A/Q, S/Space, D/E are supported. Wrong input or
expiry inflicts 28 HP once; correct input triggers a 1.8-second cinematic dodge.

Three camera compositions rotate without immediate repetition. Combat, cash/debt,
gates and level time freeze during QTE and cinematic dodge; weather may continue
visually. A pause also freezes the QTE deadline and disables its buttons. After the
shot the normal camera, FOV, player scale/rotation and simulation are restored.
No damage or boss progress is granted merely by playing the cinematic.

## Presentation
The road uses shared PBR albedo/normal/roughness maps with repeated mesh UVs.
Night changes actual sun/moon/ambient light and atmospheric colors; there is no
per-frame texture replacement. Wetness changes material roughness, snow blends
coverage on road/ground, and cold sets add frost at screen edges and breath vapor.
Vegetation takes a snow tint in fixed winter chapters. Lightning is a brief real
light/ambient flash with a visible bolt and recorded thunder; fog varies smoothly.
