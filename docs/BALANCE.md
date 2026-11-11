# Balance — 0.3.0

Source: config/balance.json. See LEVELS.md for attack windows/weather/QTE rules.

## Tempo and enemy pressure

Run before boss: 150 seconds; speed 10 → 15 m/s; lateral 8 m/s. The road covers
1875 m before the finale. Human spawn intervals 1.35 → 0.65 s, active threat 8 → 25,
up to 32 humans. Chapter two spawns packs of 5–8, capped at 64 regular zombies.
Zombie advance is road speed × 0.65 plus variant speed, slower than the human march.

| Human | HP | Shot damage | Reward | Breach |
|---|---:|---:|---:|---:|
| LUMBERJACK | 24 | 2 | $10 | $5 |
| ENGINEER | 55 | 4 | $25 | $10 |
| ELON | 120 | 12 | $55 | $18 |

| Zombie | HP | Speed offset | Contact/spit damage | Reward / breach |
|---|---:|---:|---:|---:|
| SHAMBLER | 18 | -2.8 | 3 | $3 / $2 |
| RUNNER | 24 | 2 | 6 | $5 / $3 |
| CRAWLER | 14 | -3.8 | 2 | $3 / $2 |
| SPITTER | 40 | -2 | 6 | $10 / $5 |

More actors and faster missiles are compensated by lower ordinary per-hit damage.
Elites prime at 0.12 s, repeat 3.2 s; engine ignition at 0.22 s, guidance ends at
1.65 s, turn capped 2.8 rad/s, acceleration 54 m/s² to 34 m/s. Firing direction
locks afterward. Telegraphs, finite turns and reserved horde gaps allow avoidance.

## Progression and weapons

Start $40; configurations total $575; damage levels cost $550 total, rate $520.
Whole shop totals $1645. Eight correct gates award $540; missed coins do not credit.
Increased spawn density raises potential income and breach exposure. Negative cash
remains playable and can confiscate assets every ten seconds.

| Weapon | Damage × count | Interval | Base sustained DPS | Max sustained DPS |
|---|---:|---:|---:|---:|
| log | 12 × 1 | 0.4 s | 30.00 | 86.40 |
| fan | 6.5 × 3 | 0.48 s | 40.62 | 117.00 |
| heavy | 31 × 1 | 0.85 s | 36.47 | 105.04 |
| twin | 7.5 × 2 | 0.42 s | 35.71 | 102.86 |
| laser | 6 × 1 | 0.1 s | 31.43 | 90.51 |

Four capped levels each multiply damage by up to 1.8 and rate by 1.6: 2.88× maximum.
Fan sums three rays, so distant single targets often take one. Heavy pierces three
unique targets. Twin offsets ±0.5 m. Laser burst DPS 60, with heat/cooling duty.
At illustrative 60% accuracy multiply sustained DPS by 0.6. HP 24/55/120 require
2/5/10 base log hits; 18-HP shamblers require two, maximum damage logs one.

## Bosses

Dozer: 1500 HP, scale 0.67, no passive advance. Missile fans, warned ram (30 HP once)
and lane dirt throws (18 HP). Titan: 2100 HP, throws/slams and QTE failure (28 HP once).
Physical DPS is still required to win. Ideal base-log firing time is 50/70 seconds;
maximum ideal logs 17.4/24.3 seconds. Attacks, movement and travel extend this.
QTE/cinematic time freezes all combat and does not deal free boss damage.

## Full-scene probes

33 attempts: nine strategies × three seeds in chapter one, fan/heavy × three in
chapter two. All gameplay RNG sources are seeded. The bot uses a simple projectile
predictor, lane warnings, contact avoidance and QTE response. It receives no free
HP/cash. These are development probes, not human win rates or proof of final tuning.

| Chapter | Strategy | Wins / attempts | Winning boss combat range | Final cash range |
|---|---|---:|---:|---:|
| 1 | base | 0 / 3 | — | $292 to $474 |
| 1 | damage | 0 / 3 | — | $110 to $319 |
| 1 | rate | 0 / 3 | — | $62 to $242 |
| 1 | fan | 0 / 3 | — | $-73 to $31 |
| 1 | heavy | 1 / 3 | 20.1–20.1 s | $158 to $578 |
| 1 | twin | 0 / 3 | — | $-23 to $157 |
| 1 | laser | 0 / 3 | — | $14 to $116 |
| 1 | bad_math | 0 / 3 | — | $-351 to $-299 |
| 1 | losses | 0 / 3 | — | $-14 to $62 |
| 2 | fan | 1 / 3 | 96.8–96.8 s | $-147 to $70 |
| 2 | heavy | 2 / 3 | 28.8–34.5 s | $25 to $67 |

QTE movies do not advance the reported combat clock. Separate boss-fight fixtures
pre-fund a heavy build explicitly to validate whole attack loops and physical victory;
they are not counted as earned-loadout runs. Both bosses were defeated in those fixtures.
Chapter two remains demanding. Phone/human playtesting is needed before claiming
production difficulty or accessibility across skill levels.

[Raw outcomes](simulation-results.json). Regenerate with tools/check.sh and
python3 tools/report_balance.py.
