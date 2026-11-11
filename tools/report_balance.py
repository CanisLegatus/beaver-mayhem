#!/usr/bin/env python3
"""Generate analytic metrics and bot outcomes from actual runtime data."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
c = json.loads((root/'config/balance.json').read_text())
r = json.loads((root/'builds/simulations.json').read_text())
lines = ['# Balance — 0.2.0', '', 'Runtime source: `config/balance.json`. All ten chapters currently use this same',
         'ruleset; only campaign unlock/selection persists. Cash and upgrades reset each run.', '',
         '## Tempo and economy', '',
         f"Run: {c['run_seconds']:g} seconds before the boss. Forward speed ramps from {c['run_speed']:g}",
         f"to {c['max_run_speed']:g} m/s; lateral speed is {c['strafe_speed']:g} m/s (one lane in 0.25 s).",
         'Integrated road distance to boss: 1875 m. Enemy spawn distance: 115 m, hidden',
         'in horizon haze rather than born near the camera. Gate approach distance is',
         'computed by integrating the next seven seconds of speed, growing 70.8–105 m.', '',
         '| Enemy | HP | Reward | Breach penalty | Attack interval |',
         '|---|---:|---:|---:|---:|']
for e in c['enemies']:
    lines.append(f"| {e['name']} | {e['hp']:g} | ${e['reward']} | ${e['penalty']} | {e['attack']:g} s |")
lines += ['', 'The elite primes its first rocket at 0.12 s after spawning, including at the',
          'horizon. Later attacks repeat every 3.2 s; guidance remains limited and locks',
          'after 1.65 s. Rockets have twelve seconds of life to cover the longer approach.', '',
          f"Start cash ${c['starting_money']}; weapon configurations total $575.",
          f"Damage costs {c['damage_costs']} (${sum(c['damage_costs'])} total);",
          f"rate costs {c['rate_costs']} (${sum(c['rate_costs'])} total). Full arsenal and",
          'upgrades cost $1645. Eight gate groups spawn at 14/31/49/67/85/103/121/139 s.',
          'Answering all correctly awards $540. Breaches are deliberately more forgiving',
          'than v0.1; physical pickup and meaningful debt/seizure rules remain unchanged.', '',
          '## Weapons', '',
          '| Weapon | Damage × count | Interval | Base sustained DPS | Max sustained DPS |',
          '|---|---:|---:|---:|---:|']
for name,w in c['weapons'].items():
    duty=2.2/4.2 if name=='laser' else 1
    dps=w['damage']*w['count']/w['interval']*duty
    lines.append(f"| {name} | {w['damage']:g} × {w['count']} | {w['interval']:g} s | {dps:.2f} | {dps*2.88:.2f} |")
lines += ['', 'Damage factor `1 + .20 × level`, rate factor `1 + .15 × level`, cap four',
          'levels each: maximum power is 2.88×. Values assume perfect physical hits.',
          'For illustrative 60% accuracy, effective DPS is 0.6 times the table. Fan',
          'sums three directions; a small single target generally catches only one.',
          'Heavy penetrates three unique targets. Twin offsets are ±0.5 m. Laser burst',
          'is 60 DPS, followed by forced cooling; switching preserves heat.', '',
          'Base log hits to kill 24/55/120 HP: 2/5/10 hits (0.4/1.6/3.6 s after first',
          'impact, plus travel). Boss HP 600, collision deadline ~25 s. Theoretical',
          'perfect base log boss damage time ~20 s, maximum logs ~6.94 s; misses,',
          'survivors and projectile travel extend actual fights.', '',
          '## Full-scene simulations', '',
          'Nine strategies × three seeds (11/42/91). Actual game/projectiles/economy,',
          'no granted money or HP, automated steering only. This is not a human win rate.',
          'Bad-math chooses incorrect answers; losses wanders and misses pickups.', '',
          '| Strategy | Wins / 3 | Winning boss phase range | Final cash range |',
          '|---|---:|---:|---:|']
for strategy in dict.fromkeys(x['strategy'] for x in r):
    rows=[x for x in r if x['strategy']==strategy]
    wins=[x for x in rows if x['state']=='victory']
    duration=[x['seconds']-c['run_seconds'] for x in wins]
    timing=f'{min(duration):.1f}–{max(duration):.1f} s' if duration else '—'
    lines.append(f"| {strategy} | {len(wins)} | {timing} | ${min(x['money'] for x in rows)} to ${max(x['money'] for x in rows)} |")
lines += ['', f"Collected kill cash: ${min(x['collected'] for x in r)}–${max(x['collected'] for x in r)};",
          f"potential dropped cash: ${min(x['kill_rewards'] for x in r)}–${max(x['kill_rewards'] for x in r)};",
          f"breach costs: ${min(x['breach_cost'] for x in r)}–${max(x['breach_cost'] for x in r)}.",
          'Extra time and higher rewards make this version intentionally more generous.',
          'These bot strategies optimize one configuration; they do not prove a player',
          'can or cannot buy the whole shop. Phone play remains necessary for final tuning.', '',
          '[Raw data](simulation-results.json). Regenerate: `./tools/check.sh` then',
          '`python3 tools/report_balance.py`.', '']
(root/'docs/BALANCE.md').write_text('\n'.join(lines))
(root/'docs/simulation-results.json').write_text(json.dumps(r,indent=2)+'\n')
