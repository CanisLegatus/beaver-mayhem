#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-$HOME/.local/bin/godot}"
mkdir -p builds
"$GODOT_BIN" --headless --editor --import --quit 2>&1 | tee builds/import.log
if rg -q 'SCRIPT ERROR|ERROR:' builds/import.log; then exit 1; fi
"$GODOT_BIN" --headless --script res://tests/run_tests.gd 2>&1 | tee builds/tests.log
if rg -q 'SCRIPT ERROR|ERROR:|FAIL:|leaked' builds/tests.log; then exit 1; fi

"$GODOT_BIN" --headless --script res://tests/v3_tests.gd 2>&1 | tee builds/v3-tests.log
if rg -q 'SCRIPT ERROR|ERROR:|FAIL:|leaked' builds/v3-tests.log; then exit 1; fi

"$GODOT_BIN" --headless --script res://tests/boss_fights.gd 2>&1 | tee builds/boss-fights.log
if rg -q 'SCRIPT ERROR|ERROR:|FAIL:|leaked' builds/boss-fights.log; then exit 1; fi

"$GODOT_BIN" --headless --script res://tests/simulate.gd 2>&1 | tee builds/simulations.log
if rg -q 'SCRIPT ERROR|ERROR:|FAILED|leaked' builds/simulations.log; then exit 1; fi
