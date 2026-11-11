class_name DodgeQTE
extends RefCounted
signal resolved(success: bool)
var active := false
var expected := 0
var remaining := 0.0
var prop := "tree"
var last_camera := -1
var camera_variant := 0
var rng := RandomNumberGenerator.new()

func begin(direction: int, object_kind: String) -> void:
	expected = clampi(direction,0,2)
	prop = object_kind
	remaining = 1.6
	active = true
	camera_variant = (last_camera+1+rng.randi_range(0,1))%3
	last_camera = camera_variant

func tick(delta: float) -> void:
	if not active: return
	remaining -= delta
	if remaining <= 0: resolve(false)

func press(direction: int) -> bool:
	if not active: return false
	var success := direction == expected
	resolve(success)
	return success

func resolve(success: bool) -> void:
	if not active: return
	active = false
	resolved.emit(success)

func clear() -> void:
	active = false
	remaining = 0
