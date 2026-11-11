extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_size = Vector2i(432,864)
	var game: BeaverGame = load("res://scenes/main.tscn").instantiate()
	game.progression = Progression.new("user://test-capture.cfg")
	game.progression.unlocked = 1
	game.progression.selected = 1
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	await capture("roadmap")
	game.select_level(1)
	game.cinematic.tick(1)
	await capture("family")
	game.cinematic.tick(5)
	await capture("hero")
	game.cinematic.complete()
	game.seconds = 34
	game.gates.schedule_index = 2
	game.enemies.spawn(0,-4,-14)
	game.enemies.spawn(1,2,-23)
	game.enemies.spawn(2,-2,-35)
	game.enemies.tick(0,34,0)
	game.gates.spawn(34)
	game.gates.groups[0].z = -26
	game.gates.tick(0,34,0)
	game.loot.drop(Vector2(-2,-6),25)
	game.loot.tick(0,0)
	game.projectiles.spawn("rocket",Vector3(-1,1,-13),Vector2(1,12),24,false)
	game.projectiles.tick(0.5,0)
	game.projectiles.rocket_trails(game.effects,0.1)
	game.hud.refresh(game.health,game.economy,34,{},game.combat)
	game.hud.show_math(game.gates.groups)
	game.world.set_time(0)
	await capture("gameplay")
	game.hud.root.hide()
	await capture_preview()
	game.hud.root.show()
	game.world.set_time(55)
	await capture("night")
	game.start_run()
	game.seconds = 155
	game.enemies.spawn_boss()
	game.enemies.boss.pos.y = -21
	game.enemies.tick(0,155,0)
	game.hud.refresh(game.health,game.economy,155,game.enemies.boss,game.combat)
	await capture("boss")
	for i in range(50):
		game.projectiles.spawn("log",Vector3(0,1,-19),Vector2(0,-38),12,true)
		game.projectiles.tick(0.1,0)
	game.enemies.tick(0,155,0)
	await capture("victory")
	game.show_map()
	await capture("roadmap-unlocked")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
func capture(label: String) -> void:
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+label+".png")
	print("Captured ",label)
func capture_preview() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://assets/images/level-preview.png")
