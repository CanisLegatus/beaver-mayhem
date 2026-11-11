class_name GateSystem
extends Node3D
signal answered(value: int)
var groups: Array[Dictionary] = []
var schedule_index := 0
var rng := RandomNumberGenerator.new()

func _init() -> void: rng.randomize()

func spawn(seconds: float) -> Dictionary:
	var problem := Rules.math_problem(seconds, rng)
	var root := Node3D.new()
	add_child(root)
	root.position.z = -48.0
	Art.label(root, problem.expression, Vector3(0, 4.2, 0), 68, Art.GOLD)
	for lane in range(-1, 2):
		var x := lane * 2.0
		for side in [-1,1]:
			Art.cylinder(root, Vector3(x + side * 0.8, 1.25, 0), 0.06, 2.5, Art.MINT)
		Art.box(root, Vector3(x, 2.55, 0), Vector3(1.7, 0.12, 0.15), Art.MINT)
		Art.label(root, str(problem.choices[lane + 1]), Vector3(x, 2.0, 0), 58, Color.WHITE)
		Art.box(root, Vector3(x, 0.035, 0), Vector3(1.5, 0.04, 1.3), Color("4c9b84"))
	var group := {"visual": root, "z": -48.0, "problem": problem, "used": false}
	groups.append(group)
	return group

func tick(delta: float, seconds: float, player_x: float) -> void:
	if schedule_index < Rules.config.gate_times.size() and seconds >= float(Rules.config.gate_times[schedule_index]):
		spawn(seconds)
		schedule_index += 1
	for group in groups.duplicate():
		group.z += float(Rules.config.run_speed) * delta
		group.visual.position.z = group.z
		if group.z >= 0 and not group.used:
			group.used = true
			var value := Rules.gate_result(group.problem, player_x)
			if value != 0: answered.emit(value)
		if group.z > 7:
			groups.erase(group)
			group.visual.queue_free()

func near_player() -> bool:
	for group in groups:
		if group.z > -20 and group.z < 3: return true
	return false

func clear() -> void:
	for group in groups: group.visual.queue_free()
	groups.clear()
	schedule_index = 0
