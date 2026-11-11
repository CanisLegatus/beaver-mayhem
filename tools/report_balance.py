#!/usr/bin/env python3
"""Document actual configuration and separately grouped chapter simulation results."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
c=json.loads((root/'config/balance.json').read_text())
r=json.loads((root/'builds/simulations.json').read_text())
lines=['# Balance — 0.3.0','','Source: config/balance.json. See LEVELS.md for attack windows/weather/QTE rules.','',
'## Tempo and enemy pressure','',
'Run before boss: 150 seconds; speed 10 → 15 m/s; lateral 8 m/s. The road covers',
'1875 m before the finale. Human spawn intervals 1.35 → 0.65 s, active threat 8 → 25,',
'up to 32 humans. Chapter two spawns packs of 5–8, capped at 64 regular zombies.',
'Zombie advance is road speed × 0.65 plus variant speed, slower than the human march.','',
'| Human | HP | Shot damage | Reward | Breach |','|---|---:|---:|---:|---:|']
for e in c['enemies']:lines.append(f"| {e['name']} | {e['hp']:g} | {e['damage']:g} | ${e['reward']} | ${e['penalty']} |")
lines+=['','| Zombie | HP | Speed offset | Contact/spit damage | Reward / breach |','|---|---:|---:|---:|---:|']
for e in c['zombies']:lines.append(f"| {e['name']} | {e['hp']:g} | {e['speed']:g} | {e['damage']:g} | ${e['reward']} / ${e['penalty']} |")
lines+=['','More actors and faster missiles are compensated by lower ordinary per-hit damage.',
'Elites prime at 0.12 s, repeat 3.2 s; engine ignition at 0.22 s, guidance ends at',
'1.65 s, turn capped 2.8 rad/s, acceleration 54 m/s² to 34 m/s. Firing direction',
'locks afterward. Telegraphs, finite turns and reserved horde gaps allow avoidance.','',
'## Progression and weapons','',
'Start $40; configurations total $575; damage levels cost $550 total, rate $520.',
'Whole shop totals $1645. Eight correct gates award $540; missed coins do not credit.',
'Increased spawn density raises potential income and breach exposure. Negative cash',
'remains playable and can confiscate assets every ten seconds.','',
'| Weapon | Damage × count | Interval | Base sustained DPS | Max sustained DPS |','|---|---:|---:|---:|---:|']
for name,w in c['weapons'].items():
 dps=w['damage']*w['count']/w['interval']*(2.2/4.2 if name=='laser' else 1)
 lines.append(f"| {name} | {w['damage']:g} × {w['count']} | {w['interval']:g} s | {dps:.2f} | {dps*2.88:.2f} |")
lines+=['','Four capped levels each multiply damage by up to 1.8 and rate by 1.6: 2.88× maximum.',
'Fan sums three rays, so distant single targets often take one. Heavy pierces three',
'unique targets. Twin offsets ±0.5 m. Laser burst DPS 60, with heat/cooling duty.',
'At illustrative 60% accuracy multiply sustained DPS by 0.6. HP 24/55/120 require',
'2/5/10 base log hits; 18-HP shamblers require two, maximum damage logs one.','',
'## Bosses','',
'Dozer: 1500 HP, scale 0.67, no passive advance. Missile fans, warned ram (30 HP once)',
'and lane dirt throws (18 HP). Titan: 2100 HP, throws/slams and QTE failure (28 HP once).',
'Physical DPS is still required to win. Ideal base-log firing time is 50/70 seconds;',
'maximum ideal logs 17.4/24.3 seconds. Attacks, movement and travel extend this.',
'QTE/cinematic time freezes all combat and does not deal free boss damage.','',
'## Full-scene probes','',
'33 attempts: nine strategies × three seeds in chapter one, fan/heavy × three in',
'chapter two. All gameplay RNG sources are seeded. The bot uses a simple projectile',
'predictor, lane warnings, contact avoidance and QTE response. It receives no free',
'HP/cash. These are development probes, not human win rates or proof of final tuning.','',
'| Chapter | Strategy | Wins / attempts | Winning boss combat range | Final cash range |','|---|---|---:|---:|---:|']
for chapter,strategy in dict.fromkeys((x.get('chapter',1),x['strategy']) for x in r):
 rows=[x for x in r if x.get('chapter',1)==chapter and x['strategy']==strategy]
 wins=[x for x in rows if x['state']=='victory']; d=[x['seconds']-150 for x in wins]
 span=f'{min(d):.1f}–{max(d):.1f} s' if d else '—'
 lines.append(f"| {chapter} | {strategy} | {len(wins)} / {len(rows)} | {span} | ${min(x['money'] for x in rows)} to ${max(x['money'] for x in rows)} |")
lines+=['','QTE movies do not advance the reported combat clock. Separate boss-fight fixtures',
'pre-fund a heavy build explicitly to validate whole attack loops and physical victory;',
'they are not counted as earned-loadout runs. Both bosses were defeated in those fixtures.',
'Chapter two remains demanding. Phone/human playtesting is needed before claiming',
'production difficulty or accessibility across skill levels.','',
'[Raw outcomes](simulation-results.json). Regenerate with tools/check.sh and',
'python3 tools/report_balance.py.','']
(root/'docs/BALANCE.md').write_text('\n'.join(lines))
(root/'docs/simulation-results.json').write_text(json.dumps(r,indent=2)+'\n')
