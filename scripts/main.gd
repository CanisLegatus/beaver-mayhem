class_name BeaverGame
extends Node3D
## Composition root; all runtime motion uses a floating origin at the runner.
var progression := Progression.new()
var level_map: LevelMap
var cinematic: OpeningCinematic
var action_camera: ActionCamera
var hazards: HazardSystem
var qte := DodgeQTE.new()
var qte_touch_origin := Vector2.ZERO
var current_level := 1
var paused_from := "playing"
var player := PlayerController.new()
var combat := PlayerCombat.new()
var economy := Economy.new()
var health := Health.new()
var world: ForestWorld
var projectiles: ProjectileSystem
var enemies: EnemySystem
var loot: LootSystem
var gates: GateSystem
var effects: Effects
var audio: GameAudio
var hud: GameHUD
var beaver: Node3D
var camera: Camera3D
var state := "menu"
var seconds := 0.0
var boss_started := false
var recoil := 0.0
var alarm_timer := 0.0
var smoke_timer := 0.0
var breath_timer := 0.0
var last_damage := ""

func _ready() -> void:
	world = ForestWorld.new()
	add_child(world)
	projectiles = ProjectileSystem.new()
	add_child(projectiles)
	enemies = EnemySystem.new()
	add_child(enemies)
	projectiles.targets = enemies.enemies
	hazards = HazardSystem.new()
	add_child(hazards)
	hazards.damaged.connect(take_damage)
	hazards.announced.connect(func(text: String) -> void: hud.notify(text))
	hazards.sound_requested.connect(func(key: String) -> void: audio.play(key))
	hazards.burst_requested.connect(func(pos: Vector3,color: Color,count: int) -> void: effects.burst(pos,color,count))
	loot = LootSystem.new()
	add_child(loot)
	gates = GateSystem.new()
	add_child(gates)
	effects = Effects.new()
	add_child(effects)
	audio = GameAudio.new()
	add_child(audio)
	beaver = Art.beaver()
	add_child(beaver)
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 10.5, 14.5)
	camera.look_at(Vector3(0, 0, -22))
	camera.fov = 58
	camera.far = 320
	camera.current = true
	hud = GameHUD.new()
	add_child(hud)
	level_map = LevelMap.new()
	add_child(level_map)
	level_map.level_selected.connect(select_level)
	cinematic = OpeningCinematic.new()
	add_child(cinematic)
	cinematic.setup(camera,beaver)
	action_camera = ActionCamera.new()
	add_child(action_camera)
	action_camera.setup(camera,beaver)
	action_camera.finished.connect(func(mode: String) -> void:
		state = "playing"
		beaver.position = Vector3(player.x,0,0)
		hud.set_state(state)
		hud.set_qte(false,0,0)
		audio.set_mood(state)
		if mode == "moon":
			hud.notify("MOONFALL  •  SURVIVE THE HORDE")
			audio.play("go"))
	action_camera.sound_requested.connect(func(key: String) -> void:
		audio.play(key)
		if key == "moon_impact": world.weather.flash = 1.0)
	action_camera.burst_requested.connect(func(pos: Vector3,color: Color,count: int) -> void: effects.burst(pos,color,count))
	qte.resolved.connect(resolve_qte)
	hud.qte_pressed.connect(func(direction: int) -> void:
		if state == "qte": qte.press(direction))
	enemies.boss_driver.announced.connect(hud.notify)
	enemies.boss_driver.qte_requested.connect(begin_qte)
	enemies.contact_hit.connect(take_damage)
	world.weather.thunder.connect(func() -> void: audio.play("thunder"))
	cinematic.dam_creaked.connect(func() -> void: audio.play("dam"))
	level_map.sound_requested.connect(hud.sound_requested.emit)
	cinematic.finished.connect(func() -> void:
		audio.play("go")
		state = "playing"
		hud.set_state(state)
		audio.set_mood(state))
	hud.start_requested.connect(func() -> void: select_level(progression.selected))
	hud.map_requested.connect(show_map)
	hud.next_requested.connect(func() -> void: select_level(mini(10,current_level+1)))
	hud.skip_requested.connect(func() -> void:
		if action_camera.mode == "moon": action_camera.complete()
		else: cinematic.complete())
	hud.restart_requested.connect(start_run)
	hud.pause_requested.connect(toggle_pause)
	hud.sound_requested.connect(func() -> void:
		AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0)))
	hud.purchase_requested.connect(purchase)
	hud.cycle_requested.connect(economy.cycle)
	projectiles.player_hit.connect(take_damage)
	projectiles.impact.connect(func(pos: Vector3, color: Color) -> void:
		effects.burst(pos, color, 3)
		audio.play("hit"))
	projectiles.rocket_ignited.connect(func(pos: Vector3) -> void:
		effects.burst(pos, Art.GOLD, 10)
		audio.play("rocket"))
	projectiles.rocket_exploded.connect(func(pos: Vector3) -> void:
		effects.burst(pos, Color("ff884f"), 14)
		audio.play("explosion"))
	enemies.attack.connect(func(kind: int, pos: Vector3, velocity: Vector2, damage: float) -> void:
		projectiles.spawn(["axe", "paper", "rocket","spit"][kind], pos, velocity, damage, false)
		audio.play(["shoot", "paper", "rocket","zombie"][kind]))
	enemies.killed.connect(func(pos: Vector2, reward: int) -> void:
		loot.drop(pos, reward)
		effects.burst(Vector3(pos.x, 1, pos.y), Art.GOLD, 8))
	enemies.breached.connect(func(penalty: int) -> void:
		economy.credit(-penalty)
		hud.notify("BREACH  −$%d" % penalty)
		audio.play("wrong"))
	enemies.boss_destroyed.connect(win)
	loot.collected.connect(func(amount: int, pos: Vector3) -> void:
		economy.credit(amount)
		effects.burst(pos, Art.GOLD, 3)
		audio.play("coin"))
	gates.answered.connect(func(value: int) -> void:
		economy.credit(value)
		hud.notify(("CORRECT  +$%d" % value) if value > 0 else ("WRONG  −$%d" % -value))
		audio.play("correct" if value > 0 else "wrong")
		effects.burst(Vector3(player.x, 1.5, 0), Art.MINT if value > 0 else Color("ff7755"), 16))
	economy.debt_started.connect(func() -> void:
		audio.play("alarm")
		alarm_timer = 2.5)
	economy.confiscated.connect(func(item: String) -> void:
		hud.notify("CONFISCATED: " + item)
		audio.play("alarm")
		effects.burst(beaver.position + Vector3.UP, Color("ff7755"), 10))
	hud.refresh(health, economy, seconds, enemies.boss, combat)
	show_map()
	if "--demo" in OS.get_cmdline_user_args(): start_run()

