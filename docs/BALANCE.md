# Balance — 0.1.0

All source numbers come from `config/balance.json`. Analytic DPS assumes perfect
alignment and accuracy; simulations below use actual actors/projectiles and a bot.

## Weapons and bounded progression

| Weapon | Damage × count | Interval | Base DPS (sustained) | Max sustained DPS |
|---|---:|---:|---:|---:|
| log | 12 × 1 | 0.4 s | 30.00 | 86.40 |
| fan | 6.5 × 3 | 0.48 s | 40.62 | 117.00 |
| heavy | 31 × 1 | 0.85 s | 36.47 | 105.04 |
| twin | 7.5 × 2 | 0.42 s | 35.71 | 102.86 |
| laser | 6 × 1 | 0.1 s | 31.43 | 90.51 |

Damage scales as `1 + 0.20 × level`; rate as `1 + 0.15 × level`.
Four levels each give **2.88×** maximum DPS, without exponential stacking.
Fan DPS sums all three directions; a small distant target usually intersects only
one log (13.54 base DPS). Twin streams trade reduced per-projectile damage for
coverage; a target can sit between streams. Heavy can hit three targets, but
never hits one target repeatedly with the same shot. Laser burst DPS is 60,
then ~2.2 s firing / ~2 s cooling; switching does not reset heat.

An illustrative 60% hit rate gives `0.6 × sustained DPS`, before target
penetration or fan coverage. Against 24/55/120 HP, base logs need 2/5/10
hits: 0.4/1.6/3.6 s from the first impact, plus projectile travel. Base ideal
boss fire takes ~20 s; maximum logs ~6.94 s. Actual player positioning,
enemy survivors, travel time, heat and wasted shots extend those estimates.

## Economy and difficulty

Start cash: $40. All weapon configurations cost $575 together.
Damage levels: [65, 100, 155, 230], total $550.
Rate levels: [60, 95, 145, 220], total $520.
Full arsenal plus all levels costs **$1645**.
Six correct gates award $330. No income is added for a missed coin. A ten-second
continuous debt period seizes one eligible asset, without extra cash penalties.
The protected base weapon and later math rewards allow recovery; negative cash
does not directly cause game over. The bot can still win while in debt.

Threat budget increases linearly 4 → 16 over 90 s, with costs 1/3/7. Spawning
interval decreases 2.4 → 1.35 s; enemy HP stays fixed. Gate windows soften
attacks and spawning. Boss HP is 600 and collision deadline ~25 s.

## Deterministic full-scene simulations

Three seeds (11, 42, 91), nine purchase/input strategies, 27 complete attempts.
The bot tracks nearby enemies/loot, reserves answer lanes shortly before gates,
and makes simple local projectile dodges. No HP, money or damage cheats are used.
The losses strategy intentionally wanders; bad_math chooses incorrect answers.
These are development probes, **not human win rates**. Strategies can diverge
after small frame-order/input changes, so compare the checked-in raw results.

| Strategy | Wins / 3 | Winning boss phase range | Final cash range |
|---|---:|---:|---:|
| base | 3 | 20.2–22.9 s | $172 to $360 |
| damage | 3 | 10.0–14.7 s | $32 to $116 |
| rate | 3 | 10.1–13.5 s | $39 to $75 |
| fan | 3 | 13.0–15.1 s | $2 to $82 |
| heavy | 3 | 7.5–11.0 s | $60 to $75 |
| twin | 2 | 8.8–11.4 s | $1 to $45 |
| laser | 2 | 13.8–23.1 s | $-37 to $27 |
| bad_math | 2 | 20.2–22.1 s | $-321 to $-267 |
| losses | 3 | 17.1–22.5 s | $-55 to $34 |

Prepared damage/rate/heavy builds generally defeat the boss in about 8–15 s.
Base and poorly funded laser builds face the deadline. Some bot runs lose; full
purchases are unaffordable within observed earnings. Kill rewards are potential
cash until collected; breach losses and misses materially affect purchasing.

Observed collected-kill cash: $67–$402;
kill reward potential: $193–$467;
breach charges: $90–$432.
The $550–700 income target is an early hypothesis, not a guaranteed reward budget:
good math plus successful pickups can exceed it; poor play earns much less.
Future tuning should use real touch play, accuracy and player telemetry recorded
locally with consent, rather than optimizing only for this bot.

[Raw simulation data](simulation-results.json). Regenerate with `./tools/check.sh`
then `python3 tools/report_balance.py`.
