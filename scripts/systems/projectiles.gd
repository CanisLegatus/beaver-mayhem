class_name ProjectileSystem
extends Node3D
signal player_hit(damage: float)
signal impact(pos: Vector3, color: Color)
signal rocket_ignited(pos: Vector3)
signal rocket_exploded(pos: Vector3)
var shots: Array[Dictionary] = []
var targets: Array[Dictionary] = []

func spawn(kind: String, pos: Vector3, velocity: Vector2, damage: float, friendly: bool, pierce: int = 1) -> Dictionary:
	if shots.size() >= int(Rules.config.projectile_cap): return {}
	var visual := Art.projectile(kind)
	add_child(visual)
	visual.position = pos
	var shot := {"kind": kind, "pos": Vector2(pos.x, pos.z), "velocity": velocity,
		"damage": damage, "friendly": friendly, "left": pierce, "age": 0.0,
		"visual": visual, "hit_ids": [], "ignited": false}
	shots.append(shot)
	return shot

func tick(delta: float, player_x: float) -> void:
	for shot in shots.duplicate():
		shot.age += delta
		var previous: Vector2 = shot.pos
		if shot.kind == "rocket":
			shot.velocity = Rules.rocket_velocity(shot.velocity, Vector2(player_x, 0) - shot.pos, shot.age, delta)
			if shot.age >= float(Rules.config.rocket_ignite) and not shot.ignited:
				shot.ignited = true
				shot.visual.get_node("Flame").visible = true
				rocket_ignited.emit(shot.visual.position)
		shot.pos += shot.velocity * delta
		var visual: Node3D = shot.visual
		visual.position = Vector3(shot.pos.x, 1.0, shot.pos.y)
		if shot.kind == "rocket":
			visual.rotation.y = atan2(-shot.velocity.x, -shot.velocity.y)
		else:
			visual.rotation.z += delta * 8
		var removed := false
		if shot.friendly:
			# Swept segment prevents tunnelling even for fast laser bolts.
			# Targets sorted front to back so ordinary shots hit nearest intersection.
			var ordered := targets.duplicate()
			ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pos.y > b.pos.y)
			for enemy in ordered:
				if enemy.health.dead or enemy.id in shot.hit_ids: continue
				if Rules.segment_hits(previous, shot.pos, enemy.pos, enemy.radius + 0.13):
					enemy.health.hit(shot.damage)
					shot.hit_ids.append(enemy.id)
					shot.left -= 1
					impact.emit(visual.position, Art.GOLD)
					enemy.flash = 0.13
					if shot.left <= 0:
						remove(shot)
						removed = true
						break
		elif Rules.segment_hits(previous, shot.pos, Vector2(player_x, 0), 0.5):
			player_hit.emit(shot.damage)
			impact.emit(visual.position, Color("f87959"))
			remove(shot)
			removed = true
		if not removed and (shot.age > float(Rules.config.rocket_lifetime) or absf(shot.pos.x) > 16 or shot.pos.y < -80 or shot.pos.y > 12):
			remove(shot)

func remove(shot: Dictionary) -> void:
	if shot.kind == "rocket" and shot.ignited:
		rocket_exploded.emit(shot.visual.position)
	shots.erase(shot)
	shot.visual.queue_free()

func clear() -> void:
	for shot in shots.duplicate(): remove(shot)

func rocket_trails(effects: Effects, delta: float) -> void:
	for shot in shots:
		if shot.kind == "rocket" and shot.ignited:
			shot.trail_clock = shot.get("trail_clock", 0.0) + delta
			if shot.trail_clock >= 0.08:
				shot.trail_clock = 0.0
				effects.burst(shot.visual.position, Art.GOLD, 1)