func start_run() -> void:
	get_viewport().disable_3d = false
	if level_map != null: level_map.root.hide()
	if cinematic != null: cinematic.cancel()
	if action_camera != null: action_camera.clear()
	qte.clear()
	hazards.clear()
	enemies.chapter = current_level
	world.configure(current_level)
	hud.set_weather(world.weather.snow_amount)
	audio.set_level(current_level)
	hud.set_qte(false,0,0)
	hud.root.show()
	beaver.rotation = Vector3.ZERO
	beaver.scale = Vector3.ONE
	camera.fov = 58
	camera.position = Vector3(0,10.5,14.5)
	camera.look_at(Vector3(0,0,-22))
	world.set_time(0)
	audio.set_mood("playing")
	projectiles.clear()
	enemies.clear()
	loot.clear()
	gates.clear()
	effects.clear()
	audio.reset_cues()
	economy.reset()
	player.reset()
	combat.reset()
	health = Health.new(Rules.config.starting_hp)
	seconds = 0
	boss_started = false
	alarm_timer = 0
	smoke_timer = 0
	recoil = 0
	beaver.position = Vector3.ZERO
	state = "playing"
	hud.set_state(state)
	hud.show_math(gates.groups,seconds)
	hud.notify("DEFEND THE FOREST!")
	audio.play("ready")

