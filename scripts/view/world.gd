class_name ForestWorld
extends Node3D
var chunks: Array[Node3D] = []
var rng := RandomNumberGenerator.new()
const CHUNK_SIZE := 32.0

func _ready() -> void:
	rng.seed = 705
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("84bdbe")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d0e0c4")
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -25, 0)
	sun.light_color = Color("ffe3b0")
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65.0
	add_child(sun)
	for i in range(5):
		var chunk := Node3D.new()
		add_child(chunk)
		chunks.append(chunk)
		chunk.position.z = -i * CHUNK_SIZE + 16
		Art.box(chunk, Vector3(0, -0.25, -16), Vector3(11, 0.4, 32), Color("c2ac7b"))
		for side in [-1, 1]:
			Art.box(chunk, Vector3(side * 13, -0.45, -16), Vector3(15, 0.7, 32), Color("619a65"))
			Art.box(chunk, Vector3(side * 5.3, -0.03, -16), Vector3(0.16, 0.08, 32), Art.GOLD)
			for j in range(6):
				var pos := Vector3(side * rng.randf_range(7, 18), 0, -j * 5.5)
				Art.tree(chunk, pos, rng.randf_range(1.4, 2.7))
				Art.ball(chunk, Vector3(side * rng.randf_range(6, 11), 0.2, -j * 5.5 - 2), Vector3(0.7, 0.5, 1), Color("889585"))
				Art.cylinder(chunk, Vector3(side * 6.2, 0.15, -j * 5.5), 0.27, 0.3, Art.TAN)
				Art.cylinder(chunk, Vector3(side * 5.9, 0.15, -j * 5.5 - 2), 0.25, 0.4, Color("8bc071"), 0.0)
		for lane in [-3, -1, 1, 3]:
			for j in range(8):
				Art.box(chunk, Vector3(lane, 0.01, -j * 4.0), Vector3(0.065, 0.02, 1.2), Color("e8d5a1"))
	for side in [-1, 1]:
		for i in range(4):
			Art.ball(self, Vector3(side * (20 + i * 10), 1, -70 - i * 14), Vector3(23, 13 + i * 4, 32), Color("5a9c81"))

func scroll(delta: float) -> void:
	for chunk in chunks:
		chunk.position.z += float(Rules.config.run_speed) * delta
		if chunk.position.z > 48:
			chunk.position.z -= CHUNK_SIZE * chunks.size()
