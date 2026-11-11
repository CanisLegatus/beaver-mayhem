class_name ForestWorld
extends Node3D
var chunks: Array[Node3D] = []
var rng := RandomNumberGenerator.new()
var environment: Environment
var sky_material: ProceduralSkyMaterial
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var night_amount := 0.0
const CHUNK_SIZE := 40.0

func _ready() -> void:
	rng.seed = 705
	var world_environment := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("457f9b")
	sky_material.sky_horizon_color = Color("b8cbbb")
	sky_material.ground_bottom_color = Color("344d43")
	sky_material.ground_horizon_color = Color("b8cbbb")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("bcd0d1")
	environment.ambient_light_energy = 0.4
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = true
	environment.fog_light_color = Color("a8bcaf")
	environment.fog_density = 0.004
	environment.fog_sky_affect = 0.15
	world_environment.environment = environment
	add_child(world_environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-24,0)
	sun.light_color = Color("ffdfad")
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 85
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-50,130,0)
	moon.light_color = Color("87b7e8")
	moon.light_energy = 0
	add_child(moon)
	for i in range(int(Rules.config.world_chunk_count)):
		var chunk := Node3D.new()
		add_child(chunk)
		chunks.append(chunk)
		chunk.position.z = -i*CHUNK_SIZE+20
		build_chunk(chunk,i)
		batch_static_chunk(chunk)
	for side in [-1,1]:
		for i in range(6):
			var hill := Art.ball(self,Vector3(side*(24+i*11),1,-90-i*24),Vector3(30,18+i*7,42),Color("587b65"))
			hill.material_override = Sculpt.surface(Color("506e5d"))
		# Far treeline hides object births well beyond the playable encounter zone.
		for i in range(18): Art.tree(self,Vector3(side*(6+i*1.8),0,-140-rng.randf()*20),rng.randf_range(2,4))
	# Complete the reverse view for the 360-degree opening camera.
	Art.box(self,Vector3(0,-0.47,100),Vector3(140,0.5,200),Color("486c43"))
	Art.box(self,Vector3(0,-0.25,100),Vector3(11,0.4,200),Color("928063"))
	for side in [-1,1]:
		for i in range(12):
			Art.tree(self,Vector3(side*(8+i%3*3),0,28+i*11),2.4+i%3*0.3)
	batch_static_chunk(self)
	set_time(0)

func build_chunk(chunk: Node3D, biome: int) -> void:
	var earth: Color = [Color("928063"),Color("998773"),Color("8c8474"),Color("aa885a")][biome%4]
	var grass: Color = [Color("486c43"),Color("60794e"),Color("41644f"),Color("7d7944")][biome%4]
	var road := Art.box(chunk,Vector3(0,-0.25,-20),Vector3(11,0.4,40),earth)
	road.material_override = Sculpt.surface(earth)
	for side in [-1,1]:
		Art.box(chunk,Vector3(side*15,-0.45,-20),Vector3(19,0.7,40),grass)
		Art.box(chunk,Vector3(side*5.25,-0.04,-20),Vector3(0.1,0.05,40),Color("bfac74"))
		for j in range(7):
			var p := Vector3(side*rng.randf_range(7,19),0,-j*6.0)
			if biome%3==0:
				broadleaf(chunk,p,rng.randf_range(1.8,3.1),Color("70783b") if j%2==0 else Color("416c40"))
			else: Art.tree(chunk,p,rng.randf_range(1.5,3.0))
			var rock := Art.ball(chunk,Vector3(side*rng.randf_range(6,12),0.25,-j*5.7-2),Vector3(0.9,0.7,1.3),Color("737870"))
			rock.rotation = Vector3(rng.randf(),rng.randf()*PI,rng.randf())
			for k in range(3):
				var stem := Vector3(side*rng.randf_range(5.7,8),0.1,-j*6-k)
				Art.cylinder(chunk,stem,0.06,0.4,grass.lightened(0.13),0)
				if biome%2==0: Art.ball(chunk,stem+Vector3.UP*0.2,Vector3.ONE*0.13,Color("d3bd80") if k%2==0 else Color("b77e8f"))
		if biome%3==1:
			Art.box(chunk,Vector3(side*10,-0.06,-20),Vector3(2.8,0.06,40),Color("4a8b98"))
			for j in range(5): Art.box(chunk,Vector3(side*10,0.0,-j*8),Vector3(2.3,0.02,0.1),Color("91b6b2"))
		if biome%3==2:
			for j in range(4):
				Art.ball(chunk,Vector3(side*11,0,-j*11),Vector3(5,4+j%2,7),Color("797b71"))
		var fallen := Art.cylinder(chunk,Vector3(side*7.5,0.3,-15),0.3,3.2,Art.BROWN)
		fallen.rotation.z = PI/2
		Art.cylinder(chunk,Vector3(side*6.4,0.3,-27),0.4,0.6,Art.BROWN)
		Art.cylinder(chunk,Vector3(side*6.4,0.61,-27),0.38,0.02,Art.TAN)
	for lane in [-3,-1,1,3]:
		for j in range(10): Art.box(chunk,Vector3(lane,0.012,-j*4.0),Vector3(0.045,0.02,1),Color("c6b590"))

