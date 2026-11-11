extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_size = Vector2i(432,864)
	var game: BeaverGame = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	game.audio.muted = true
	game.seconds = 58
	game.gates.schedule_index = 4
	game.health = Health.new(10000)
	for i in range(12): game.enemies.spawn(i % 3,(i % 5 - 2) * 2,-10-i*3)
	game.gates.spawn(58)
	game.economy.money = 500
	game.purchase("fan")
	var times: Array[float] = []
	var calls: Array[float] = []
	var previous := Time.get_ticks_usec()
	for i in range(660):
		await process_frame
		var now := Time.get_ticks_usec()
		if i >= 60:
			times.append((now - previous)/1000.0)
			calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		previous = now
	times.sort()
	var mean := 0.0
	var draw_mean := 0.0
	for value in times: mean += value / times.size()
	for value in calls: draw_mean += value / calls.size()
	var result := {"platform":"Linux x86_64 AMD Lucienne Mesa 26.2.6, Compatibility",
		"viewport":"432x864", "samples":times.size(),"mean_frame_ms":mean,"p95_frame_ms":times[int(times.size()*0.95)],
		"max_frame_ms":times.back(),"average_draw_calls":draw_mean,
		"note":"Graphical fixture with 12 initial enemies, fan and gate; HP raised to avoid ending profiling. Not Android or a human run."}
	var file := FileAccess.open("res://builds/profile.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  "))
	print(JSON.stringify(result))
	game.queue_free()
	await process_frame
	Art.materials.clear()
	Art.meshes.clear()
	await create_timer(0.15).timeout
	quit()
