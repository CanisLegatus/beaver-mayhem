#!/usr/bin/env python3
"""Structural checks in addition to apksigner and zipalign (not device testing)."""
import re
import sys
import zipfile
from pathlib import Path
apk, manifest = map(Path, sys.argv[1:])
text = manifest.read_text()
authorities = re.findall(r'android:authorities[^=]*="([^"]+)"', text)
assert len(authorities) == 2 and len(set(authorities)) == 2, authorities
assert 'org.canislegatus.beavermayhem.fileprovider' in authorities
assert 'org.canislegatus.beavermayhem.androidx-startup' in authorities
assert 'com.godot.game.GodotAppLauncher' in text
assert 'android.intent.action.MAIN' in text and 'android.intent.category.LAUNCHER' in text
assert 'android.permission.INTERNET' not in text
with zipfile.ZipFile(apk) as z:
    names = z.namelist()
    assert 'lib/arm64-v8a/libgodot_android.so' in names
    assert not any('armeabi-v7a/' in n or 'x86/' in n or 'x86_64/' in n for n in names)
    assert any(n.startswith('assets/') and ('main.gd' in n or n.endswith('.pck')) for n in names)
    assert not any(n.endswith(('.keystore', '.jks')) for n in names)
    credits = z.read('assets/assets/licenses/CREDITS.txt').decode('utf-8')
    assert 'Kevin MacLeod' in credits and 'Attribution 4.0' in credits
    for asset in ['hitman.ogg', 'descent.ogg', 'volatile.ogg', 'moon.jpg']:
        assert any(asset in name for name in names), asset

print('APK structure PASS: unique providers, launcher, offline, ARM64, packaged game, no signing keys.')
