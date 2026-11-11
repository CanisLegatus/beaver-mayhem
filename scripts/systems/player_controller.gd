class_name PlayerController
extends RefCounted
var x := 0.0
var target_x := 0.0
var distance := 0.0
var pointer_id := -1
var mouse_down := false

func reset() -> void:
	x = 0.0
	target_x = 0.0
	distance = 0.0
	pointer_id = -1
	mouse_down = false

func tick(delta: float, keyboard: float = 0.0) -> void:
	if keyboard != 0.0:
		target_x = clampf(target_x + keyboard * 6.0 * delta, -Rules.config.road_limit, Rules.config.road_limit)
	x = Rules.move_x(x, target_x, delta)
	distance += float(Rules.config.run_speed) * delta

func input(event: InputEvent, viewport_size: Vector2) -> void:
	# Touch emits synthetic mouse events for UI; do not apply its motion twice.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION: return
	if event is InputEventScreenTouch:
		if event.pressed and pointer_id == -1:
			pointer_id = event.index
		elif event.index == pointer_id:
			pointer_id = -1
	if event is InputEventScreenDrag and event.index == pointer_id:
		target_x += event.relative.x / viewport_size.x * 12.0
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_down = event.pressed
	if event is InputEventMouseMotion and mouse_down:
		target_x += event.relative.x / viewport_size.x * 12.0
	target_x = clampf(target_x, -Rules.config.road_limit, Rules.config.road_limit)
