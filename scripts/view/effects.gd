class_name Effects
extends Node3D
var particles: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
func _init() -> void: rng.randomize()

func burst(pos: Vector3, color: Color, count: int = 7) -> void:
	for i in range(count):
		if particles.size() >= int(Rules.config.vfx_cap): break
		var visual := Art.box(self, pos, Vector3.ONE * rng.randf_range(0.07, 0.18), color)
		particles.append({"visual": visual, "velocity": Vector3(rng.randf_range(-2,2), rng.randf_range(1,4), rng.randf_range(-2,2)), "life": rng.randf_range(0.25, 0.7)})

func tick(delta: float) -> void:
	for particle in particles.duplicate():
		particle.life -= delta
		particle.velocity.y -= delta * 8
		particle.visual.position += particle.velocity * delta
		particle.visual.rotation += Vector3(2,3,4) * delta
		particle.visual.scale = Vector3.ONE * minf(1, particle.life * 3)
		if particle.life <= 0:
			particle.visual.queue_free()
			particles.erase(particle)

func clear() -> void:
	for particle in particles: particle.visual.queue_free()
	particles.clear()
