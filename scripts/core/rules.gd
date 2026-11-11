class_name Rules
extends RefCounted
## Pure, shared rules. Runtime and tests use the same configuration.
static var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/balance.json"))

static func weapon_stats(weapon: String, damage_level: int, rate_level: int) -> Dictionary:
	var stats: Dictionary = config.weapons[weapon].duplicate()
	stats.damage *= 1.0 + 0.20 * clampi(damage_level, 0, 4)
	stats.interval /= 1.0 + 0.15 * clampi(rate_level, 0, 4)
	return stats

static func upgrade_cost(kind: String, level: int) -> int:
	if level >= int(config.max_upgrade):
		return -1
	return int(config[kind + "_costs"][level])

static func threat_budget(seconds: float) -> float:
	return 4.0 + minf(seconds / 90.0, 1.0) * 12.0

static func spawn_interval(seconds: float) -> float:
	return lerpf(2.4, 1.35, clampf(seconds / 90.0, 0.0, 1.0))

static func move_x(current: float, target: float, delta: float) -> float:
	return move_toward(current, clampf(target, -config.road_limit, config.road_limit), config.strafe_speed * delta)

static func segment_hits(a: Vector2, b: Vector2, center: Vector2, radius: float) -> bool:
	var offset := b - a
	var t := clampf((center - a).dot(offset) / maxf(offset.length_squared(), 0.000001), 0.0, 1.0)
	return (a + offset * t).distance_squared_to(center) <= radius * radius

static func rocket_velocity(velocity: Vector2, target_offset: Vector2, age: float, delta: float) -> Vector2:
	if age < float(config.rocket_ignite) or age > float(config.rocket_lock):
		return velocity
	var angle := velocity.angle()
	var difference := wrapf(target_offset.angle() - angle, -PI, PI)
	angle += clampf(difference, -float(config.rocket_turn) * delta, float(config.rocket_turn) * delta)
	return Vector2.from_angle(angle) * minf(18.0, velocity.length() + delta * 22.0)

static func math_problem(seconds: float, rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(3, 15)
	var b := rng.randi_range(2, 9)
	var operation := rng.randi_range(0, 1) if seconds < 30 else rng.randi_range(2, 3)
	var answer: int
	var expression: String
	match operation:
		0:
			answer = a + b
			expression = "%d + %d" % [a, b]
		1:
			answer = a - b
			expression = "%d − %d" % [a, b]
		2:
			answer = a * b
			expression = "%d × %d" % [a, b]
		_:
			a *= b
			answer = a / b
			expression = "%d ÷ %d" % [a, b]
	if seconds >= 60:
		var c := rng.randi_range(2, 9)
		answer += c
		expression += " + %d" % c
	var gap := rng.randi_range(1, 4)
	var choices: Array = [answer - gap, answer, answer + gap]
	for i in range(2, 0, -1):
		var j := rng.randi_range(0, i)
		var temp: int = choices[i]
		choices[i] = choices[j]
		choices[j] = temp
	return {"expression": expression + " = ?", "answer": answer, "choices": choices,
		"reward": 30 if seconds < 30 else (55 if seconds < 60 else 80),
		"penalty": 20 if seconds < 30 else (35 if seconds < 60 else 55)}

static func gate_result(problem: Dictionary, x: float) -> int:
	var lane := roundi(x / float(config.lane_width))
	if absi(lane) > 1 or absf(x - lane * float(config.lane_width)) > 0.8:
		return 0
	return int(problem.reward) if int(problem.choices[lane + 1]) == int(problem.answer) else -int(problem.penalty)
