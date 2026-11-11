class_name BeaverGame
extends Node3D
## Composition root; all runtime motion uses a floating origin at the runner.
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
var last_damage := ""

func _ready() -> void:
	world = ForestWorld.new()
	add_child(world)
	projectiles = ProjectileSystem.new()
	add_child(projectiles)
	enemies = EnemySystem.new()
	add_child(enemies)
	projectiles.targets = enemies.enemies
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
	camera.position = Vector3(0, 12.5, 16)
	camera.look_at(Vector3(0, 0, -15))
	camera.fov = 58
	camera.far = 180
	camera.current = true
	hud = GameHUD.new()
	add_child(hud)
	hud.start_requested.connect(start_run)
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
		projectiles.spawn(["axe", "paper", "rocket"][kind], pos, velocity, damage, false)
		audio.play(["shoot", "paper", "rocket"][kind]))
	enemies.killed.connect(func(pos: Vector2, reward: int) -> void:
		loot.drop(pos, reward)
		effects.burst(Vector3(pos.x, 1, pos.y), Art.GOLD, 8))
	enemies.breached.connect(func(penalty: int) -> void:
		economy.credit(-penalty)
		hud.notify("BREACH  −$%d" % penalty)
		audio.play("wrong"))
	enemies.boss_destroyed.connect(win)
	enemies.boss_collision.connect(func() -> void: lose("The bulldozer reached the forest."))
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
	if "--demo" in OS.get_cmdline_user_args(): start_run()

func start_run() -> void:
	projectiles.clear()
	enemies.clear()
	loot.clear()
	gates.clear()
	effects.clear()
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
	hud.show_math(gates.groups)
	hud.notify("DEFEND THE FOREST!")

func _physics_process(delta: float) -> void:
	hud.tick(delta)
	if state != "playing":
		if state == "victory": effects.tick(delta)
		hud.show_math([])
		return
	seconds += delta
	var keyboard := 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): keyboard -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): keyboard += 1
	player.tick(delta, keyboard)
	world.scroll(delta)
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
		hud.notify("FINAL THREAT: DEFORESTATOR")
		audio.play("alarm")
	projectiles.tick(delta, player.x)
	projectiles.rocket_trails(effects, delta)
	if state != "playing": return
	enemies.tick(delta, seconds, player.x, gates.near_player())
	if state != "playing": return
	loot.tick(delta, player.x)
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
	hud.show_math(gates.groups)

func _unhandled_input(event: InputEvent) -> void:
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
	if what == NOTIFICATION_APPLICATION_PAUSED and state == "playing": toggle_pause()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and state == "playing": toggle_pause()

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
	if state not in ["playing", "paused"]: return
	state = "paused" if state == "playing" else "playing"
	player.pointer_id = -1
	player.mouse_down = false
	hud.set_state(state)

func lose(reason: String) -> void:
	if state != "playing": return
	state = "game_over"
	last_damage = reason
	hud.set_state(state)
	hud.overlay_text.text = reason + "\nCash: $%d  •  Time: %ds" % [economy.money, int(seconds)]
	hud.refresh(health, economy, seconds, enemies.boss, combat)
	audio.play("loss")

func win() -> void:
	if state != "playing": return
	state = "victory"
	var pos: Vector3 = enemies.boss.visual.position
	for i in range(5): effects.burst(pos + Vector3(i - 2, 1.0 + i * 0.4, 0), Art.GOLD if i % 2 == 0 else Art.DARK, 18)
	hud.set_state(state)
	hud.overlay_text.text = "The forest is yours again.\nCash: $%d  •  Time: %ds" % [economy.money, int(seconds)]
	hud.refresh(health, economy, seconds, enemies.boss, combat)
	audio.play("explosion")
	audio.play("victory")
