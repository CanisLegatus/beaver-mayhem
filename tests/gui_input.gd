extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ",text)
	else: print("PASS: ",text)
func click(pos: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = pos
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_size = Vector2i(432,864)
	var game: BeaverGame = load("res://scenes/main.tscn").instantiate()
	game.progression = Progression.new("user://test-progress.cfg")
	game.progression.unlocked = 1
	game.progression.selected = 1
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	for i in range(3): await process_frame
	click(game.level_map.card_buttons[0].get_global_rect().get_center())
	await process_frame
	check(game.state == "cinematic", "map starts first-level cinematic")
	click(game.hud.skip_button.get_global_rect().get_center())
	check(game.state == "playing", "skip story enters gameplay")
	var down := InputEventMouseButton.new()
	down.position = Vector2(216,450)
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	root.push_input(down,true)
	var move := InputEventMouseMotion.new()
	move.position = Vector2(288,450)
	move.relative = Vector2(72,0)
	root.push_input(move,true)
	down = down.duplicate()
	down.pressed = false
	down.position = move.position
	root.push_input(down,true)
	check(is_equal_approx(game.player.target_x,2), "gameplay drag reaches controller through viewport")
	game.economy.money = 500
	game.hud.refresh(game.health,game.economy,0,{},game.combat)
	await process_frame
	click(game.hud.buttons.damage.get_global_rect().get_center())
	await process_frame
	check(game.economy.damage_level == 1, "HUD damage button buys actual upgrade")
	check(is_equal_approx(game.player.target_x,2) and not game.player.mouse_down, "HUD click does not move or latch player")
	game.toggle_pause()
	await process_frame
	click(game.hud.play_button.get_global_rect().get_center())
	check(game.state == "playing", "resume button works")
	game.lose("Input test")
	await process_frame
	click(game.hud.restart_button.get_global_rect().get_center())
	check(game.state == "playing" and game.economy.damage_level == 0, "restart button resets run")
	game.progression.unlocked = 2
	game.show_map()
	for i in range(3): await process_frame
	click(game.level_map.root.get_node("CreditsButton").get_global_rect().get_center())
	check(game.level_map.credits_panel.visible,"offline asset/music credits open")
	var close: Button = game.level_map.credits_panel.find_child("CloseCredits",true,false)
	click(close.get_global_rect().get_center())
	check(not game.level_map.credits_panel.visible,"credits close")
	click(game.level_map.card_buttons[1].get_global_rect().get_center())
	check(game.current_level == 2 and game.action_camera.mode == "moon","chapter 2 selection starts moonfall")
	await process_frame
	click(game.hud.skip_button.get_global_rect().get_center())
	check(game.state == "playing","moonfall skip restores run")
	game.begin_qte(2,"house")
	await process_frame
	var right_button: Button = game.hud.qte_panel.get_child(2).get_child(2)
	click(right_button.get_global_rect().get_center())
	check(game.state == "dodge_movie","QTE touch button triggers dodge")
	game.action_camera.tick(2)
	check(game.state == "playing","cinematic dodge returns to playing")
	game.queue_free()
	await process_frame
	Art.materials.clear()
	Art.meshes.clear()
	Sculpt.clear_cache()
	await create_timer(0.15).timeout
	print("GUI INPUT: ",failures," failures")
	quit(0 if failures == 0 else 1)