func _physics_process(delta: float) -> void:
	hud.tick(delta)
	if state == "qte":
		action_camera.tick(delta)
		qte.tick(delta)
		hud.set_qte(qte.active,qte.expected,qte.remaining)
		return
	if state == "dodge_movie":
		world.weather.tick(delta)
		world.set_time(seconds)
		action_camera.tick(delta)
		effects.tick(delta)
		return
	if state == "cinematic":
		if action_camera.mode == "moon":
			action_camera.tick(delta)
			world.weather.tick(delta)
			world.set_time(0)
			effects.tick(delta)
		else: cinematic.tick(delta)
		return
	if state != "playing":
		if state == "victory": effects.tick(delta)
		hud.show_math([])
		return
	seconds += delta
	var keyboard := 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): keyboard -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): keyboard += 1
	player.tick(delta, keyboard, Rules.run_speed(seconds))
	world.scroll(delta,seconds)
	hud.set_weather(world.weather.snow_amount)
	breath_timer -= delta
	if world.weather.snow_amount > 0.6 and breath_timer <= 0:
		effects.burst(Vector3(player.x,1.5,-0.6),Color("bbd7e1"),2,"smoke")
		breath_timer = 0.85
	beaver.position = Vector3(player.x, absf(sin(seconds * 12)) * 0.09, 0)
	beaver.rotation.z = clampf((player.target_x - player.x) * -0.08, -0.18, 0.18)
	beaver.get_node("FootL").rotation.x = sin(seconds * 12) * 0.6
	beaver.get_node("FootR").rotation.x = -sin(seconds * 12) * 0.6
	camera.position.x = lerpf(camera.position.x, player.x * 0.10, delta * 3)
	if combat.tick(delta, player.x, economy, projectiles):
		recoil = 0.08
		audio.play("shoot")
	recoil = maxf(0, recoil - delta)
	beaver.position.z = recoil
	gates.tick(delta, seconds, player.x)
	if seconds < float(Rules.config.run_seconds):
		enemies.director(delta, seconds, gates.near_player())
	elif not boss_started:
		boss_started = true
		enemies.spawn_boss()
		hud.notify("FINAL THREAT: " + enemies.boss.name)
		audio.set_boss()
		audio.play("alarm")
	hazards.director(delta,seconds,current_level,world.night_amount,gates.near_player() or boss_started)
	hazards.tick(delta,player.x,Rules.run_speed(seconds))
	if state != "playing": return
	if boss_started:
		enemies.boss_driver.tick(delta,player.x,enemies.boss,projectiles,hazards)
		if state != "playing": return
	projectiles.tick(delta, player.x)
	projectiles.rocket_trails(effects, delta)
	if state != "playing": return
	enemies.tick(delta, seconds, player.x, gates.near_player())
	if state != "playing": return
	loot.tick(delta, player.x,Rules.run_speed(seconds))
	economy.tick(delta)
	effects.tick(delta)
	alarm_timer -= delta
	if economy.money < 0 and alarm_timer <= 0:
		audio.play("alarm")
		alarm_timer = 2.5
	if boss_started and not enemies.boss.is_empty() and not enemies.boss.health.dead:
		smoke_timer -= delta
		if smoke_timer <= 0:
			effects.burst(enemies.boss.visual.position + Vector3(1.3,4,-1.5), Color("606b66"), 2)
			smoke_timer = 0.25
	hud.refresh(health, economy, seconds, enemies.boss, combat)
	hud.show_math(gates.groups,seconds)

func _unhandled_input(event: InputEvent) -> void:
	if state == "qte":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode in [KEY_A,KEY_LEFT,KEY_Q]: qte.press(0)
			elif event.physical_keycode in [KEY_S,KEY_DOWN,KEY_SPACE]: qte.press(1)
			elif event.physical_keycode in [KEY_D,KEY_RIGHT,KEY_E]: qte.press(2)
		if event is InputEventScreenTouch:
			if event.pressed: qte_touch_origin = event.position
			else:
				var swipe: Vector2 = event.position-qte_touch_origin
				if swipe.length()>45: qte.press(1 if absf(swipe.y)>absf(swipe.x) else (0 if swipe.x<0 else 2))
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		toggle_pause()
		return
	if state == "playing": player.input(event, get_viewport().get_visible_rect().size)

func _input(event: InputEvent) -> void:
	# Releases must reach the controller even when the pointer ends over HUD.
	if event is InputEventScreenTouch and not event.pressed and event.index == player.pointer_id:
		player.pointer_id = -1
	if event is InputEventMouseButton and not event.pressed: player.mouse_down = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		if state in ["playing","cinematic","qte","dodge_movie"]: toggle_pause()
		if audio != null and audio.music != null:
			audio.music.stream_paused = true
			if audio.ambience != null: audio.ambience.stream_paused = true
			if audio.speech != null: audio.speech.stream_paused = true
	if what == NOTIFICATION_APPLICATION_RESUMED and audio != null: audio.set_mood(state)
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and state in ["playing","cinematic","qte","dodge_movie"]: toggle_pause()

