extends SceneTree
var count := 0
var errors := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	count += 1
	if not ok:
		errors += 1
		printerr("FAIL: ",label)
func run() -> void:
	geometry()
	qte_rules()
	var game: BeaverGame = load("res://scenes/main.tscn").instantiate()
	game.progression = Progression.new("user://v3-tests.cfg")
	game.progression.unlocked = 2
	root.add_child(game)
	await process_frame
	game.enemies.rng.seed=42
	game.set_physics_process(false)
	game.start_run()
	var material_id := game.world.road_material.get_instance_id()
	game.world.set_time(35)
	var first_light := game.world.sun.light_energy
	game.world.set_time(35.016)
	check(absf(first_light-game.world.sun.light_energy)<0.01,"continuous sunlight")
	game.world.scroll(0.1,40)
	check(game.world.road_material.get_instance_id()==material_id,"road material stable through time and scroll")
	game.world.configure(2)
	check(game.world.night_amount>0.9 and game.world.weather.kind=="storm","chapter 2 starts stormy night")
	game.world.configure(4)
	check(game.world.weather.snow_amount==1 and game.world.weather.batch.visible,"chapter 4 fixed snow")
	game.world.configure(5)
	check(game.world.weather.kind=="blizzard","chapter 5 cold set")
	game.world.configure(1)
	check(game.world.weather.kind=="temperate" and not game.world.weather.batch.visible,"chapter 1 temperate")
	game.hazards.lane_strike([0],"earth",1.8,15)
	game.hazards.tick(1.7,0,10)
	check(game.health.hp==100,"strike windup cannot hurt")
	game.hazards.tick(0.11,0,10)
	game.hazards.tick(0.1,0,10)
	check(game.health.hp==85,"announced strike hits once")
	game.hazards.clear()
	game.hazards.lane_strike([0],"earth",1.8,15)
	game.hazards.tick(1.81,4,10)
	check(game.health.hp==85,"safe lane avoids strike")
	game.start_run()
	var traffic := game.hazards.truck(true)
	game.hazards.tick(1.99,0,12)
	check(game.health.hp==100,"truck warning protects before crossing")
	for i in range(150): game.hazards.tick(1.0/60,0,12)
	check(game.health.hp==76,"physical traffic collision once")
	game.start_run()
	game.hazards.truck(false)
	for i in range(300): game.hazards.tick(1.0/60,4.6,12)
	check(game.health.hp==100 and game.hazards.hazards.is_empty(),"outer lane avoids truck and truck expires")
	game.hazards.comet()
	game.hazards.tick(3.1,4.6,12)
	check(game.hazards.comet_used and game.hazards.hazards.size()==3,"comet creates three warned shard lanes")
	var size_before := game.hazards.hazards.size()
	game.hazards.comet()
	check(game.hazards.hazards.size()==size_before,"comet cannot repeat in same run")
	game.start_run()
	game.current_level=2
	game.enemies.chapter=2
	game.enemies.director(0.5,0,false)
	check(game.enemies.enemies.size()>=5,"horde spawns group")
	for enemy in game.enemies.enemies: check(enemy.get("zombie",false),"chapter 2 contains no human shooters")
	for i in range(150): game.enemies.director(1,60,false)
	check(game.enemies.enemies.size()==int(Rules.config.enemy_cap),"horde cap enforced")
	game.enemies.clear()
	var shambler := game.enemies.spawn_zombie(0,0,-10)
	var runner := game.enemies.spawn_zombie(1,2,-10)
	var crawler := game.enemies.spawn_zombie(2,-2,-10)
	game.enemies.tick(0.1,30,4,false)
	check(runner.pos.y>shambler.pos.y and crawler.pos.y<shambler.pos.y,"runner faster, crawler slower")
	check(crawler.visual.scale.y<0.5,"crawler low silhouette")
	game.enemies.tick(5,30,4,false)
	check(game.projectiles.shots.is_empty(),"non-spitting horde cannot shoot")
	game.enemies.clear()
	var spitter := game.enemies.spawn_zombie(3,0,-20)
	spitter.attack_timer=0.1
	game.enemies.tick(0.2,30,4,false)
	check(game.projectiles.shots.size()==1 and game.projectiles.shots[0].kind=="spit","rare spitter attack")
	game.start_run()
	var walker := game.enemies.spawn_zombie(0,0,-0.01)
	var money := game.economy.money
	game.enemies.tick(0.1,30,0)
	game.enemies.tick(0.1,30,0)
	check(game.health.hp==97,"zombie contact damage once")
	walker.pos.y=3.5
	game.enemies.tick(0,30,0)
	game.enemies.tick(0,30,0)
	check(game.economy.money==money-2,"zombie breach penalty once")
	game.current_level=1
	game.start_run()
	game.enemies.spawn_boss()
	var boss: Dictionary = game.enemies.boss
	var position: Vector2 = boss.pos
	game.enemies.tick(3,155,0)
	check(boss.pos==position,"dozer does not advance passively")
	check(boss.radius<3 and boss.health.maximum==1500,"smaller stronger dozer")
	var driver: BossCombat = game.enemies.boss_driver
	driver.clock=0
	driver.tick(0.01,0,boss,game.projectiles,game.hazards)
	check(game.projectiles.shots.size()>=2 and game.projectiles.shots.size()<=4,"boss rocket fan 2 to 4")
	game.projectiles.clear()
	driver.clock=0
	driver.tick(0.01,0,boss,game.projectiles,game.hazards)
	check(driver.phase=="windup_charge" and not game.hazards.hazards.is_empty(),"charge telegraphed")
	for i in range(250):
		driver.tick(1.0/60,0,boss,game.projectiles,game.hazards)
		game.hazards.tick(1.0/60,0,15)
	check(game.health.hp==70,"ram causes one real damage event")
	game.current_level=2
	game.start_run()
	game.enemies.spawn_boss()
	check(game.enemies.boss.health.maximum==2100,"titan health")
	game.enemies.boss_driver.clock=0
	game.enemies.boss_driver.tick(0.01,0,game.enemies.boss,game.projectiles,game.hazards)
	check(game.state=="qte","titan throw triggers QTE")
	var frozen := game.seconds
	game.toggle_pause()
	var remaining := game.qte.remaining
	game._physics_process(1)
	check(game.qte.remaining==remaining,"paused QTE deadline frozen")
	game.hud.qte_pressed.emit(game.qte.expected)
	check(game.qte.active,"paused QTE buttons cannot resolve challenge")
	game.toggle_pause()
	game.qte.press(game.qte.expected)
	check(game.state=="dodge_movie","success enters cinematic dodge")
	game._physics_process(0.8)
	check(game.seconds==frozen and game.camera.fov==66,"dodge cinematic freezes combat and changes lens")
	game._physics_process(1.1)
	check(game.state=="playing" and game.camera.fov==58 and game.beaver.scale==Vector3.ONE,"dodge restores camera and player")
	game.begin_qte(0,"tree")
	var hp := game.health.hp
	game.qte.press(2)
	game.qte.press(2)
	check(game.health.hp==hp-28 and game.state=="playing","failed QTE damage exactly once")
	game.select_level(2)
	check(game.action_camera.mode=="moon" and game.state=="cinematic","moonfall starts chapter two")
	game._physics_process(8)
	check(game.seconds==0 and game.action_camera.impacted,"moon impact while run frozen")
	game.action_camera.complete()
	check(game.state=="playing" and game.camera.position.is_equal_approx(Vector3(0,10.5,14.5)),"moonfall restores gameplay")
	game.begin_qte(0,"house")
	game.qte.press(0)
	game.action_camera.tick(0.5)
	game.start_run()
	check(game.camera.fov == 58 and game.beaver.scale == Vector3.ONE,"restart during dodge restores camera/body")
	check(game.hazards.hazards.is_empty() and not game.qte.active and game.action_camera.mode.is_empty(),"restart clears every new subsystem")
	var explosion_count: Array = [0]
	game.projectiles.rocket_exploded.connect(func(_p: Vector3) -> void: explosion_count[0]+=1)
	var old_rocket := game.projectiles.spawn("rocket",Vector3(0,1,-20),Vector2(0,20),12,false)
	old_rocket.ignited=true
	game.start_run()
	check(explosion_count[0]==0,"restart cleanup does not explode old rockets")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("V3 TEST RESULT: %d checks, %d failures" % [count,errors])
	quit(1 if errors else 0)

func geometry() -> void:
	var root := Node3D.new()
	var visual := Sculpt.rings(root,"winding_test",[[0,0.5,0.5],[1,0.5,0.5]],Color.WHITE)
	var arrays := visual.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for i in range(vertices.size()):
		var radial := Vector3(vertices[i].x,0,vertices[i].z)
		check(normals[i].dot(radial)>0,"sculpt normals point outward")
	check(not visual.material_override.shader.code.contains("ALPHA"),"body shader opaque")
	root.free()

func qte_rules() -> void:
	var q := DodgeQTE.new()
	var results: Array = []
	q.resolved.connect(func(ok: bool) -> void: results.append(ok))
	q.begin(0,"tree")
	var first := q.camera_variant
	q.press(0)
	q.press(0)
	check(results==[true],"QTE resolves once")
	q.begin(2,"house")
	check(q.camera_variant!=first,"camera variant does not repeat")
	q.tick(1.61)
	check(results==[true,false],"missed deadline fails")
