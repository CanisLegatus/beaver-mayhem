extends SceneTree
## Physical full boss fights, including live attack state machines and QTE response.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var passed := true
	for level in [1,2]:
		var game: BeaverGame = load("res://scenes/main.tscn").instantiate()
		game.progression=Progression.new("user://boss-tests.cfg")
		game.progression.unlocked=2
		root.add_child(game)
		await process_frame
		game.set_physics_process(false)
		game.hazards.rng.seed=42
		game.enemies.boss_driver.rng.seed=42
		game.current_level=level
		game.start_run()
		# A documented combat fixture, not a claim of naturally earning this build.
		game.economy.money=1000
		game.economy.buy("heavy")
		game.economy.buy("damage")
		game.economy.buy("damage")
		game.economy.buy("rate")
		game.economy.buy("rate")
		game.seconds=150
		game.gates.schedule_index=8
		game._physics_process(1.0/60)
		for frame in range(60*100):
			if game.state in ["victory","game_over"]: break
			if game.state == "qte" and game.qte.remaining<1.2: game.qte.press(game.qte.expected)
			var blocked: Array=[]
			for h in game.hazards.hazards:
				for lane in h.get("lanes",[]):
					if lane not in blocked: blocked.append(lane)
			game.player.target_x=0
			if not blocked.is_empty():
				for lane in range(-2,3):
					if lane not in blocked:
						game.player.target_x=lane*2
						break
			elif game.enemies.boss_driver.phase in ["windup_charge","charge"]:
				game.player.target_x=-4 if game.enemies.boss_driver.target_x>=0 else 4
			for shot in game.projectiles.shots:
				if not shot.friendly and shot.velocity.y>0:
					var t: float=-shot.pos.y/shot.velocity.y
					if t>0 and t<0.6 and absf(shot.pos.x+shot.velocity.x*t-game.player.x)<0.8:
						game.player.target_x=clampf(game.player.x+(2 if game.player.x<0 else -2),-4.6,4.6)
			game._physics_process(1.0/60)
			if frame%60==0: await process_frame
		print("BOSS FIGHT chapter %d: %s, HP %.0f, combat %.1fs" % [level,game.state,game.health.hp,game.seconds-150])
		if game.state!="victory": passed=false
		game.queue_free()
		await process_frame
	await create_timer(0.2).timeout
	quit(0 if passed else 1)
