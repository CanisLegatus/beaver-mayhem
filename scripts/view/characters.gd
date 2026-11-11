class_name Characters
extends RefCounted

static func human(kind: int) -> Node3D:
	var root := Node3D.new()
	var skin := Color("c49578")
	var cloth: Color = [Color("993d2b"),Color("386478"),Color("283143")][kind]
	Sculpt.rings(root,"human_torso",[[0.72,0.25,0.17],[0.85,0.27,0.18],[1.1,0.3,0.19],[1.35,0.36,0.19],[1.5,0.32,0.17],[1.57,0.12,0.12],[1.58,0.01,0.01]],cloth)
	Sculpt.rings(root,"human_face",[[1.51,0.08,0.09],[1.59,0.12,0.13],[1.65,0.17,0.17],[1.77,0.2,0.19],[1.93,0.21,0.18],[2.05,0.17,0.16],[2.09,0.08,0.08],[2.1,0.01,0.01]],skin)
	for side in [-1,1]:
		var leg := Sculpt.limb(root,"human_leg",Vector3(side*0.16,0.83,0),0.68,0.14,Color("293e49"))
		leg.name = "FootL" if side == -1 else "FootR"
		Art.ball(leg,Vector3(0,-0.67,0.11),Vector3(0.27,0.19,0.47),Color("282b28"))
		var arm := Sculpt.limb(root,"human_arm",Vector3(side*0.34,1.4,0),0.62,0.13,cloth)
		arm.rotation.z = side*0.12
		Art.ball(arm,Vector3(0,-0.65,0.03),Vector3(0.17,0.22,0.19),skin)
		Art.ball(root,Vector3(side*0.21,1.81,0),Vector3(0.09,0.18,0.13),skin)
		Art.ball(root,Vector3(side*0.082,1.86,0.171),Vector3(0.085,0.048,0.045),Color("eadfd1"))
		Art.ball(root,Vector3(side*0.082,1.86,0.197),Vector3(0.028,0.033,0.015),Color("33484c"))
		var brow := Art.ball(root,Vector3(side*0.08,1.91,0.171),Vector3(0.105,0.028,0.038),Color("40332c"))
		brow.rotation.z = side*0.12
	Art.ball(root,Vector3(0,1.81,0.2),Vector3(0.076,0.12,0.11),skin.lightened(0.07))
	Art.ball(root,Vector3(0,1.7,0.166),Vector3(0.14,0.027,0.035),Color("704238"))
	Art.cylinder(root,Vector3(0,0.83,0),0.28,0.065,Color("4d392c"))
	for side in [-1,1]:
		Art.box(root,Vector3(side*0.13,1.19,0.192),Vector3(0.16,0.17,0.015),cloth.lightened(0.06))
	for i in range(4): Art.ball(root,Vector3(0,0.96+i*0.12,0.19),Vector3.ONE*0.024,Art.GOLD)
	if kind < 2:
		Art.ball(root,Vector3(0,2.04,0),Vector3(0.47,0.22,0.43),Art.GOLD if kind == 0 else Color("e8e9e3"))
		Art.cylinder(root,Vector3(0,2.04,0.025),0.27,0.035,Art.GOLD if kind == 0 else Color("eee9dc"))
		Art.box(root,Vector3(0,2.15,0),Vector3(0.045,0.035,0.32),Color("b59641") if kind == 0 else Color("c6d5ce"))
	else:
		Sculpt.rings(root,"elon_hair",[[1.98,0.205,0.18],[2.05,0.225,0.2],[2.14,0.17,0.14],[2.17,0.02,0.02]],Color("42392f"),Vector3(0,0,-0.025),"fur")
		for side in [-1,1]:
			var lapel := Art.box(root,Vector3(side*0.08,1.4,0.19),Vector3(0.09,0.3,0.025),cloth.lightened(0.1))
			lapel.rotation.z = side*0.32
		Art.box(root,Vector3(0,1.3,0.2),Vector3(0.05,0.33,0.016),Color("c3cbce"))
		Art.label(root,"X",Vector3(0.16,1.37,0.22),12,Color.WHITE)
	if kind == 0:
		Art.cylinder(root,Vector3(0.48,1.13,0.1),0.035,0.95,Art.BROWN)
		var blade := Sculpt.rings(root,"axe_blade",[[0,0.02,0.03],[0.03,0.2,0.045],[0.17,0.24,0.035],[0.22,0.08,0.025],[0.24,0.01,0.01]],Color("adb9b4"),Vector3(0.58,1.4,0.1),"metal")
		blade.rotation.z = -0.3
	elif kind == 1:
		var paper := Art.cylinder(root,Vector3(0.48,0.93,0.17),0.075,0.55,Color("e0e8d8"))
		paper.rotation.z = 0.3
		Art.box(root,Vector3(0.48,1.1,0.25),Vector3(0.34,0.41,0.012),Color("78a3b0"))
		for i in range(4): Art.box(root,Vector3(0.48,0.99+i*0.07,0.26),Vector3(0.26,0.008,0.006),Color("d4e8df"))
	else:
		var launcher := Art.cylinder(root,Vector3(0.48,1.25,0),0.14,0.85,Color("8a9597"))
		launcher.rotation.z = PI/2
		Art.cylinder(root,Vector3(0.48,1.25,0),0.16,0.12,Color("39454b")).rotation.z = PI/2
		Art.ball(root,Vector3(0.48,1.42,0),Vector3(0.09,0.09,0.09),Color("e84f38"))
	Sculpt.batch_character(root,"human"+str(kind))
	return root

