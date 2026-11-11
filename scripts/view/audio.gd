class_name GameAudio
extends Node
## Original synthesized PCM effects, precomputed once, bounded eight-voice playback.
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var cursor := 0
var muted := false
var music: AudioStreamPlayer
var speech: AudioStreamPlayer
var ambience: AudioStreamPlayer
var music_name := ""
var speech_time := -10000
var mood := "menu"
var last_play: Dictionary = {}

func _ready() -> void:
	var tones := {"shoot":[220.0,90.0,0.07], "hit":[120.0,50.0,0.09],
		"coin":[700.0,1200.0,0.1], "buy":[420.0,900.0,0.18], "correct":[600.0,1300.0,0.3],"thunder":[70.0,25.0,1.0],"truck":[120.0,75.0,0.6],"impact":[65.0,25.0,0.4],"moon_impact":[55.0,20.0,1.0],"dodge":[250.0,600.0,0.2],
		"wrong":[190.0,80.0,0.3], "paper":[800.0,350.0,0.12], "rocket":[90.0,600.0,0.4],
		"explosion":[75.0,20.0,0.5], "victory":[500.0,1400.0,0.7], "loss":[400.0,60.0,0.7],
		"alarm":[600.0,1200.0,0.65]}
	for key in tones:
		var t: Array = tones[key]
		sounds[key] = synth(t[0], t[1], t[2], key in ["explosion", "rocket", "hit"], key == "alarm")
	for pair in [["shoot","throw.ogg"],["hit","wood-hit.ogg"],["paper","paper.ogg"],["buy","click.wav"],["explosion","explosion.ogg"],["coin","coins.ogg"],["dam","dam.ogg"],["rocket","rocket-engine.ogg"],["zombie","zombie.ogg"],["impact","explosion.ogg"],["moon_impact","explosion.ogg"],["dodge","throw.ogg"],["thunder","thunder.ogg"],["truck","energy.ogg"]]:
		sounds[pair[0]] = load("res://assets/audio/"+pair[1])
	music = AudioStreamPlayer.new()
	add_child(music)
	var score: AudioStreamOggVorbis = load("res://assets/audio/prepare-to-fight.ogg")
	score.loop = true
	music.stream = score
	music.volume_db = -16
	if DisplayServer.get_name() != "headless": music.play()
	ambience = AudioStreamPlayer.new()
	add_child(ambience)
	speech = AudioStreamPlayer.new()
	speech.volume_db = -1
	add_child(speech)
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func synth(start: float, finish: float, duration: float, noise: bool, alarm: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	var rate := 22050
	bytes.resize(int(duration * rate) * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(bytes.size() / 2):
		var t := float(i) / rate
		var frequency := lerpf(start, finish, t / duration)
		if alarm: frequency = start if fmod(t, 0.16) < 0.08 else finish
		phase += TAU * frequency / rate
		var value := sin(phase) * 0.65 + (rng.randf_range(-0.35, 0.35) if noise else sin(phase * 2) * 0.15)
		var envelope := minf(t * 120, 1) * pow(1.0 - t / duration, 1.6)
		bytes.encode_s16(i * 2, int(value * envelope * 10000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream

func play(key: String) -> void:
	# Rule/soak tests load real assets but do not start asynchronous audio decoders.
	if DisplayServer.get_name() == "headless": return
	if key in ["warning","ready","go","qte","victory","loss","boss"] and not muted:
		var now := Time.get_ticks_msec()
		if now-speech_time > 1400:
			speech_time = now
			speech.stream = load("res://assets/audio/voice-"+key+".ogg")
			speech.play()
	if muted or not sounds.has(key) or voices.is_empty(): return
	var now := Time.get_ticks_msec()
	if now - int(last_play.get(key,-10000)) < (70 if key in ["hit","shoot"] else 30): return
	last_play[key] = now
	var voice := voices[cursor % voices.size()]
	cursor += 1
	voice.stream = sounds[key]
	voice.play()

func toggle() -> void:
	muted = not muted
	for voice in voices: voice.stream_paused = muted
	if music != null: music.stream_paused = muted
	if speech != null: speech.stream_paused = muted
	if ambience != null: ambience.stream_paused = muted

func _exit_tree() -> void:
	if ambience != null:
		ambience.stop()
		ambience.stream = null
	if speech != null:
		speech.stop()
		speech.stream = null
	if music != null:
		music.stop()
		music.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null
	sounds.clear()

func set_mood(state: String) -> void:
	if music == null: return
	mood = state
	music.volume_db = -9 if state == "playing" else (-6 if state == "cinematic" else -18)
	music.stream_paused = muted
	if ambience != null: ambience.stream_paused = muted or state == "paused"

func choose_music(name: String) -> void:
	if music_name == name: return
	music_name = name
	var stream: AudioStreamOggVorbis = load("res://assets/audio/"+name+".ogg")
	stream.loop = true
	music.stream = stream
	if DisplayServer.get_name() != "headless" and not muted: music.play()

func set_level(level: int) -> void:
	choose_music("descent" if level == 2 else ("hitman" if level%2==1 else "volatile"))
	ambience.stop()
	var weather: String = LevelProfile.for_level(level).weather
	if weather in ["rain","storm"]:
		var stream: AudioStreamOggVorbis = load("res://assets/audio/storm-ambience.ogg" if weather == "storm" else "res://assets/audio/rain.ogg")
		stream.loop = true
		ambience.stream = stream
		ambience.volume_db = -20
		if DisplayServer.get_name() != "headless" and not muted: ambience.play()

func set_boss() -> void:
	choose_music("volatile")
	play("boss")

func _process(delta: float) -> void:
	if music == null: return
	var target := -9.0 if mood in ["playing","qte","dodge_movie"] else (-6.0 if mood=="cinematic" else -18.0)
	if speech != null and speech.playing: target -= 7
	music.volume_db = move_toward(music.volume_db,target,delta*20)

func reset_cues() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	if speech != null:
		speech.stop()
		speech.stream = null
	speech_time = -10000
	last_play.clear()
