#!/usr/bin/env python3
"""Generate documented analytic metrics from the runtime configuration and results."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
c = json.loads((root/'config/balance.json').read_text())
r = json.loads((root/'builds/simulations.json').read_text())
lines = ['# Balance — 0.1.0', '', 'All source numbers come from `config/balance.json`. Analytic DPS assumes perfect',
         'alignment and accuracy; simulations below use actual actors/projectiles and a bot.', '',
         '## Weapons and bounded progression', '',
         '| Weapon | Damage × count | Interval | Base DPS (sustained) | Max sustained DPS |',
         '|---|---:|---:|---:|---:|']
for name, w in c['weapons'].items():
    duty = 2.2/4.2 if name == 'laser' else 1
    dps = w['damage']*w['count']/w['interval']*duty
    lines.append(f"| {name} | {w['damage']:g} × {w['count']} | {w['interval']:g} s | {dps:.2f} | {dps*2.88:.2f} |")
lines += ['', 'Damage scales as `1 + 0.20 × level`; rate as `1 + 0.15 × level`.',
          'Four levels each give **2.88×** maximum DPS, without exponential stacking.',
          'Fan DPS sums all three directions; a small distant target usually intersects only',
          'one log (13.54 base DPS). Twin streams trade reduced per-projectile damage for',
          'coverage; a target can sit between streams. Heavy can hit three targets, but',
          'never hits one target repeatedly with the same shot. Laser burst DPS is 60,',
          'then ~2.2 s firing / ~2 s cooling; switching does not reset heat.', '',
          'An illustrative 60% hit rate gives `0.6 × sustained DPS`, before target',
          'penetration or fan coverage. Against 24/55/120 HP, base logs need 2/5/10',
          'hits: 0.4/1.6/3.6 s from the first impact, plus projectile travel. Base ideal',
          'boss fire takes ~20 s; maximum logs ~6.94 s. Actual player positioning,',
          'enemy survivors, travel time, heat and wasted shots extend those estimates.', '',
          '## Economy and difficulty', '',
          f"Start cash: ${c['starting_money']}. All weapon configurations cost $575 together.",
          f"Damage levels: {c['damage_costs']}, total ${sum(c['damage_costs'])}.",
          f"Rate levels: {c['rate_costs']}, total ${sum(c['rate_costs'])}.",
          f"Full arsenal plus all levels costs **${575+sum(c['damage_costs'])+sum(c['rate_costs'])}**.",
          'Six correct gates award $330. No income is added for a missed coin. A ten-second',
          'continuous debt period seizes one eligible asset, without extra cash penalties.',
          'The protected base weapon and later math rewards allow recovery; negative cash',
          'does not directly cause game over. The bot can still win while in debt.', '',
          'Threat budget increases linearly 4 → 16 over 90 s, with costs 1/3/7. Spawning',
          'interval decreases 2.4 → 1.35 s; enemy HP stays fixed. Gate windows soften',
          'attacks and spawning. Boss HP is 600 and collision deadline ~25 s.', '',
          '## Deterministic full-scene simulations', '',
          'Three seeds (11, 42, 91), nine purchase/input strategies, 27 complete attempts.',
          'The bot tracks nearby enemies/loot, reserves answer lanes shortly before gates,',
          'and makes simple local projectile dodges. No HP, money or damage cheats are used.',
          'The losses strategy intentionally wanders; bad_math chooses incorrect answers.',
          'These are development probes, **not human win rates**. Strategies can diverge',
          'after small frame-order/input changes, so compare the checked-in raw results.', '',
          '| Strategy | Wins / 3 | Winning boss phase range | Final cash range |',
          '|---|---:|---:|---:|']
for strategy in dict.fromkeys(x['strategy'] for x in r):
    rows = [x for x in r if x['strategy'] == strategy]
    wins = [x for x in rows if x['state'] == 'victory']
    durations = [x['seconds']-90 for x in wins]
    duration = f'{min(durations):.1f}–{max(durations):.1f} s' if durations else '—'
    lines.append(f"| {strategy} | {len(wins)} | {duration} | ${min(x['money'] for x in rows)} to ${max(x['money'] for x in rows)} |")
lines += ['', 'Prepared damage/rate/heavy builds generally defeat the boss in about 8–15 s.',
          'Base and poorly funded laser builds face the deadline. Some bot runs lose; full',
          'purchases are unaffordable within observed earnings. Kill rewards are potential',
          'cash until collected; breach losses and misses materially affect purchasing.', '',
          f"Observed collected-kill cash: ${min(x['collected'] for x in r)}–${max(x['collected'] for x in r)};",
          f"kill reward potential: ${min(x['kill_rewards'] for x in r)}–${max(x['kill_rewards'] for x in r)};",
          f"breach charges: ${min(x['breach_cost'] for x in r)}–${max(x['breach_cost'] for x in r)}.",
          'The $550–700 income target is an early hypothesis, not a guaranteed reward budget:',
          'good math plus successful pickups can exceed it; poor play earns much less.',
          'Future tuning should use real touch play, accuracy and player telemetry recorded',
          'locally with consent, rather than optimizing only for this bot.', '',
          '[Raw simulation data](simulation-results.json). Regenerate with `./tools/check.sh`',
          'then `python3 tools/report_balance.py`.', '']
(root/'docs/BALANCE.md').write_text('\n'.join(lines))
(root/'docs/simulation-results.json').write_text(json.dumps(r, indent=2)+'\n')
