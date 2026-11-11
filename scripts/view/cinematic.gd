class_name OpeningCinematic
extends Node3D
signal finished
signal dam_creaked
var camera: Camera3D
var hero: Node3D
var family: Node3D
var elapsed := 0.0
var active := false
var duration := 12.0
var fill: OmniLight3D
var mother: Node3D
var child: Node3D
var tears: Array[MeshInstance3D] = []

func setup(value: Camera3D, player: Node3D) -> void:
	camera = value
	hero = player
	family = Node3D.new()
	add_child(family)
	fill = OmniLight3D.new()
	fill.light_color = Color("ffe8c8")
	fill.light_energy = 1.3
	fill.omni_range = 12
	family.add_child(fill)
	var water := Art.box(family,Vector3(-1,0.025,4),Vector3(13,0.12,8),Color("397e8a"))
	water.material_override = Art.material(Color("397e8a"))
	for row in range(3):
		for column in range(6):
			var log_node := Art.cylinder(family,Vector3(-4+column*1.5,0.18+row*0.28,3.0+sin(column)*0.12),0.19,1.9,Art.BROWN)
			log_node.rotation.z = PI/2 + (0.12 if row%2==0 else -0.1)
	mother = Characters.beaver(false)
	family.add_child(mother)
	mother.position = Vector3(-1.7,0,2.2)
	mother.rotation.y = PI
	mother.rotation.x = -0.22
	mother.scale = Vector3.ONE*0.88
	child = Characters.beaver(false)
	family.add_child(child)
	child.position = Vector3(-0.6,0.5,2.35)
	child.rotation.y = PI
	child.rotation.x = -0.2
	child.scale = Vector3.ONE*0.5
	# Outstretched paws press against the failing dam.
	for body in [mother,child]:
		for side in [-1,1]:
			Art.ball(body,Vector3(side*0.3,0.9,-0.75),Vector3(0.22,0.22,0.45),Art.BROWN)
			var tear := Art.ball(body,Vector3(side*0.28,1.47,-0.58),Vector3(0.085,0.20,0.07),Color("5bbde8"))
			tear.material_override = Art.material(Color("6ed5ff"),true)
			tears.append(tear)
			var brow := Art.box(body,Vector3(side*0.27,1.72,-0.49),Vector3(0.18,0.04,0.045),Color("4f3529"))
			brow.rotation.z = side*0.5
	family.visible = false

func start() -> void:
	elapsed = 0
	active = true
	family.visible = true
	hero.rotation = Vector3.ZERO
	hero.position = Vector3(1.4,0,1.0)
	update_camera(0)

func tick(delta: float) -> void:
	if not active: return
	elapsed += delta
	if fmod(elapsed,3.0) < delta: dam_creaked.emit()
	for i in range(tears.size()):
		tears[i].position.y = 1.51 - fmod(elapsed*0.38 + i*0.1,0.25)
	mother.position.y = sin(elapsed*3)*0.025
	child.position.y = 0.5 + sin(elapsed*4)*0.025
	var progress := clampf((elapsed-2)/6,0,1)
	hero.position = Vector3(1.4*(1-progress),absf(sin(elapsed*8))*0.04,1.0-progress)
	hero.get_node("FootL").rotation.x = sin(elapsed*8)*0.25
	hero.get_node("FootR").rotation.x = -sin(elapsed*8)*0.25
	update_camera(elapsed)
	if elapsed >= duration: complete()

func update_camera(time: float) -> void:
	fill.position = camera.position + Vector3.UP
	if time < 3:
		camera.position = Vector3(-4.5,2.6,6.5)
		camera.look_at(Vector3(-1.2,1.0,1.8))
	elif time < 9:
		var angle := (time-3)/6*TAU
		camera.position = hero.position + Vector3(sin(angle)*5.4,2.7,cos(angle)*5.4)
		camera.look_at(hero.position+Vector3(0,1.0,0))
	else:
		var weight := smoothstep(9.0,12.0,time)
		camera.position = Vector3(0,2.7,5.4).lerp(Vector3(0,10.5,14.5),weight)
		camera.look_at(Vector3(0,1,0).lerp(Vector3(0,0,-22),weight))

func complete() -> void:
	if not active: return
	active = false
	family.visible = false
	hero.position = Vector3.ZERO
	camera.position = Vector3(0,10.5,14.5)
	camera.look_at(Vector3(0,0,-22))
	finished.emit()

func cancel() -> void:
	active = false
	family.visible = false
