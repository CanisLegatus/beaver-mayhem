class_name WeatherFX
extends Node3D
signal thunder
var kind := "temperate"
var wetness := 0.0
var snow_amount := 0.0
var flash := 0.0
var clock := 0.0
var thunder_timer := 5.0
var rng := RandomNumberGenerator.new()
var batch: MultiMeshInstance3D
var drops: Array[Vector3] = []
var bolt: Node3D
var cold_overlay: ColorRect

func _ready() -> void:
	batch = MultiMeshInstance3D.new()
	add_child(batch)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.025,0.65)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = 420
	batch.multimesh = multi
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.55,0.75,0.9,0.48)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	batch.material_override = mat
	for i in range(420): drops.append(Vector3(rng.randf_range(-10,10),rng.randf_range(1,15),rng.randf_range(-55,8)))
	bolt = Node3D.new()
	add_child(bolt)
	for i in range(7):
		var line := Art.box(bolt,Vector3(-15+(i%2)*2,30-i*4,-65),Vector3(0.15,5,0.15),Color("c7e8ff"))
		line.rotation.z = 0.4 if i%2==0 else -0.4
		line.material_override = Art.material(Color("d0e9ff"),true)
	bolt.hide()

func configure(profile: Dictionary) -> void:
	kind = profile.weather
	clock = 0
	flash = 0
	thunder_timer = 5
	batch.visible = kind in ["rain","storm","snow","blizzard"]
	var snow := kind in ["snow","blizzard"]
	var quad: QuadMesh = batch.multimesh.mesh
	quad.size = Vector2(0.085,0.085) if snow else Vector2(0.025,0.65)
	batch.multimesh.visible_instance_count = 420 if kind in ["storm","blizzard"] else 240
	bolt.hide()

func tick(delta: float) -> void:
	clock += delta
	wetness = move_toward(wetness,1.0 if kind in ["rain","storm"] else 0.0,delta*0.4)
	snow_amount = move_toward(snow_amount,1.0 if kind in ["snow","blizzard"] else 0.0,delta*0.16)
	flash = maxf(0,flash-delta*3.5)
	bolt.visible = flash > 0.45
	if kind == "storm":
		thunder_timer -= delta
		if thunder_timer <= 0:
			flash = 1
			thunder_timer = rng.randf_range(7,13)
			thunder.emit()
	if not batch.visible: return
	var snowy := kind in ["snow","blizzard"]
	for i in range(drops.size()):
		var pos := drops[i]
		pos.y -= delta*(2 if snowy else 26)
		pos.x += delta*(sin(clock+i)*0.5 if snowy else -3.0)
		if pos.y < 0:
			pos.y += 15
			pos.x = rng.randf_range(-10,10)
		if absf(pos.x)>12: pos.x = -signf(pos.x)*10
		drops[i] = pos
		batch.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,pos))

func clear() -> void:
	flash = 0
	bolt.hide()
