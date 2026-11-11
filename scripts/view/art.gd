class_name Art
extends RefCounted
## All original procedural models. Shared materials keep state changes bounded.
static var materials: Dictionary = {}
const BROWN = Color("81502f")
const TAN = Color("dba56c")
const DARK = Color("203b3c")
const GOLD = Color("ffce55")
const MINT = Color("65e3b2")

static func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var key := str(color) + str(glow)
	if not materials.has(key):
		var result := StandardMaterial3D.new()
		result.albedo_color = color
		result.roughness = 0.85
		if glow:
			result.emission_enabled = true
			result.emission = color
		materials[key] = result
	return materials[key]

static func shape(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	node.position = pos
	parent.add_child(node)
	return node

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return shape(parent, mesh, pos, color)

static func ball(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 10
	mesh.rings = 5
	mesh.radius = 0.5
	mesh.height = 1.0
	var node := shape(parent, mesh, pos, color)
	node.scale = size
	return node

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, top: float = -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top < 0 else top
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	return shape(parent, mesh, pos, color)

static func label(parent: Node3D, text: String, pos: Vector3, size: int, color: Color = Color.WHITE) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.font_size = size
	node.pixel_size = 0.012
	node.position = pos
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.no_depth_test = true
	node.modulate = color
	node.outline_size = 8
	node.outline_modulate = Color("163031")
	parent.add_child(node)
	return node

static func beaver() -> Node3D:
	var root := Node3D.new()
	ball(root, Vector3(0, 0.85, 0), Vector3(1.0, 1.25, 0.85), BROWN)
	ball(root, Vector3(0, 1.55, -0.15), Vector3(1.08, 0.95, 0.85), BROWN)
	ball(root, Vector3(0, 1.35, -0.57), Vector3(0.85, 0.45, 0.38), TAN)
	ball(root, Vector3(0, 1.52, -0.75), Vector3(0.22, 0.17, 0.14), DARK)
	for side in [-1, 1]:
		ball(root, Vector3(side * 0.4, 1.98, -0.05), Vector3(0.28, 0.3, 0.22), BROWN)
		ball(root, Vector3(side * 0.3, 1.68, -0.52), Vector3(0.23, 0.26, 0.16), Color.WHITE)
		ball(root, Vector3(side * 0.3, 1.67, -0.61), Vector3(0.10, 0.15, 0.06), DARK)
		box(root, Vector3(side * 0.1, 1.12, -0.7), Vector3(0.16, 0.3, 0.11), Color("fff2cc"))
		var foot := ball(root, Vector3(side * 0.35, 0.2, -0.07), Vector3(0.4, 0.32, 0.6), DARK)
		foot.name = "FootL" if side == -1 else "FootR"
		ball(root, Vector3(side * 0.52, 0.95, -0.2), Vector3(0.32, 0.6, 0.34), BROWN)
	var tail := ball(root, Vector3(0, 0.28, 0.82), Vector3(0.75, 0.18, 1.3), Color("573e35"))
	tail.rotation.x = -0.18
	for i in range(5):
		box(root, Vector3(0, 0.38, 0.42 + i * 0.19), Vector3(0.6, 0.025, 0.025), BROWN)
	var launcher := cylinder(root, Vector3(0.58, 0.95, -0.6), 0.19, 0.8, DARK)
	launcher.rotation.x = PI / 2
	cylinder(root, Vector3(0.58, 1.3, -0.5), 0.11, 0.08, GOLD)
	return root

static func enemy(kind: int) -> Node3D:
	var root := Node3D.new()
	var shirt := [Color("da654a"), Color("558fa5"), Color("4d5675")][kind] as Color
	ball(root, Vector3(0, 0.95, 0), Vector3(0.85, 1.15, 0.6), shirt)
	ball(root, Vector3(0, 1.75, 0), Vector3(0.65, 0.7, 0.6), TAN)
	for side in [-1, 1]:
		var leg := box(root, Vector3(side * 0.22, 0.35, 0), Vector3(0.25, 0.65, 0.32), DARK)
		leg.name = "FootL" if side == -1 else "FootR"
		ball(root, Vector3(side * 0.48, 1.0, 0.15), Vector3(0.25, 0.7, 0.3), shirt)
		ball(root, Vector3(side * 0.14, 1.8, 0.29), Vector3(0.09, 0.1, 0.05), DARK)
	if kind < 2:
		cylinder(root, Vector3(0, 2.06, 0), 0.39, 0.14, GOLD if kind == 0 else Color.WHITE)
		ball(root, Vector3(0, 2.1, 0), Vector3(0.7, 0.4, 0.7), GOLD if kind == 0 else Color.WHITE)
	else:
		var hair := ball(root, Vector3(0, 2.07, -0.07), Vector3(0.7, 0.32, 0.65), Color("423637"))
		hair.rotation.z = -0.18
		box(root, Vector3(0, 1.2, 0.33), Vector3(0.09, 0.5, 0.04), Color.WHITE)
		label(root, "X", Vector3(0.0, 1.3, 0.38), 24, Color.WHITE)
	if kind == 0:
		box(root, Vector3(0.68, 1.15, 0.13), Vector3(0.09, 1.1, 0.09), BROWN)
		box(root, Vector3(0.8, 1.6, 0.13), Vector3(0.42, 0.3, 0.13), Color("b8d1cd"))
	elif kind == 1:
		box(root, Vector3(0.63, 1.2, 0.25), Vector3(0.65, 0.42, 0.13), Color("d2f3f5"))
		for i in range(3):
			box(root, Vector3(0.63, 1.1 + 0.09 * i, 0.33), Vector3(0.45, 0.025, 0.02), shirt)
	else:
		var tube := cylinder(root, Vector3(0.65, 1.35, 0), 0.22, 1.1, Color("929fa4"))
		tube.rotation.z = PI / 2
	return root

static func bulldozer() -> Node3D:
	var root := Node3D.new()
	box(root, Vector3(0, 1.25, 0), Vector3(4.4, 1.8, 4.3), GOLD)
	box(root, Vector3(0, 2.85, -0.3), Vector3(2.5, 1.8, 2.2), DARK)
	box(root, Vector3(0, 3.8, -0.3), Vector3(2.9, 0.25, 2.6), GOLD)
	box(root, Vector3(0, 3, 0.85), Vector3(2.05, 1.2, 0.1), Color("85c6cc"))
	for side in [-1, 1]:
		box(root, Vector3(side * 2.35, 0.65, 0), Vector3(1.0, 1.3, 5.2), DARK)
		for i in range(7):
			var wheel := cylinder(root, Vector3(side * 2.9, 0.65, -2.0 + i * 0.65), 0.42, 0.1, Color("6c7a76"))
			wheel.rotation.z = PI / 2
		for i in range(12):
			box(root, Vector3(side * 2.35, 1.34, -2.4 + i * 0.44), Vector3(1.05, 0.12, 0.15), Color("526461"))
		box(root, Vector3(side * 1.5, 0.75, 2.55), Vector3(0.25, 0.3, 2.0), Color("d6913c"))
		ball(root, Vector3(side * 1.65, 1.9, 2.15), Vector3(0.4, 0.4, 0.15), Color("fff5b9"))
	box(root, Vector3(0, 0.7, 3.45), Vector3(6.6, 1.5, 0.5), Color("edaa40"))
	box(root, Vector3(0, 0.1, 3.65), Vector3(6.8, 0.2, 0.25), Color("b9c9c2"))
	cylinder(root, Vector3(1.35, 2.9, -1.5), 0.18, 2.2, DARK)
	label(root, "DEFORESTATOR", Vector3(0, 4.4, 0), 45, GOLD)
	return root

static func projectile(kind: String) -> Node3D:
	var root := Node3D.new()
	match kind:
		"rocket":
			var hull := cylinder(root, Vector3.ZERO, 0.14, 0.8, Color.WHITE, 0.03)
			hull.rotation.x = PI / 2
			box(root, Vector3(0, 0, 0.22), Vector3(0.55, 0.06, 0.2), Color("e76b55"))
			var flame := ball(root, Vector3(0, 0, 0.6), Vector3(0.2, 0.2, 0.65), GOLD)
			flame.name = "Flame"
			flame.visible = false
		"axe":
			box(root, Vector3.ZERO, Vector3(0.1, 0.65, 0.1), BROWN)
			box(root, Vector3(0.18, 0.23, 0), Vector3(0.45, 0.3, 0.13), Color("d6e2df"))
		"paper":
			box(root, Vector3.ZERO, Vector3(0.55, 0.1, 0.7), Color("cbf4fb"))
		"laser":
			box(root, Vector3.ZERO, Vector3(0.1, 0.1, 2.2), MINT).material_override = material(MINT, true)
		_:
			var radius := 0.28 if kind == "heavy" else 0.15
			var log_mesh := cylinder(root, Vector3.ZERO, radius, 0.8, BROWN)
			log_mesh.rotation.x = PI / 2
			var end := cylinder(root, Vector3(0, 0, -0.41), radius * 0.95, 0.025, TAN)
			end.rotation.x = PI / 2
	return root

static func tree(parent: Node3D, pos: Vector3, size: float) -> void:
	cylinder(parent, pos + Vector3(0, size * 0.5, 0), size * 0.12, size, BROWN)
	for i in range(3):
		cylinder(parent, pos + Vector3(0, size * (0.9 + i * 0.35), 0), size * (0.7 - i * 0.15), size * 0.85, Color("287b62") if i % 2 == 0 else Color("359777"), 0.0)
