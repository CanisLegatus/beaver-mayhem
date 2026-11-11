class_name ActionCamera
extends Node3D
signal finished(mode: String)
signal sound_requested(key: String)
signal burst_requested(pos: Vector3, color: Color, count: int)
var camera: Camera3D
var hero: Node3D
var mode := ""
var elapsed := 0.0
var scenery: Node3D
var prop: Node3D
var moon: Node3D
var rising: Array[Node3D] = []
var shockwave: MeshInstance3D
var dust_clouds: Array[Node3D] = []
var impacted := false
var direction := 0
var variant := 0
var origin_x := 0.0

func setup(view: Camera3D, player: Node3D) -> void:
	camera = view
	hero = player

func start_moon() -> void:
	clear()
	mode = "moon"
	scenery = Node3D.new()
	add_child(scenery)
	moon = Node3D.new()
	scenery.add_child(moon)
	var orb := Art.ball(moon,Vector3.ZERO,Vector3.ONE*22,Color("bec6b8"))
	var lunar := StandardMaterial3D.new()
	lunar.albedo_texture = load("res://assets/textures/moon.jpg")
	lunar.roughness = 1
	orb.material_override = lunar
	var ring := TorusMesh.new()
	ring.inner_radius = 0.85
	ring.outer_radius = 1.0
	shockwave = Art.shape(scenery,ring,Vector3(-5,0.3,-70),Color("a9d9eb"))
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.albedo_color = Color(0.5,0.8,1,0.6)
	shockwave.material_override = glow
	shockwave.hide()
	for i in range(5):
		var cloud := Sprite3D.new()
		scenery.add_child(cloud)
		cloud.texture = load("res://assets/vfx/smoke_01.png")
		cloud.pixel_size = 0.035
		cloud.position = Vector3(-15+i*5,1,-72+i%2*4)
		cloud.modulate = Color(0.6,0.7,0.8,0.6)
		var smoke := StandardMaterial3D.new()
		smoke.albedo_texture = cloud.texture
		smoke.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smoke.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		smoke.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smoke.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		smoke.vertex_color_use_as_albedo = true
		smoke.disable_fog = true
		smoke.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		cloud.material_override = smoke
		cloud.hide()
		dust_clouds.append(cloud)
	for i in range(14):
		var zombie := HazardArt.zombie(i%4)
		scenery.add_child(zombie)
		zombie.position = Vector3((i%5-2)*1.8,-2,-12-i*2.3)
		rising.append(zombie)
	sound_requested.emit("warning")
	update_moon(0)

func start_dodge(input_direction: int, camera_style: int, object_kind: String, x: float) -> void:
	clear()
	mode = "dodge"
	direction = input_direction
	variant = camera_style
	origin_x = x
	prop = HazardArt.house() if object_kind == "house" else HazardArt.tree_weapon()
	add_child(prop)
	sound_requested.emit("dodge")

func tick(delta: float) -> void:
	if mode.is_empty(): return
	elapsed += delta
	if mode == "anticipate":
		prop.position = Vector3(0,8,-38+minf(elapsed/1.6,1)*17)
		prop.rotation.z += delta*0.35
	elif mode == "moon":
		update_moon(elapsed)
		if elapsed >= 14: complete()
	elif mode == "dodge":
		var p := clampf(elapsed/1.8,0,1)
		var side := -1.0 if direction == 0 else 1.0
		if direction == 1: side = -1.0 if variant%2 == 0 else 1.0
		hero.position.x = clampf(origin_x+side*sin(p*PI)*2.0,-4.5,4.5)
		hero.position.y = sin(p*PI)*0.32
		hero.rotation.z = -side*sin(p*PI)*0.65
		if direction == 1: hero.scale.y = 1-sin(p*PI)*0.55
		prop.position = Vector3(origin_x+sin(p*PI)*2,6*(1-p),-22+40*p)
		prop.rotation += Vector3(0.4,0.3,1.5)*delta
		match variant:
			0: camera.position = Vector3(hero.position.x+4.5,2.6,5.8)
			1: camera.position = Vector3(hero.position.x-4.8,1.7+sin(p*PI),3.8)
			_: camera.position = Vector3(hero.position.x+sin(p*PI)*4,6.2,5)
		camera.look_at(hero.position+Vector3(0,1,-1))
		camera.fov = 66
		if p >= 1: complete()

func update_moon(time: float) -> void:
	var fall := smoothstep(2.0,7.0,time)
	moon.position = Vector3(-5,42*(1-fall)+2,-75)
	moon.rotation.z = time*0.08
	if time < 7:
		camera.position = Vector3(4,3.2,9)
		camera.look_at(Vector3(-4,lerpf(20,5,fall),-65))
	elif time < 11:
		if not impacted:
			impacted = true
			moon.hide()
			burst_requested.emit(Vector3(-5,4,-70),Color("b7daeb"),80)
			sound_requested.emit("moon_impact")
		shockwave.show()
		shockwave.scale = Vector3(1+(time-7)*10,0.12,1+(time-7)*10)
		for i in range(dust_clouds.size()):
			dust_clouds[i].show()
			dust_clouds[i].position.y = 1+(time-7)*(1.4+i*0.3)
			dust_clouds[i].scale = Vector3.ONE*(0.6+i*0.1+(time-7)*0.3)
		camera.position = Vector3(sin(time*23)*0.35*(11-time)/4,3.5+sin(time*31)*0.1,6)
		camera.look_at(Vector3(0,1.5,-24))
		for i in range(rising.size()): rising[i].position.y = lerpf(-2.0,0.0,smoothstep(7.0+i*0.07,9.0+i*0.07,time))
	else:
		var p := smoothstep(11,14,time)
		camera.position = Vector3(0,3.5,6).lerp(Vector3(0,10.5,14.5),p)
		camera.look_at(Vector3(0,1.5,-24).lerp(Vector3(0,0,-22),p))

func complete() -> void:
	var previous := mode
	clear()
	reset_camera()
	finished.emit(previous)

func reset_camera() -> void:
	hero.rotation = Vector3.ZERO
	hero.scale = Vector3.ONE
	hero.position = Vector3(origin_x,0,0) if mode == "dodge" else Vector3.ZERO
	camera.position = Vector3(0,10.5,14.5)
	camera.look_at(Vector3(0,0,-22))
	camera.fov = 58

func clear() -> void:
	if is_instance_valid(scenery): scenery.queue_free()
	if is_instance_valid(prop): prop.queue_free()
	scenery = null
	prop = null
	moon = null
	rising.clear()
	dust_clouds.clear()
	shockwave = null
	mode = ""
	elapsed = 0
	impacted = false

func prepare_throw(object_kind: String) -> void:
	clear()
	mode = "anticipate"
	prop = HazardArt.house() if object_kind == "house" else HazardArt.tree_weapon()
	add_child(prop)
	prop.position = Vector3(0,8,-38)
