# Asset sources — v0.3.0

Downloaded assets use CC0 or CC BY 4.0 and are free to redistribute under those
terms. They are not relicensed under the software MIT license. Required attribution
is included in assets/licenses/CREDITS.txt, shipped in the APK and accessible from
the roadmap i button. No non-commercial-only or paid assets are used.

| Local asset | Creator / work | Source | License / processing |
|---|---|---|---|
| audio/prepare-to-fight.ogg | Basil, Prepare to Fight | https://opengameart.org/content/prepare-to-fight | CC0; original MP3 transcoded to Vorbis, loop enabled in engine |
| audio/explosion.ogg | NenadSimic, Muffled Distant Explosion | https://opengameart.org/content/muffled-distant-explosion | CC0; WAV transcoded to Vorbis |
| audio/wood-hit.ogg, paper.ogg, throw.ogg, coins.ogg, dam.ogg | Kenney, 50 RPG Sound Effects | https://opengameart.org/content/50-rpg-sound-effects | CC0; selected chop/bookFlip1/cloth1/handleCoins/creak1 recordings |
| audio/click.wav | Kenney, UI Audio | https://github.com/Calinou/kenney-ui-audio | CC0; click1.wav, mirror of Kenney's pack |
| vfx/smoke_01.png, spark_01.png, star_01.png | Kenney, Particle Pack | https://opengameart.org/content/particle-pack-80-sprites | CC0; selected unmodified textures |

Upstream pack license notices are preserved in assets/licenses/. Source pages for
the Basil and NenadSimic tracks explicitly mark them CC0; source/license metadata
is recorded in assets/licenses/audio-sources.json. CC0 legal text:
https://creativecommons.org/publicdomain/zero/1.0/

## Generated app icon
`assets/images/beaver-icon.png` was generated with the built-in imagegen tool.
Final prompt: a premium photorealistic square Android icon showing a real North
American beaver in a heroic three-quarter portrait, looking proudly to the upper
right, detailed wet brown fur, orange incisors, sunrise rim light, misty forest and
river background, no text, clothing, weapons, borders, cartoon or illustration.
The [exact prompt/tool record](ICON_PROMPT.md) is preserved. The generation used no reference image. The original generated PNG is copied into
the project; project/icon and Android launcher icon refer to this file.

## Original 3D content
Characters use original smooth ring-sculpted ArrayMesh geometry with anatomical
profiles, clothing details and procedural fur/cloth shading. They are three-dimensional
semi-realistic game models, not photographs or scanned human assets. Vegetation,
road, dam and bulldozer are original procedural geometry. No external character
likeness assets are downloaded. Level preview is captured from the game renderer.

## v0.3 additions
| Asset | Creator / source | License / processing |
|---|---|---|
| hitman.ogg, descent.ogg, volatile.ogg | Kevin MacLeod / https://incompetech.com/music/royalty-free/ | CC BY 4.0; original catalog metadata saved in music-catalog.json; normalized toward -18 LUFS/-2 dBTP, Vorbis transcoding, loop/volume mixing |
| voice-*.ogg | Kenney / https://opengameart.org/content/voiceover-pack-40-lines | CC0; selected recorded male warning, ready, go, final-round and mission-result lines |
| rocket-engine.ogg, energy.ogg | Kenney Sci-Fi Sounds / https://kenney.nl/assets/sci-fi-sounds | CC0; spaceEngineLarge_001 and forceField_000, retrieved through Mcamento8/open-game-sfx-index mirror |
| zombie.ogg | artisticdude / https://opengameart.org/content/zombies-sound-pack | CC0; zombie-1 WAV transcoded to Vorbis, same verified mirror |
| rain.ogg | Ylmir / https://opengameart.org/content/rain-loopable | CC0; first OGG from original pack, looped |
| storm-ambience.ogg, thunder.ogg | kindland / https://opengameart.org/node/22231 | CC0; original ambience loop plus a faded 4.2-second thunder excerpt at 256.8 s |
| asphalt-*.jpg | ambientCG / https://ambientcg.com/view?id=Asphalt002 | CC0; original 1K JPG color/NormalGL/roughness maps |
| ground-*.jpg | ambientCG / https://ambientcg.com/view?id=Ground037 | CC0; original 1K JPG color/NormalGL maps |
| moon.jpg | Solar System Scope / INOVE / https://www.solarsystemscope.com/textures/ | CC BY 4.0; original 2K Moon map applied to sphere |

Kevin MacLeod official catalog identifies Volatile Reaction (155 BPM, ISRC
USUAN1400039), Hitman (76 BPM, USUAN1300013), and The Descent (103 BPM,
USUAN1200094). They were selected as driving action/horror compositions from a
well-known free-music composer; no unsupported popularity ranking is claimed.
Source downloads: incompetech.com/music/royalty-free/mp3-royaltyfree/ followed by
the URL-encoded catalog filename. Current official licensing/credit generator:
https://incompetech.com/music/royalty-free/licenses/

The three music cues are selected for level one, Moonfall and boss fights, rather
than played simultaneously. A dedicated recorded-speech player ducks music; rain
has a separate quiet ambience player. Synthetic short utility cues remain where
appropriate. The named zombie/human/vehicle/house meshes are original procedural
3D work; no paid character likeness models were imported.