static func beaver(with_weapon: bool = true) -> Node3D:
	var root := Node3D.new()
	var fur := Color("705039")
	Sculpt.rings(root,"beaver_body",[[0.22,0.14,0.15],[0.35,0.34,0.3],[0.6,0.43,0.37],[0.95,0.42,0.34],[1.2,0.34,0.28],[1.4,0.23,0.22],[1.43,0.02,0.02]],fur,Vector3.ZERO,"fur")
	Sculpt.rings(root,"beaver_head",[[1.12,0.12,0.15],[1.25,0.36,0.33],[1.45,0.44,0.36],[1.66,0.39,0.33],[1.8,0.26,0.23],[1.85,0.02,0.02]],fur,Vector3(0,0,-0.18),"fur")
	for side in [-1,1]:
		Art.ball(root,Vector3(side*0.34,1.77,-0.12),Vector3(0.25,0.28,0.16),fur)
		Art.ball(root,Vector3(side*0.34,1.78,-0.21),Vector3(0.14,0.16,0.04),Color("9c7357"))
		Art.ball(root,Vector3(side*0.27,1.58,-0.46),Vector3(0.17,0.15,0.1),Color("1d1916"))
		Art.ball(root,Vector3(side*0.28,1.6,-0.51),Vector3.ONE*0.035,Color("e4dfce"))
		Art.ball(root,Vector3(side*0.17,1.35,-0.53),Vector3(0.38,0.25,0.25),Color("b2926d"))
		var tooth := Art.box(root,Vector3(side*0.085,1.16,-0.62),Vector3(0.12,0.24,0.1),Color("d5a958"))
		tooth.rotation.x = -0.12
		var leg := Sculpt.limb(root,"beaver_leg",Vector3(side*0.28,0.5,0),0.3,0.17,fur,"fur")
		leg.name = "FootL" if side == -1 else "FootR"
		Art.ball(leg,Vector3(0,-0.28,-0.12),Vector3(0.28,0.14,0.42),Color("3c3027"))
		Sculpt.limb(root,"beaver_arm",Vector3(side*0.36,1.0,-0.08),0.46,0.14,fur,"fur").rotation.x = -0.6
		for whisker in range(3):
			var hair := Art.cylinder(root,Vector3(side*0.4,1.35+whisker*0.035,-0.64),0.005,0.37,Color("d0b495"))
			hair.rotation.z = side*(1.2+whisker*0.16)
	Art.ball(root,Vector3(0,1.47,-0.67),Vector3(0.24,0.14,0.11),Color("221f1b"))
	var tail := Art.ball(root,Vector3(0,0.19,0.78),Vector3(0.66,0.12,1.3),Color("3d342a"))
	tail.material_override = Sculpt.surface(Color("453a31"),"fur")
	for i in range(6):
		var ridge := Art.box(root,Vector3(0,0.25,0.32+i*0.16),Vector3(0.5,0.012,0.018),Color("75604b"))
		ridge.rotation.y = 0.2
	if with_weapon: Art.cylinder(root,Vector3(0.46,0.81,-0.42),0.12,0.75,Color("323e3c")).rotation.x = PI/2
	Sculpt.batch_character(root,"beaver"+str(with_weapon))
	return root
