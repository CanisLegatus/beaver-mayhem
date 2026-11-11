extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_size = Vector2i(432,864)
	var results: Array=[]
	for chapter in [1,2]:
		var game: BeaverGame=load("res://scenes/main.tscn").instantiate()
		game.progression=Progression.new("user://profile-v3.cfg")
		root.add_child(game)
		await process_frame
		game.set_physics_process(false)
		game.current_level=chapter
		game.start_run()
		game.audio.muted=true
		game.health=Health.new(10000)
		game.seconds=70
		game.gates.schedule_index=8
		if chapter==2:
			for i in range(64): game.enemies.spawn_zombie(i%4,(i%5-2)*2,-6-i*1.2)
		else:
			for i in range(16): game.enemies.spawn(i%3,(i%5-2)*2,-6-i*3.2)
		game.economy.money=500
		game.economy.buy("fan")
		var samples: Array[float]=[]
		var calls:=0.0
		var previous:=Time.get_ticks_usec()
		for frame in range(360):
			game._physics_process(1.0/60)
			await process_frame
			var now:=Time.get_ticks_usec()
			if frame>=60:
				samples.append((now-previous)/1000.0)
				calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)/300
			previous=now
		samples.sort()
		var mean:=0.0
		for sample in samples: mean+=sample/samples.size()
		var row={"chapter":chapter,"samples":300,"mean_frame_ms":mean,"p95_frame_ms":samples[285],"max_frame_ms":samples.back(),"mean_draw_calls":calls}
		results.append(row)
		print(JSON.stringify(row))
		game.queue_free()
		await process_frame
	var report={"platform":"Linux AMD Lucienne / Mesa / Compatibility","viewport":"432x864","fixtures":results,"note":"Dense fixtures: 16 human enemies or 64 zombies plus storm, real rendering. Test-only HP avoids early exit. Not Android performance."}
	var file:=FileAccess.open("res://builds/profile-v3.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	await create_timer(0.2).timeout
	quit()
