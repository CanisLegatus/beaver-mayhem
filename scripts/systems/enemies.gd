class_name EnemySystem
extends Node3D
signal killed(pos: Vector2, reward: int)
signal breached(penalty: int)
signal attack(kind: int, pos: Vector3, velocity: Vector2, damage: float)
signal boss_destroyed
signal boss_collision
var enemies: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var spawn_timer := 0.4
var next_id := 0
var boss: Dictionary = {}

func _init() -> void:
	rng.randomize()

func spawn(kind: int, x: float, z: float = -115.0) -> Dictionary:
	var stats: Dictionary = Rules.config.enemies[kind]
	var visual := Art.enemy(kind)
	add_child(visual)
	visual.position = Vector3(x, 0, z)
	next_id += 1
	var enemy := {"id": next_id, "kind": kind, "pos": Vector2(x,z), "health": Health.new(stats.hp),
		"radius": 0.48, "visual": visual, "attack_timer": 0.12 if kind == 2 else rng.randf_range(1.2, 2.8),
		"warning": false, "flash": 0.0, "boss": false, "rewarded": false}
	enemies.append(enemy)
	return enemy

func spawn_boss() -> void:
	var visual := Art.bulldozer()
	add_child(visual)
	next_id += 1
	boss = {"id": next_id, "kind": 3, "pos": Vector2(0, -Rules.config.boss_start_distance),
		"health": Health.new(Rules.config.boss_hp), "radius": 3.1, "visual": visual,
		"flash": 0.0, "boss": true, "rewarded": false}
	enemies.append(boss)

func director(delta: float, seconds: float, gate_near: bool) -> void:
	spawn_timer -= delta
	if spawn_timer > 0: return
	spawn_timer += Rules.spawn_interval(seconds) * (1.25 if gate_near else 1.0)
	var threat := 0.0
	for enemy in enemies:
		if not enemy.boss:
			threat += float(Rules.config.enemies[enemy.kind].threat)
	var roll := rng.randf()
	var kind := 0
	if seconds >= 35 and roll < 0.10: kind = 2
	elif seconds >= 22 and roll < 0.33: kind = 1
	if threat + float(Rules.config.enemies[kind].threat) > Rules.threat_budget(seconds): kind = 0
	if enemies.size() >= int(Rules.config.enemy_cap) or threat >= Rules.threat_budget(seconds): return
	spawn(kind, rng.randi_range(-2, 2) * float(Rules.config.lane_width), -float(Rules.config.enemy_spawn_distance))

func tick(delta: float, seconds: float, player_x: float, gate_near: bool = false) -> void:
	for enemy in enemies.duplicate():
		if enemy.health.dead:
			if not enemy.rewarded:
				enemy.rewarded = true
				if enemy.boss: boss_destroyed.emit()
				else: killed.emit(enemy.pos, int(Rules.config.enemies[enemy.kind].reward))
			remove(enemy)
			continue
		var visual: Node3D = enemy.visual
		enemy.flash = maxf(0.0, enemy.flash - delta)
		if enemy.boss:
			enemy.pos.y += float(Rules.config.boss_speed) * delta
			visual.position = Vector3(enemy.pos.x, sin(seconds * 7) * 0.06, enemy.pos.y)
			visual.scale = Vector3.ONE * (1.025 if enemy.flash > 0 else 1.0)
			if enemy.pos.y > -4.2: boss_collision.emit()
			continue
		var stats: Dictionary = Rules.config.enemies[enemy.kind]
		enemy.pos.y += (Rules.run_speed(seconds) + float(stats.speed)) * delta
		visual.position = Vector3(enemy.pos.x, absf(sin(seconds * 8 + enemy.id)) * 0.12, enemy.pos.y)
		visual.rotation.z = sin(seconds * 8 + enemy.id) * 0.04
		visual.get_node("FootL").rotation.x = sin(seconds * 8 + enemy.id) * 0.5
		visual.get_node("FootR").rotation.x = -sin(seconds * 8 + enemy.id) * 0.5
		if enemy.pos.y > 3:
			breached.emit(int(stats.penalty))
			remove(enemy)
			continue
		if (enemy.kind == 2 or enemy.pos.y > -45) and enemy.pos.y < -3:
			enemy.attack_timer -= delta * (0.65 if gate_near else 1.0)
			if enemy.attack_timer < 0.65:
				enemy.warning = true
				visual.scale = Vector3.ONE * (1.0 + sin(seconds * 24) * 0.08)
				visual.rotation.x = -0.2
			if enemy.attack_timer <= 0:
				var velocity := Vector2(0, float(stats.projectile_speed))
				if enemy.kind == 1:
					velocity = (Vector2(player_x,0) - enemy.pos).normalized() * float(stats.projectile_speed)
				if enemy.kind == 2: velocity = Vector2(5 if enemy.pos.x < 0 else -5, 0)
				attack.emit(enemy.kind, Vector3(enemy.pos.x, 1.0, enemy.pos.y + 0.6), velocity, stats.damage)
				enemy.attack_timer = stats.attack
				enemy.warning = false
				visual.rotation.x = 0
				visual.scale = Vector3.ONE

func remove(enemy: Dictionary) -> void:
	enemies.erase(enemy)
	enemy.visual.queue_free()

func clear() -> void:
	for enemy in enemies.duplicate(): remove(enemy)
	boss = {}
	spawn_timer = 0.4
	next_id = 0
