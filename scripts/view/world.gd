class_name ForestWorld
extends Node3D
var chunks: Array[Node3D] = []
var rng := RandomNumberGenerator.new()
var environment: Environment
var sky_material: ProceduralSkyMaterial
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var night_amount := 0.0
var profile: Dictionary = LevelProfile.for_level(1)
var weather: WeatherFX
var road_material: ShaderMaterial
var reverse_road_material: ShaderMaterial
var ground_material: ShaderMaterial
var foliage_materials: Array[Dictionary] = []
var elapsed := 0.0
const CHUNK_SIZE := 40.0

func _ready() -> void:
	rng.seed = 705
	road_material = ShaderMaterial.new()
	var road_shader := Shader.new()
	road_shader.code = """shader_type spatial;
render_mode cull_back, depth_draw_opaque;
uniform sampler2D pavement : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rough_tex : filter_linear_mipmap, repeat_enable;
uniform vec2 texture_repeat = vec2(2.75,10.0);
uniform float wetness = 0.0;
uniform float snow = 0.0;
void fragment(){
 vec2 uv = UV*texture_repeat;
 vec3 stone = texture(pavement,uv).rgb*0.62;
 float grain = texture(rough_tex,uv).r;
 float cover = smoothstep(0.12,0.85,snow*(0.9+grain*0.35));
 ALBEDO = mix(stone*mix(1.0,0.66,wetness),vec3(0.76,0.82,0.86),cover);
 ROUGHNESS = mix(mix(grain,0.22,wetness),0.85,cover);
 NORMAL_MAP = texture(normal_tex,uv).rgb;
 NORMAL_MAP_DEPTH = 0.3*(1.0-cover*0.65);
}"""
	road_material.shader = road_shader
	road_material.set_shader_parameter("pavement",load("res://assets/textures/asphalt-color.jpg"))
	road_material.set_shader_parameter("normal_tex",load("res://assets/textures/asphalt-normal.jpg"))
	road_material.set_shader_parameter("rough_tex",load("res://assets/textures/asphalt-roughness.jpg"))
	ground_material = road_material.duplicate()
	ground_material.set_shader_parameter("pavement",load("res://assets/textures/ground-color.jpg"))
	ground_material.set_shader_parameter("normal_tex",load("res://assets/textures/ground-normal.jpg"))
	ground_material.set_shader_parameter("texture_repeat",Vector2(4.75,10))
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
	# Slightly lower reverse-view pavement cannot z-fight with moving chunks.
	var reverse_road := Art.box(self,Vector3(0,-0.28,110),Vector3(11,0.4,180),Color.WHITE)
	reverse_road_material = road_material.duplicate()
	reverse_road_material.set_shader_parameter("texture_repeat",Vector2(2.75,45))
	reverse_road.material_override = reverse_road_material
	for side in [-1,1]:
		for i in range(12):
			Art.tree(self,Vector3(side*(8+i%3*3),0,28+i*11),2.4+i%3*0.3)
	batch_static_chunk(self)
	weather = WeatherFX.new()
	add_child(weather)
	for mat in Art.materials.values():
		var base: Color = mat.albedo_color
		if base.g > base.r*1.08 and base.g>0.3:
			foliage_materials.append({"material":mat,"base":base})
	configure(1)
	set_time(0)

func build_chunk(chunk: Node3D, biome: int) -> void:
	var earth := Color("54564f")
	var grass: Color = [Color("486c43"),Color("60794e"),Color("41644f"),Color("7d7944")][biome%4]
	var road := Art.box(chunk,Vector3(0,-0.25,-20),Vector3(11,0.4,40),earth)
	road.material_override = road_material
	for side in [-1,1]:
		var floor_mesh := Art.box(chunk,Vector3(side*15,-0.45,-20),Vector3(19,0.7,40),grass)
		floor_mesh.material_override = ground_material
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
	weather.tick(delta)
	set_time(seconds)
	for chunk in chunks:
		chunk.position.z += Rules.run_speed(seconds)*delta
		if chunk.position.z > 60: chunk.position.z -= CHUNK_SIZE*chunks.size()

func set_time(seconds: float) -> void:
	# Dawn → daylight → dusk → moonlight → dawn, with readable ambient light.
	elapsed = seconds
	var phase := seconds / 220.0*TAU
	night_amount = 0.96 if bool(profile.night) else smoothstep(-0.2,0.7,-cos(phase))
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
	moon.light_energy = night_amount*0.65
	if weather != null:
		road_material.set_shader_parameter("wetness",weather.wetness)
		road_material.set_shader_parameter("snow",weather.snow_amount)
		ground_material.set_shader_parameter("wetness",weather.wetness)
		ground_material.set_shader_parameter("snow",weather.snow_amount)
		if reverse_road_material != null:
			reverse_road_material.set_shader_parameter("wetness",weather.wetness)
			reverse_road_material.set_shader_parameter("snow",weather.snow_amount)
		ground_material.set_shader_parameter("wetness",weather.wetness)
		ground_material.set_shader_parameter("snow",weather.snow_amount)
		environment.fog_density = 0.004 + (0.004+sin(seconds*0.07)*0.002 if profile.weather in ["fog","storm","blizzard"] else 0.0)
		sun.light_energy += weather.flash*1.8
		environment.ambient_light_energy += weather.flash*0.6

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

func configure(level: int) -> void:
	profile = LevelProfile.for_level(level)
	weather.configure(profile)
	weather.wetness = 1.0 if profile.wet else 0.0
	weather.snow_amount = 1.0 if profile.snow else 0.0
	for entry in foliage_materials:
		entry.material.albedo_color = entry.base.lerp(Color("d0dfe2"),0.8 if profile.snow else 0.0)
	set_time(0)