func broadleaf(parent: Node3D, pos: Vector3, height: float, color: Color) -> void:
	Art.cylinder(parent,pos+Vector3.UP*height*0.6,height*0.09,height*1.2,Art.BROWN)
	for i in range(5):
		var angle := i*TAU/5
		Art.ball(parent,pos+Vector3(cos(angle)*height*0.4,height*1.35,sin(angle)*height*0.4),Vector3(height,height*0.8,height),color.lightened(i*0.015))

func scroll(delta: float, seconds: float = 0.0) -> void:
	set_time(seconds)
	for chunk in chunks:
		chunk.position.z += Rules.run_speed(seconds)*delta
		if chunk.position.z > 60: chunk.position.z -= CHUNK_SIZE*chunks.size()

func set_time(seconds: float) -> void:
	# Dawn → daylight → dusk → moonlight → dawn, with readable ambient light.
	var phase := seconds / float(Rules.config.cycle_seconds)*TAU
	night_amount = smoothstep(-0.2,0.7,-cos(phase))
	var dusk := pow(1.0-absf(cos(phase)),4.0)
	sky_material.sky_top_color = Color("527f9c").lerp(Color("08132b"),night_amount)
	sky_material.sky_horizon_color = Color("b8cbbb").lerp(Color("293753"),night_amount).lerp(Color("b07e71"),dusk*0.45)
	sky_material.ground_horizon_color = sky_material.sky_horizon_color
	environment.fog_light_color = sky_material.sky_horizon_color
	environment.ambient_light_color = Color("c5d0c1").lerp(Color("7b9ec0"),night_amount)
	environment.ambient_light_energy = lerpf(0.38,0.45,night_amount)
	sun.light_energy = lerpf(0.8,0.04,night_amount)
	sun.light_color = Color("ffdfad").lerp(Color("f2b580"),dusk)
	sun.rotation_degrees.x = -42+sin(phase)*22
	moon.light_energy = night_amount*0.55

func batch_static_chunk(chunk: Node3D) -> void:
	var groups: Dictionary = {}
	for child in chunk.get_children():
		if child is MeshInstance3D:
			var key := str(child.mesh.get_instance_id())+"/"+str(child.material_override.get_instance_id())
			if not groups.has(key): groups[key] = []
			groups[key].append(child)
	for group in groups.values():
		var batch := MultiMeshInstance3D.new()
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = group[0].mesh
		multi.instance_count = group.size()
		for i in range(group.size()): multi.set_instance_transform(i,group[i].transform)
		batch.multimesh = multi
		batch.material_override = group[0].material_override
		chunk.add_child(batch)
		for child in group: child.free()
