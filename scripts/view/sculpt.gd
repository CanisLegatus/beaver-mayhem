class_name Sculpt
extends RefCounted
## Original smooth ring-sculpted meshes, shared across instances.
static var cache: Dictionary = {}
static var surfaces: Dictionary = {}

static func surface(color: Color, kind: String = "cloth") -> ShaderMaterial:
	var key := str(color) + kind
	if not surfaces.has(key):
		var shader := Shader.new()
		shader.code = """shader_type spatial;
render_mode specular_schlick_ggx, cull_back, depth_draw_opaque;
uniform vec4 tint : source_color;
uniform float grain = 1.0;
varying vec3 local_pos;
void vertex(){ local_pos = VERTEX; }
float hash(vec3 p){ return fract(sin(dot(p,vec3(12.9898,78.233,35.425)))*43758.5453); }
void fragment(){
 float n = 0.5 + sin(local_pos.x*141.0+local_pos.z*127.0)*sin(local_pos.y*93.0)*0.15;
 float weave = sin(local_pos.y*120.0 + sin(local_pos.x*70.0)*2.0);
 ALBEDO = tint.rgb * (0.9 + n*0.12 + weave*0.018*grain);
 ROUGHNESS = 0.77 + n*0.2;
 NORMAL_MAP = vec3(0.5+weave*0.012*grain,0.5+(n-0.5)*0.035,1.0);
 NORMAL_MAP_DEPTH = 0.4;
}"""
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("tint", color)
		mat.set_shader_parameter("grain", 1.8 if kind == "fur" else 0.6)
		surfaces[key] = mat
	return surfaces[key]

static func rings(parent: Node3D, key: String, profiles: Array, color: Color, pos: Vector3 = Vector3.ZERO, kind: String = "cloth") -> MeshInstance3D:
	if not cache.has(key):
		profiles = profiles.duplicate()
		if float(profiles[0][0]) > float(profiles[-1][0]): profiles.reverse()
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var segments := 24
		for row in range(profiles.size()-1):
			for section in range(segments):
				for corner in [[row,section],[row+1,section+1],[row+1,section],[row,section],[row,section+1],[row+1,section+1]]:
					var p: Array = profiles[corner[0]]
					var angle: float = float(corner[1]) / segments * TAU
					tool.set_uv(Vector2(float(corner[1])/segments,float(corner[0])/(profiles.size()-1)))
					tool.add_vertex(Vector3(cos(angle)*float(p[1]),float(p[0]),sin(angle)*float(p[2])))
		tool.generate_normals()
		tool.index()
		cache[key] = tool.commit()
	var node := MeshInstance3D.new()
	node.mesh = cache[key]
	node.material_override = surface(color,kind)
	node.position = pos
	parent.add_child(node)
	return node

static func limb(parent: Node3D, key: String, pos: Vector3, length: float, radius: float, color: Color, kind: String = "cloth") -> Node3D:
	var pivot := Node3D.new()
	parent.add_child(pivot)
	pivot.position = pos
	rings(pivot,key,[[0,0.01,0.01],[-0.06,radius*0.8,radius*0.8],[-length*0.3,radius,radius*0.9],[-length*0.55,radius*0.85,radius*0.8],[-length*0.8,radius*0.72,radius*0.75],[-length,radius*0.65,radius*0.7],[-length-0.02,0.01,0.01]],color,Vector3.ZERO,kind)
	return pivot

static func clear_cache() -> void:
	cache.clear()
	surfaces.clear()

static func collect_static(node: Node3D, transform: Transform3D, groups: Dictionary) -> void:
	for child in node.get_children():
		if not child is Node3D or child.name in ["FootL","FootR"]: continue
		var local: Transform3D = transform * child.transform
		if child is MeshInstance3D:
			var key := str(child.material_override.get_instance_id())
			if not groups.has(key): groups[key] = []
			groups[key].append({"node":child,"transform":local})
		else: collect_static(child,local,groups)

static func batch_character(root: Node3D, key: String) -> void:
	var groups: Dictionary = {}
	collect_static(root,Transform3D.IDENTITY,groups)
	var batch_key := "batch_"+key
	if not cache.has(batch_key):
		var merged: Array = []
		for group in groups.values():
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			for entry in group: tool.append_from(entry.node.mesh,0,entry.transform)
			merged.append({"mesh":tool.commit(),"material":group[0].node.material_override})
		cache[batch_key] = merged
	for group in groups.values():
		for entry in group: entry.node.free()
	for batch in cache[batch_key]:
		var visual := MeshInstance3D.new()
		visual.mesh = batch.mesh
		visual.material_override = batch.material
		root.add_child(visual)
