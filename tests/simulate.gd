extends SceneTree
## Deterministic bot simulations use the actual scene, shots, health and economy.
## Automated input is not a claim of human playability or Android performance.
var report: Array[Dictionary] = []
var failed := false
func _initialize() -> void: call_deferred("run")

func run() -> void:
	for strategy in ["base", "damage", "rate", "fan", "heavy", "twin", "laser", "bad_math", "losses"]:
		for seed_value in [11, 42, 91]:
			await simulate(strategy, seed_value)
	var file := FileAccess.open("res://builds/simulations.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	Art.materials.clear()
	Art.meshes.clear()
	await create_timer(0.15).timeout
	print("SIMULATIONS: %d runs, runtime invariants %s" % [report.size(), "FAILED" if failed else "PASS"])
	quit(1 if failed else 0)

func simulate(strategy: String, seed_value: int) -> void:
	var game: BeaverGame = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.enemies.rng.seed = seed_value
	game.gates.rng.seed = seed_value + 100
	game.economy.rng.seed = seed_value + 200
	game.start_run()
	game.audio.muted = true
	var peaks := {"enemies":0,"shots":0,"coins":0,"vfx":0}
	var awarded: Array = [0]
	var breached: Array = [0]
	var picked: Array = [0]
	var seized: Array = [0]
	game.enemies.killed.connect(func(_p: Vector2, v: int) -> void: awarded[0] += v)
	game.enemies.breached.connect(func(v: int) -> void: breached[0] += v)
	game.loot.collected.connect(func(v: int, _p: Vector3) -> void: picked[0] += v)
	game.economy.confiscated.connect(func(_i: String) -> void: seized[0] += 1)
	var purchases: Array[String] = []
	var decision_timer := 0.0
	for frame in range(60 * 122):
		if game.state != "playing": break
		decision_timer -= 1.0 / 60
		if decision_timer <= 0:
			decision_timer = 0.12
			choose_position(game, strategy)
			if strategy in ["fan","heavy","twin","laser"] and strategy not in game.economy.owned:
				if game.economy.buy(strategy): purchases.append(strategy)
			elif strategy != "base":
				var kind := "rate" if strategy == "rate" else "damage"
				var level := game.economy.rate_level if kind == "rate" else game.economy.damage_level
				if level >= 2: kind = "damage" if kind == "rate" else "rate"
				var actual_level := game.economy.rate_level if kind == "rate" else game.economy.damage_level
				var cost := Rules.upgrade_cost(kind, actual_level)
				if cost > 0 and game.economy.money >= cost + 35:
					if game.economy.buy(kind): purchases.append(kind)
		game._physics_process(1.0 / 60)
		peaks.enemies = maxi(peaks.enemies,game.enemies.enemies.size())
		peaks.shots = maxi(peaks.shots,game.projectiles.shots.size())
		peaks.coins = maxi(peaks.coins,game.loot.coins.size())
		peaks.vfx = maxi(peaks.vfx,game.effects.particles.size())
		# Flush queue_free regularly during accelerated simulation.
		if frame % 60 == 0: await process_frame
	var result := {"strategy":strategy,"seed":seed_value,"state":game.state,"seconds":snappedf(game.seconds,0.1),
		"hp":game.health.hp,"money":game.economy.money,"purchases":purchases,"kill_rewards":awarded[0],
		"collected":picked[0],"breach_cost":breached[0],"seizures":seized[0],"peak_entities":peaks}
	report.append(result)
	print(JSON.stringify(result))
	if peaks.enemies > int(Rules.config.enemy_cap) + 1 or peaks.shots > int(Rules.config.projectile_cap) or peaks.coins > int(Rules.config.loot_cap) + 2 or peaks.vfx > int(Rules.config.vfx_cap):
		failed = true
	game.queue_free()
	await process_frame

func choose_position(game: BeaverGame, strategy: String) -> void:
	if game.boss_started:
		game.player.target_x = 0
		return
	# Last two seconds before a gate reserve the chosen answer lane.
	for group in game.gates.groups:
		if group.z > -17 and not group.used:
			var lane: int = group.problem.choices.find(group.problem.answer) - 1
			if strategy == "bad_math": lane = (lane + 2) % 3 - 1
			game.player.target_x = lane * 2
			return
	if strategy == "losses":
		game.player.target_x = sin(game.seconds * 1.4) * 4.6
		return
	var target := game.player.target_x
	var priority := -INF
	for enemy in game.enemies.enemies:
		var score: float = 30 + enemy.pos.y - absf(enemy.pos.x - game.player.x) * 1.2
		if enemy.pos.y > -1: continue
		if score > priority:
			priority = score
			target = enemy.pos.x
	for coin in game.loot.coins:
		if coin.pos.y > -10 and coin.pos.y < 0:
			var score: float = 35 + coin.pos.y - absf(coin.pos.x - game.player.x) * 4
			if score > priority:
				priority = score
				target = coin.pos.x
	# Local dodge of imminent hostile projectiles, without changing any projectile.
	for shot in game.projectiles.shots:
		if not shot.friendly and shot.pos.y > -5 and shot.pos.y < 0 and absf(shot.pos.x - game.player.x) < 0.65:
			target = clampf(game.player.x + (2 if game.player.x < 0 else -2),-4.6,4.6)
	game.player.target_x = target
