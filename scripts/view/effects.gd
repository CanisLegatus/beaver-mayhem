class_name Effects
extends Node3D
var particles: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var textures: Dictionary = {}
var sprite_materials: Dictionary = {}
func _init() -> void: rng.randomize()

func burst(pos: Vector3, color: Color, count: int = 7) -> void:
	for i in range(count):
		if particles.size() >= int(Rules.config.vfx_cap): break
		var smoke := i % 4 == 0
		var visual := Sprite3D.new()
		add_child(visual)
		var file := "smoke_01" if smoke else ("spark_01" if i % 2 == 0 else "star_01")
		if not textures.has(file): textures[file] = load("res://assets/vfx/"+file+".png")
		visual.texture = textures[file]
		if not sprite_materials.has(file):
			var mat := StandardMaterial3D.new()
			mat.albedo_texture = textures[file]
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
			mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			mat.vertex_color_use_as_albedo = true
			mat.disable_fog = true
			sprite_materials[file] = mat
		visual.material_override = sprite_materials[file]
		visual.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		visual.no_depth_test = false
		visual.shaded = false
		visual.pixel_size = 0.0025 if smoke else 0.0014
		visual.position = pos
		visual.modulate = Color("9b9c93") if smoke else color
		visual.rotation.z = rng.randf()*TAU
		var life := rng.randf_range(0.55,1.3) if smoke else rng.randf_range(0.18,0.6)
		particles.append({"visual":visual,"velocity":Vector3(rng.randf_range(-2,2),rng.randf_range(1,3),rng.randf_range(-2,2)),"life":life,"maximum":life,"smoke":smoke})

func tick(delta: float) -> void:
	for particle in particles.duplicate():
		particle.life -= delta
		if not particle.smoke: particle.velocity.y -= delta*7
		particle.visual.position += particle.velocity*delta
		particle.visual.modulate.a = clampf(particle.life/particle.maximum,0,1)
		particle.visual.scale = Vector3.ONE*(1.0+(1-particle.life/particle.maximum)*(2 if particle.smoke else 0.2))
		if particle.life <= 0:
			particle.visual.queue_free()
			particles.erase(particle)

func clear() -> void:
	for particle in particles: particle.visual.queue_free()
	particles.clear()
