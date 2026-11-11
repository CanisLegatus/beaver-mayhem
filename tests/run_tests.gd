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
	test_progression()
	await test_runtime()
	Art.materials.clear()
	Art.meshes.clear()
	Sculpt.clear_cache()
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	print("TEST RESULT: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func test_rules() -> void:
	check(is_equal_approx(Rules.move_x(0, 10, 0.1), 0.8), "bounded movement speed")
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
	var controller := PlayerController.new()
	var touch := InputEventScreenTouch.new()
	touch.index = 2
	touch.pressed = true
	controller.input(touch, Vector2(432,864))
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.relative = Vector2(36,0)
	controller.input(drag, Vector2(432,864))
	check(is_equal_approx(controller.target_x, 1.0), "touch drag maps viewport distance")
	drag.index = 3
	controller.input(drag, Vector2(432,864))
	check(is_equal_approx(controller.target_x, 1.0), "second finger cannot move player")
	var mouse := InputEventMouseMotion.new()
	mouse.device = InputEvent.DEVICE_ID_EMULATION
	mouse.relative = Vector2(36,0)
	controller.mouse_down = true
	controller.input(mouse, Vector2(432,864))
	check(is_equal_approx(controller.target_x, 1.0), "synthetic mouse does not double touch")
	touch.pressed = false
	controller.input(touch, Vector2(432,864))
	check(controller.pointer_id == -1, "touch release clears ownership")
	var velocity := Vector2(5,0)
	check(Rules.rocket_velocity(velocity, Vector2(0,20), 0.2, 0.1) == velocity, "rocket side launch fixed")
	var guided := Rules.rocket_velocity(velocity, Vector2(0,20), 0.8, 0.1)
	check(absf(velocity.angle_to(guided)) <= float(Rules.config.rocket_turn) * 0.1 + 0.0001, "rocket angular speed limit")
	check(Rules.rocket_velocity(guided, Vector2(-20,-20), 2, 0.1) == guided, "rocket final trajectory locked")
	var base := Rules.weapon_stats("log",0,0)
	var maximum := Rules.weapon_stats("log",4,4)
	var ratio: float = (maximum.damage / maximum.interval) / (base.damage / base.interval)
	check(ratio > 2 and ratio < 3, "max DPS under 3x")
	check(Rules.threat_budget(float(Rules.config.run_seconds)) == Rules.threat_budget(900), "bounded difficulty")

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

func test_progression() -> void:
	var path := "user://test-campaign-rules.cfg"
	if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	var campaign := Progression.new(path)
	check(campaign.unlocked == 1 and campaign.selected == 1, "fresh campaign unlocks only first")
	check(not campaign.select(2) and not campaign.complete(2), "locked level cannot select or complete")
	check(campaign.complete(1), "victory saves progress")
	var restored := Progression.new(path)
	check(restored.unlocked == 2, "unlock survives reopening save")
	check(restored.select(2), "next level selectable")
	for level in range(2,11): check(restored.complete(level), "sequential chapter completion")
	check(restored.unlocked == 10 and not restored.select(11), "ten chapter campaign bounded")
	check(restored.complete(1) and restored.unlocked == 10, "replaying does not regress progress")
	var corrupt := FileAccess.open(path,FileAccess.WRITE)
	corrupt.store_string("[campaign]\nunlocked=999\nselected=999\n")
	corrupt.close()
	var clamped := Progression.new(path)
	check(clamped.unlocked == 10 and clamped.selected == 10, "save values clamped")
	DirAccess.remove_absolute(path)
	check(Rules.run_speed(0) == 10 and Rules.run_speed(150) == 15 and Rules.run_speed(999) == 15, "acceleration bounded 10 to 15")
	check(Rules.travel_distance(150) == 1875, "accelerating level distance")
	check(Rules.preview_distance(100) > Rules.preview_distance(0), "gate distance grows with speed")
	check(Rules.config.enemy_spawn_distance >= 110, "enemy births near horizon")
	check(Rules.config.enemies[1].reward == 25 and Rules.config.enemies[1].penalty == 10, "engineer reward and smaller fine")

func test_runtime() -> void:
	var game: BeaverGame = load("res://scenes/main.tscn").instantiate()
	game.progression = Progression.new("user://test-progress.cfg")
	game.progression.unlocked = 1
	game.progression.selected = 1
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	check(game.state == "menu" and game.level_map.root.visible, "launch opens campaign map")
	game.select_level(2)
	check(game.state == "menu", "runtime locked-level guard")
	game.select_level(1)
	check(game.state == "cinematic" and game.cinematic.family.visible, "first chapter begins family scene")
	game._physics_process(2)
	check(game.seconds == 0 and game.player.distance == 0, "cinematic does not advance level")
	var story_time := game.cinematic.elapsed
	game.toggle_pause()
	game._physics_process(2)
	check(game.cinematic.elapsed == story_time, "cinematic pause freezes camera/story")
	game.toggle_pause()
	game.cinematic.tick(11)
	check(game.state == "playing" and not game.cinematic.family.visible, "full story transitions to gameplay")
	check(game.camera.position.is_equal_approx(Vector3(0,10.5,14.5)), "cinematic reaches gameplay camera")
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
	check(game.economy.money == money_before + 7 - int(Rules.config.enemies[0].penalty) and game.health.hp == 100, "breach charges once and no HP")
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
	game.projectiles.spawn("log",Vector3(0,1,-134),Vector2(0,-38),12,true)
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
	game.seconds = float(Rules.config.run_seconds)-0.01
	game._physics_process(0.02)
	check(game.boss_started and not game.enemies.boss.is_empty(), "boss appears at configured duration")
	var boss: Dictionary = game.enemies.boss
	game.projectiles.spawn("log",Vector3(0,1,boss.pos.y+2),Vector2(0,-38),12,true)
	game.projectiles.tick(0.1,0)
	check(boss.health.hp == float(Rules.config.bosses.dozer.hp)-12 and not boss.health.dead, "boss takes real nonlethal damage")
	boss.pos.y = -4
	game.enemies.tick(0,91,0)
	check(game.state == "playing", "boss no longer passively collides")
	game.start_run()
	game.enemies.spawn_boss()
	boss = game.enemies.boss
	# Simulate physical volleys, no direct health manipulation.
	for i in range(ceili(float(Rules.config.bosses.dozer.hp)/12)):
		game.projectiles.spawn("log",Vector3(0,1,boss.pos.y+2),Vector2(0,-38),12,true)
		game.projectiles.tick(0.1,0)
	game.enemies.tick(0,100,0)
	check(game.state == "victory" and boss.health.dead, "physical damage can win level")
	check(game.progression.unlocked == 2, "actual boss victory unlocks next chapter")
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
	game.start_run()
	for kind in range(3):
		var attacker := game.enemies.spawn(kind, kind * 2 - 2, -15)
		attacker.attack_timer = 0.1
	game.enemies.tick(0.2,40,0)
	check(game.projectiles.shots.size() == 3, "all three enemy classes attack")
	check(game.projectiles.shots[2].velocity.y == 0, "rocket launches sideways")
	game.projectiles.tick(0.5,0)
	check(game.projectiles.shots[2].ignited, "rocket ignition phase occurs")
	game.start_run()
	for i in range(4): game.enemies.spawn(0,0,-4-i*3)
	game.projectiles.spawn("heavy",Vector3(0,1,0),Vector2(0,-38),31,true,3)
	game.projectiles.tick(0.5,0)
	check(game.enemies.enemies[2].health.dead and not game.enemies.enemies[3].health.dead, "heavy piercing stops at three")
	game.start_run()
	game.economy.money = 500
	game.purchase("damage")
	game._physics_process(0.1)
	check(game.state == "playing" and game.seconds > 0 and game.economy.damage_level == 1, "HUD purchases keep simulation running")
	game.gates.spawn(0)
	game.gates.groups[0].z = 8
	game.gates.tick(0,0,0)
	game.loot.drop(Vector2(0,6),7)
	game.loot.tick(0,0)
	check(game.gates.groups.is_empty() and game.loot.coins.is_empty(), "passed gates and coins expire")
	for i in range(12):
		game.start_run()
		game._physics_process(0.1)
		await process_frame
		check(game.enemies.enemies.size() <= 1 and game.projectiles.shots.size() <= 1, "repeated restart stays bounded")
	game.start_run()
	var elite := game.enemies.spawn(2,0)
	game.enemies.tick(0.2,40,0)
	check(game.projectiles.shots.size() == 1, "elite fires immediately at horizon")
	game.projectiles.tick(0.2,0)
	check(game.projectiles.shots.size() == 1, "far rocket survives projectile bounds")
	game.enemies.tick(float(Rules.config.enemies[2].attack),40,0)
	check(game.projectiles.shots.size() >= 2, "elite repeats rocket in 3.2 seconds")
	game.world.set_time(0)
	var daylight := game.world.sun.light_energy
	game.world.set_time(110)
	check(game.world.night_amount > 0.9 and game.world.sun.light_energy < daylight and game.world.moon.light_energy > 0, "day-night lighting changes")
	game.show_map()
	check(game.state == "menu" and game.level_map.root.visible and not game.hud.root.visible, "return to map stops run")
	game.queue_free()
	await process_frame