func purchase(item: String) -> void:
	if state != "playing": return
	if item in economy.owned:
		economy.active = item
	elif economy.buy(item):
		hud.notify("UPGRADED: " + item.to_upper())
		audio.play("buy")
		effects.burst(Vector3(player.x, 1, 0), Art.MINT, 10)

func take_damage(amount: float) -> void:
	if state != "playing": return
	if health.hit(amount):
		hud.damage_flash()
		recoil = 0.15
		audio.play("hit")
	if health.dead: lose("The beaver ran out of HP.")

func toggle_pause() -> void:
	if state not in ["playing", "cinematic", "qte","dodge_movie", "paused"]: return
	if state == "paused": state = paused_from
	else:
		paused_from = state
		state = "paused"
	player.pointer_id = -1
	player.mouse_down = false
	hud.set_state(state)
	audio.set_mood(state)

func select_level(level: int) -> void:
	if not progression.select(level): return
	current_level = level
	start_run()
	if level == 2:
		state = "cinematic"
		action_camera.start_moon()
		hud.set_state(state)
		hud.cinematic_caption.text = "THE MOON IS FALLING.\nThe dead will not stay buried."
		audio.set_mood(state)
	elif level == 1:
		hud.cinematic_caption.text = "THEIR HOME. HIS PROMISE.\nHold the dam. I will stop them."
		state = "cinematic"
		cinematic.start()
		hud.set_state(state)
		audio.set_mood(state)

func show_map() -> void:
	get_viewport().disable_3d = true
	state = "menu"
	if cinematic != null: cinematic.cancel()
	if action_camera != null: action_camera.clear()
	qte.clear()
	hud.set_qte(false,0,0)
	player.pointer_id = -1
	player.mouse_down = false
	hud.root.hide()
	level_map.show_campaign(progression)
	audio.set_mood(state)

func lose(reason: String) -> void:
	if state != "playing": return
	state = "game_over"
	last_damage = reason
	hud.set_state(state)
	hud.overlay_text.text = reason + "\nCash: $%d  •  Time: %ds" % [economy.money, int(seconds)]
	hud.refresh(health, economy, seconds, enemies.boss, combat)
	audio.play("loss")
	audio.set_mood(state)

func win() -> void:
	if state != "playing": return
	state = "victory"
	if not progression.complete(current_level):
		hud.notify("PROGRESS SAVE FAILED")
	audio.set_mood(state)
	var pos: Vector3 = enemies.boss.visual.position
	for i in range(5): effects.burst(pos + Vector3(i - 2, 1.0 + i * 0.4, 0), Art.GOLD if i % 2 == 0 else Art.DARK, 18)
	hud.set_state(state)
	if current_level == 10: hud.play_button.text = "REPLAY FINAL CHAPTER  →"
	hud.overlay_text.text = "The forest is yours again.\nCash: $%d  •  Time: %ds" % [economy.money, int(seconds)]
	hud.refresh(health, economy, seconds, enemies.boss, combat)
	audio.play("explosion")
	audio.play("victory")

func _exit_tree() -> void:
	Art.materials.clear()
	Art.meshes.clear()
	Sculpt.clear_cache()

func begin_qte(direction: int, prop: String) -> void:
	if state != "playing": return
	qte.begin(direction,prop)
	action_camera.prepare_throw(prop)
	state = "qte"
	player.pointer_id = -1
	player.mouse_down = false
	hud.set_state(state)
	hud.set_qte(true,direction,qte.remaining)
	audio.play("qte")

func resolve_qte(success: bool) -> void:
	if state != "qte": return
	hud.set_qte(false,0,0)
	if success:
		state = "dodge_movie"
		action_camera.start_dodge(qte.expected,qte.camera_variant,qte.prop,player.x)
		hud.set_state(state)
	else:
		action_camera.clear()
		state = "playing"
		effects.burst(Vector3(player.x,1,0),Color("a9916c"),18)
		take_damage(28)
		hud.set_state(state)
		hud.notify("TOO SLOW  •  TITAN IMPACT")
