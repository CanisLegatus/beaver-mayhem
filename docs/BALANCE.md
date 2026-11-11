# Balance — 0.2.0

Runtime source: `config/balance.json`. All ten chapters currently use this same
ruleset; only campaign unlock/selection persists. Cash and upgrades reset each run.

## Tempo and economy

Run: 150 seconds before the boss. Forward speed ramps from 10
to 15 m/s; lateral speed is 8 m/s (one lane in 0.25 s).
Integrated road distance to boss: 1875 m. Enemy spawn distance: 115 m, hidden
in horizon haze rather than born near the camera. Gate approach distance is
computed by integrating the next seven seconds of speed, growing 70.8–105 m.

| Enemy | HP | Reward | Breach penalty | Attack interval |
|---|---:|---:|---:|---:|
| LUMBERJACK | 24 | $10 | $5 | 3.5 s |
| ENGINEER | 55 | $25 | $10 | 1.8 s |
| ELON | 120 | $55 | $18 | 3.2 s |

The elite primes its first rocket at 0.12 s after spawning, including at the
horizon. Later attacks repeat every 3.2 s; guidance remains limited and locks
after 1.65 s. Rockets have twelve seconds of life to cover the longer approach.

Start cash $40; weapon configurations total $575.
Damage costs [65, 100, 155, 230] ($550 total);
rate costs [60, 95, 145, 220] ($520 total). Full arsenal and
upgrades cost $1645. Eight gate groups spawn at 14/31/49/67/85/103/121/139 s.
Answering all correctly awards $540. Breaches are deliberately more forgiving
than v0.1; physical pickup and meaningful debt/seizure rules remain unchanged.

## Weapons

| Weapon | Damage × count | Interval | Base sustained DPS | Max sustained DPS |
|---|---:|---:|---:|---:|
| log | 12 × 1 | 0.4 s | 30.00 | 86.40 |
| fan | 6.5 × 3 | 0.48 s | 40.62 | 117.00 |
| heavy | 31 × 1 | 0.85 s | 36.47 | 105.04 |
| twin | 7.5 × 2 | 0.42 s | 35.71 | 102.86 |
| laser | 6 × 1 | 0.1 s | 31.43 | 90.51 |

Damage factor `1 + .20 × level`, rate factor `1 + .15 × level`, cap four
levels each: maximum power is 2.88×. Values assume perfect physical hits.
For illustrative 60% accuracy, effective DPS is 0.6 times the table. Fan
sums three directions; a small single target generally catches only one.
Heavy penetrates three unique targets. Twin offsets are ±0.5 m. Laser burst
is 60 DPS, followed by forced cooling; switching preserves heat.

Base log hits to kill 24/55/120 HP: 2/5/10 hits (0.4/1.6/3.6 s after first
impact, plus travel). Boss HP 600, collision deadline ~25 s. Theoretical
perfect base log boss damage time ~20 s, maximum logs ~6.94 s; misses,
survivors and projectile travel extend actual fights.

## Full-scene simulations

Nine strategies × three seeds (11/42/91). Actual game/projectiles/economy,
no granted money or HP, automated steering only. This is not a human win rate.
Bad-math chooses incorrect answers; losses wanders and misses pickups.

| Strategy | Wins / 3 | Winning boss phase range | Final cash range |
|---|---:|---:|---:|
| base | 2 | 19.8–20.2 s | $1097 to $1354 |
| damage | 2 | 8.9–9.3 s | $808 to $845 |
| rate | 1 | 8.3–8.3 s | $733 to $893 |
| fan | 3 | 11.0–11.3 s | $597 to $698 |
| heavy | 3 | 6.5–6.6 s | $661 to $714 |
| twin | 3 | 7.1–7.7 s | $651 to $726 |
| laser | 3 | 8.4–8.4 s | $448 to $670 |
| bad_math | 3 | 9.5–11.3 s | $-3 to $124 |
| losses | 3 | 10.3–10.5 s | $47 to $60 |

Collected kill cash: $134–$1033;
potential dropped cash: $670–$1300;
breach costs: $0–$206.
Extra time and higher rewards make this version intentionally more generous.
These bot strategies optimize one configuration; they do not prove a player
can or cannot buy the whole shop. Phone play remains necessary for final tuning.

[Raw data](simulation-results.json). Regenerate: `./tools/check.sh` then
`python3 tools/report_balance.py`.
