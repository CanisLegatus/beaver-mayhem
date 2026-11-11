class_name GameAudio
extends Node
## Original synthesized PCM effects, precomputed once, bounded eight-voice playback.
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var cursor := 0
var muted := false

func _ready() -> void:
	var tones := {"shoot":[220.0,90.0,0.07], "hit":[120.0,50.0,0.09],
		"coin":[700.0,1200.0,0.1], "buy":[420.0,900.0,0.18], "correct":[600.0,1300.0,0.3],
		"wrong":[190.0,80.0,0.3], "paper":[800.0,350.0,0.12], "rocket":[90.0,600.0,0.4],
		"explosion":[75.0,20.0,0.5], "victory":[500.0,1400.0,0.7], "loss":[400.0,60.0,0.7],
		"alarm":[600.0,1200.0,0.65]}
	for key in tones:
		var t: Array = tones[key]
		sounds[key] = synth(t[0], t[1], t[2], key in ["explosion", "rocket", "hit"], key == "alarm")
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
	if muted or not sounds.has(key) or voices.is_empty(): return
	var voice := voices[cursor % voices.size()]
	cursor += 1
	voice.stream = sounds[key]
	voice.play()

func toggle() -> void:
	muted = not muted
	for voice in voices: voice.stream_paused = muted

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	sounds.clear()
