extends SceneTree
var checks := 0
var failures: Array[String] = []

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	test_rules()
	test_economy()
	await test_runtime()
	Art.materials.clear()
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	print("TEST RESULT: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func test_rules() -> void:
	check(is_equal_approx(Rules.move_x(0, 10, 0.1), 0.6), "bounded movement speed")
	check(is_equal_approx(Rules.move_x(4.5, 20, 1), 4.6), "right road edge")
	check(is_equal_approx(Rules.move_x(-4.5, -20, 1), -4.6), "left road edge")
	check(Rules.segment_hits(Vector2(0,0), Vector2(0,-30), Vector2(0,-15), 0.5), "swept collision")
	check(not Rules.segment_hits(Vector2(0,0), Vector2(0,-30), Vector2(2,-15), 0.5), "no phantom collision")
	var hp := Health.new(24)
	var deaths: Array = [0]
	hp.died.connect(func() -> void: deaths[0] += 1)
	check(hp.hit(12) and hp.hp == 12, "health damage")
	hp.hit(20)
	hp.hit(20)
	check(hp.dead and hp.hp == 0 and deaths[0] == 1, "death emitted once")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for seconds in [0,35,70]:
		for i in range(150):
			var problem := Rules.math_problem(seconds, rng)
			var choices: Array = problem.choices
			check(choices.size() == 3 and choices[0] != choices[1] and choices[1] != choices[2] and choices[0] != choices[2], "distinct math choices")
			check(choices.count(problem.answer) == 1, "unique correct answer")
			var expression := Expression.new()
			var source: String = problem.expression.replace(" = ?", "").replace("×","*").replace("÷","/").replace("−","-")
			check(expression.parse(source) == OK and is_equal_approx(float(expression.execute()), problem.answer), "arithmetic verified independently")
			var good := choices.find(problem.answer) - 1
			check(Rules.gate_result(problem, good * 2.0) == problem.reward, "correct gate reward")
			check(Rules.gate_result(problem, 4) == 0, "skip gate is neutral")
			check(Rules.gate_result(problem, ((good + 2) % 3 - 1) * 2.0) < 0, "incorrect gate penalty")
	var velocity := Vector2(5,0)
	check(Rules.rocket_velocity(velocity, Vector2(0,20), 0.2, 0.1) == velocity, "rocket side launch fixed")
	var guided := Rules.rocket_velocity(velocity, Vector2(0,20), 0.8, 0.1)
	check(absf(velocity.angle_to(guided)) <= float(Rules.config.rocket_turn) * 0.1 + 0.0001, "rocket angular speed limit")
	check(Rules.rocket_velocity(guided, Vector2(-20,-20), 2, 0.1) == guided, "rocket final trajectory locked")
	var base := Rules.weapon_stats("log",0,0)
	var maximum := Rules.weapon_stats("log",4,4)
	var ratio: float = (maximum.damage / maximum.interval) / (base.damage / base.interval)
	check(ratio > 2 and ratio < 3, "max DPS under 3x")
	check(Rules.threat_budget(90) == Rules.threat_budget(900), "bounded difficulty")

func test_economy() -> void:
	var e := Economy.new()
	e.money = 500
	check(e.buy("damage") and e.money == 435 and e.damage_level == 1, "upgrade deducts and applies")
	e.money = 0
	check(not e.buy("rate") and e.rate_level == 0, "insufficient funds rejected")
	e.credit(-12)
	check(e.money == -12, "negative balance allowed")
	e.tick(9.9)
	check(e.damage_level == 1, "no early seizure")
	e.tick(0.11)
	check(e.damage_level == 0, "seizure at ten seconds")
	e.tick(40)
	check(e.owned == ["log"], "base weapon protected without assets")
	e.credit(12)
	check(e.debt_time == 0, "debt recovery resets clock")
	e.money = 500
	check(e.buy("laser") and e.active == "laser", "weapon purchase equips")
	check(not e.buy("laser"), "duplicate purchase rejected")
	e.damage_level = 0
	e.rate_level = 0
	e.confiscate()
	check(e.active == "log" and e.owned == ["log"], "active seized weapon falls back")
	for kind in ["damage", "rate"]:
		e.money = 10000
		for i in range(4): check(e.buy(kind), "four upgrade levels purchasable")
		check(not e.buy(kind), "upgrade cap enforced")
	e.reset()
	check(e.money == Rules.config.starting_money and e.damage_level == 0 and e.rate_level == 0 and e.active == "log", "economy reset")

func test_runtime() -> void:
	var game: BeaverGame = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start_run()
	game.player.tick(1,1)
	check(game.player.distance == Rules.config.run_speed and game.player.x > 0, "runner forward progress")
	game.start_run()
	check(game.player.x == 0 and game.player.distance == 0, "player reset")
	var enemy := game.enemies.spawn(0,0,-5)
	var shot := game.projectiles.spawn("log",Vector3(0,1,-1),Vector2(0,-38),12,true)
	game.player.target_x = 4
	game.player.tick(0.5)
	game.projectiles.tick(0.1,game.player.x)
	check(shot.pos.x == 0 and shot.velocity.x == 0, "old log independent of player")
	check(enemy.health.hp == 12, "actual projectile damages target")
	game.projectiles.tick(0.2,game.player.x)
	check(enemy.health.hp == 12, "consumed shot cannot repeat damage")
	game.projectiles.spawn("log",Vector3(0,1,-1),Vector2(0,-38),12,true)
	game.projectiles.tick(0.2,game.player.x)
	game.enemies.tick(0,1,game.player.x)
	check(game.enemies.enemies.is_empty() and game.loot.coins.size() == 3, "dead enemy drops once")
	game.enemies.tick(0,1,game.player.x)
	check(game.loot.coins.size() == 3, "no duplicated loot")
	var money_before := game.economy.money
	game.loot.clear()
	game.loot.drop(Vector2(-4,0),7)
	game.loot.tick(0.01,4)
	check(game.economy.money == money_before, "distant coins not credited")
	game.loot.clear()
	game.loot.drop(Vector2(0,0),7)
	game.loot.tick(0.01,0)
	check(game.economy.money == money_before + 7, "physical pickup exact value")
	game.enemies.spawn(0,0,3.1)
	game.enemies.tick(0,1,0)
	game.enemies.tick(0,1,0)
	check(game.economy.money == money_before + 7 - 12 and game.health.hp == 100, "breach charges once and no HP")
	game.start_run()
	var target_a := game.enemies.spawn(0,0,-4)
	var target_b := game.enemies.spawn(0,0,-7)
	game.projectiles.spawn("log",Vector3(0,1,-1),Vector2(0,-38),12,true)
	game.projectiles.tick(0.3,0)
	check(target_a.health.hp == 12 and target_b.health.hp == 24, "ordinary shot hits nearest only")
	game.projectiles.spawn("heavy",Vector3(0,1,-1),Vector2(0,-38),10,true,3)
	game.projectiles.tick(0.3,0)
	check(target_a.health.hp == 2 and target_b.health.hp == 14, "heavy pierces distinct targets")
	var old_hp: float = target_b.health.hp
	game.projectiles.tick(0.01,0)
	check(target_b.health.hp == old_hp, "piercing no double-hit")
	game.projectiles.clear()
	for kind in ["axe","paper"]:
		var hostile := game.projectiles.spawn(kind, Vector3(0,1,-10), Vector2(0,14),4,false)
		game.projectiles.tick(0.1,4)
		check(hostile.velocity == Vector2(0,14) and hostile.pos.x == 0, "fixed " + kind + " trajectory")
	game.projectiles.clear()
	game.projectiles.spawn("axe",Vector3(0,1,-1),Vector2(0,14),4,false)
	game.projectiles.tick(0.2,0)
	game.projectiles.tick(0.2,0)
	check(game.health.hp == 96, "hostile hit applies damage once")
	game.projectiles.spawn("log",Vector3(0,1,-79),Vector2(0,-38),12,true)
	game.projectiles.tick(1,4)
	check(game.projectiles.shots.is_empty(), "offscreen shot cleanup")
	game.start_run()
	var group := game.gates.spawn(0)
	group.z = -0.01
	var lane: int = group.problem.choices.find(group.problem.answer) - 1
	money_before = game.economy.money
	game.gates.tick(0.01,0,lane * 2)
	game.gates.tick(0.01,0,lane * 2)
	check(game.economy.money == money_before + group.problem.reward, "gate fires exactly once")
	game.start_run()
	game.economy.money = 1000
	game.purchase("laser")
	for i in range(240): game.combat.tick(1.0/60,0,game.economy,game.projectiles)
	check(game.combat.overheated, "laser really overheats")
	game.economy.active = "log"
	for i in range(180): game.combat.tick(1.0/60,0,game.economy,game.projectiles)
	check(not game.combat.overheated and game.combat.heat == 0, "laser cools")
	game.start_run()
	game.seconds = 89.99
	game._physics_process(0.02)
	check(game.boss_started and not game.enemies.boss.is_empty(), "boss appears at 90 seconds")
	var boss: Dictionary = game.enemies.boss
	game.projectiles.spawn("log",Vector3(0,1,boss.pos.y+2),Vector2(0,-38),12,true)
	game.projectiles.tick(0.1,0)
	check(boss.health.hp == 588 and not boss.health.dead, "boss takes real nonlethal damage")
	boss.pos.y = -4
	game.enemies.tick(0,91,0)
	check(game.state == "game_over", "boss contact ends run")
	game.start_run()
	game.enemies.spawn_boss()
	boss = game.enemies.boss
	# Simulate physical volleys, no direct health manipulation.
	for i in range(50):
		game.projectiles.spawn("log",Vector3(0,1,boss.pos.y+2),Vector2(0,-38),12,true)
		game.projectiles.tick(0.1,0)
	game.enemies.tick(0,100,0)
	check(game.state == "victory" and boss.health.dead, "physical damage can win level")
	game.start_run()
	check(game.state == "playing" and game.health.hp == 100 and game.seconds == 0 and not game.boss_started, "full state restart")
	check(game.enemies.enemies.is_empty() and game.projectiles.shots.is_empty() and game.loot.coins.is_empty() and game.gates.groups.is_empty(), "restart removes all entities")
	check(game.gates.schedule_index == 0 and game.enemies.spawn_timer == 0.4 and game.combat.heat == 0, "restart restores timers and generator")
	game.toggle_pause()
	game._physics_process(1)
	check(game.seconds == 0 and game.state == "paused", "pause stops gameplay")
	game.toggle_pause()
	game._physics_process(0.1)
	check(game.seconds > 0 and game.player.distance > 0, "resume restores motion")
	game.queue_free()
	await process_frame
