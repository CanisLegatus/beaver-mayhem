extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_size = Vector2i(432,864)
	var game: BeaverGame = load("res://scenes/main.tscn").instantiate()
	game.progression = Progression.new("user://test-capture-v3.cfg")
	game.progression.unlocked = 2
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start_run()
	game.current_level = 1
	game.seconds = 40
	game.gates.schedule_index = 8
	game.enemies.spawn(0,-2,-14)
	game.enemies.spawn(1,2,-22)
	game.enemies.tick(0,40,0)
	game.hud.refresh(game.health,game.economy,40,{},game.combat)
	await capture("opaque-back")
	game.hazards.truck(true)
	game.hazards.tick(2.7,0,12)
	await capture("truck")
	game.start_run()
	game.enemies.spawn_boss()
	game.enemies.tick(0,150,0)
	game.hud.refresh(game.health,game.economy,150,game.enemies.boss,game.combat)
	game.hazards.lane_strike([-2,0],"earth",2,18)
	game.hazards.tick(1,4,15)
	await capture("dozer")
	game.select_level(2)
	game.action_camera.tick(4)
	await capture("moonfall")
	game.action_camera.tick(5)
	await capture("uprising")
	game.action_camera.complete()
	game.seconds = 45
	game.gates.schedule_index = 8
	for i in range(45): game.enemies.spawn_zombie(i%4,(i%5-2)*2+sin(i)*0.2,-8-i*1.5)
	game.enemies.tick(0,45,0)
	game.world.weather.tick(0.1)
	game.world.set_time(45)
	game.hud.refresh(game.health,game.economy,45,{},game.combat)
	await capture("horde")
	game.start_run()
	game.enemies.chapter = 2
	game.enemies.spawn_boss()
	game.enemies.tick(0,150,0)
	game.hud.refresh(game.health,game.economy,150,game.enemies.boss,game.combat)
	await capture("titan")
	game.begin_qte(0,"house")
	await capture("qte")
	game.qte.press(0)
	game.action_camera.tick(0.8)
	await capture("dodge")
	game.action_camera.complete()
	game.start_run()
	game.world.configure(4)
	game.world.weather.tick(0.1)
	game.world.set_time(12)
	game.hud.set_weather(game.world.weather.snow_amount)
	game.hud.refresh(game.health,game.economy,12,{},game.combat)
	await capture("snow")
	game.show_map()
	await capture("roadmap-v3")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
func capture(label: String) -> void:
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+label+".png")
	print("Captured ",label)
