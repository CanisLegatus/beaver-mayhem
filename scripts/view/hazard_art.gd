class_name HazardArt
extends RefCounted
static func truck(cyber: bool = false) -> Node3D:
	var root := Node3D.new()
	var body := Color("a1aeb5") if cyber else Color("dddcd2")
	Art.box(root,Vector3(0,0.65,0),Vector3(3.5,0.65,1.65),body)
	Art.box(root,Vector3(-0.1,1.2,0),Vector3(1.7,0.85,1.45),Color("293e4c"))
	if cyber:
		var roof := Art.box(root,Vector3(-0.2,1.68,0),Vector3(2,0.12,1.55),body)
		roof.rotation.z = -0.08
	else:
		Art.box(root,Vector3(-1.1,1.6,0),Vector3(2.1,1.6,1.65),body)
	for side in [-1,1]:
		for x in [-1.15,1.15]:
			var wheel := Art.cylinder(root,Vector3(x,0.35,side*0.8),0.35,0.16,Color("182224"))
			wheel.rotation.x = PI/2
		Art.box(root,Vector3(1.78,0.9,side*0.52),Vector3(0.035,0.13,0.42),Color("dcfaff")).material_override = Art.material(Color("bdeaff"),true)
	Art.label(root,"CYBERTRUCK" if cyber else "TESLA",Vector3(0,2.3,0),20,Art.GOLD)
	Sculpt.batch_character(root,"truck"+str(cyber))
	return root

static func house() -> Node3D:
	var root := Node3D.new()
	Art.box(root,Vector3(0,1.3,0),Vector3(3,2.6,2.5),Color("c4b296"))
	for side in [-1,1]:
		var roof := Art.box(root,Vector3(side*0.8,2.9,0),Vector3(1.9,0.2,2.9),Color("643f36"))
		roof.rotation.z = side*-0.45
		Art.box(root,Vector3(side*0.85,1.5,1.26),Vector3(0.65,0.85,0.04),Color("8bb1be"))
	Art.box(root,Vector3(0,0.8,1.27),Vector3(0.6,1.6,0.05),Art.BROWN)
	Sculpt.batch_character(root,"house")
	return root

static func tree_weapon() -> Node3D:
	var root := Node3D.new()
	Art.tree(root,Vector3.ZERO,2.4)
	Sculpt.batch_character(root,"thrown_tree")
	return root

static func zombie(kind: int, titan: bool = false) -> Node3D:
	var root := Node3D.new()
	var skin := [Color("69816a"),Color("879270"),Color("576d63"),Color("8d9655")][kind] as Color
	Sculpt.rings(root,"zombie_torso",[[0.55,0.24,0.15],[0.8,0.33,0.21],[1.15,0.37,0.2],[1.45,0.35,0.17],[1.52,0.1,0.1]],Color("41464a") if kind != 3 else Color("545c36"))
	Sculpt.rings(root,"zombie_head",[[1.48,0.1,0.12],[1.58,0.17,0.16],[1.8,0.22,0.19],[2.01,0.18,0.17],[2.08,0.01,0.01]],skin)
	for side in [-1,1]:
		var leg := Sculpt.limb(root,"zombie_leg",Vector3(side*0.16,0.67,0),0.58,0.13,Color("343b3a"))
		leg.name = "FootL" if side == -1 else "FootR"
		Art.ball(leg,Vector3(0,-0.55,0.08),Vector3(0.23,0.15,0.35),Color("242b28"))
		var arm := Sculpt.limb(root,"zombie_arm",Vector3(side*0.35,1.4,0),0.65,0.105,skin)
		arm.rotation.x = -1.0
		Art.ball(arm,Vector3(0,-0.65,0),Vector3(0.13,0.2,0.13),skin)
		Art.ball(root,Vector3(side*0.085,1.83,0.18),Vector3(0.075,0.06,0.04),Color("f0b858")).material_override = Art.material(Color("e8a83f"),true)
		Art.box(root,Vector3(side*0.09,1.63,0.17),Vector3(0.05,0.06,0.04),Color("c7c4a7"))
	for i in range(3): Art.box(root,Vector3(-0.2+i*0.15,1.1,0.21),Vector3(0.035,0.32,0.025),skin)
	if titan:
		Art.tree(root,Vector3(-0.5,1.2,-0.3),0.6)
		Art.ball(root,Vector3(0.4,1.4,0.1),Vector3(0.5,0.6,0.5),Color("59675b"))
	Sculpt.batch_character(root,"zombie"+str(kind)+str(titan))
	return root
