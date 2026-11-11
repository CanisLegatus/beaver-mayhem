extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_size = Vector2i(432,864)
	var game: BeaverGame = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	await capture("menu")
	game.start_run()
	game.seconds = 40
	game.enemies.spawn(0,-4,-13)
	game.enemies.spawn(1,2,-22)
	game.enemies.spawn(2,-2,-32)
	game.enemies.spawn(0,0,-36)
	game.enemies.spawn(0,4,-39)
	game.gates.schedule_index = 3
	game.gates.spawn(40)
	game.gates.groups[0].z = -20
	game.gates.tick(0,40,0)
	game.loot.drop(Vector2(-2,-5),16)
	game.loot.tick(0,0)
	game.projectiles.spawn("rocket",Vector3(-1,1,-13),Vector2(1,12),24,false)
	game.projectiles.tick(0.5,0)
	game.hud.refresh(game.health,game.economy,game.seconds,game.enemies.boss,game.combat)
	game.hud.show_math(game.gates.groups)
	await capture("gameplay")
	game.start_run()
	game.economy.money = 700
	game.purchase("heavy")
	game.purchase("damage")
	game.purchase("rate")
	game.seconds = 95
	game.enemies.spawn_boss()
	game.enemies.boss.pos.y = -21
	game.enemies.tick(0,95,0)
	game.hud.refresh(game.health,game.economy,game.seconds,game.enemies.boss,game.combat)
	await capture("boss")
	for i in range(50):
		game.projectiles.spawn("log",Vector3(0,1,-19),Vector2(0,-38),12,true)
		game.projectiles.tick(0.1,0)
	game.enemies.tick(0,95,0)
	await capture("victory")
	game.queue_free()
	await process_frame
	Art.materials.clear()
	Art.meshes.clear()
	await create_timer(0.15).timeout
	quit()
func capture(label: String) -> void:
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png("res://docs/screenshots/" + label + ".png")
	print("Captured ", label)
