class_name HazardSystem
extends Node3D
signal damaged(amount: float)
signal announced(text: String)
signal sound_requested(key: String)
signal burst_requested(pos: Vector3, color: Color, count: int)
var hazards: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var timer := 13.0
var comet_used := false
var enabled := true

func lane_strike(lanes: Array, kind: String, warning: float = 1.8, damage: float = 15.0) -> Dictionary:
	if hazards.size() >= int(Rules.config.event_cap): return {}
	var root := Node3D.new()
	add_child(root)
	for lane in lanes:
		var x: float = float(lane)*2.0
		for side in [-1,1]: Art.box(root,Vector3(x+side*0.78,0.06,-8),Vector3(0.06,0.035,20),Color("f2a259")).material_override = Art.material(Color("ef9852"),true)
		for z in [0,-4,-8,-12,-16]:
			var marker := Art.box(root,Vector3(x,0.07,z),Vector3(0.6,0.025,0.09),Color("f5d28c"))
			marker.rotation.y = 0.6
	var falling := Node3D.new()
	add_child(falling)
	for lane in lanes:
		var piece := HazardArt.house() if kind == "house" else (HazardArt.tree_weapon() if kind == "tree" else Node3D.new())
		if kind not in ["tree","house"]:
			for i in range(3): Art.ball(piece,Vector3(i*0.25,0,0),Vector3.ONE*(0.5+i*0.2),Color("82664a") if kind == "earth" else Color("84b9ce"))
		falling.add_child(piece)
		piece.position.x = (float(lane)-float(lanes[0]))*2
	falling.position = Vector3(float(lanes[0])*2,20,-25)
	var record := {"kind":kind,"lanes":lanes.duplicate(),"time":0.0,"warning":maxf(1.3,warning),"damage":damage,"hit":false,"root":root,"visual":falling,"impacted":false}
	hazards.append(record)
	announced.emit("%s  •  AVOID MARKED LANES" % kind.to_upper())
	sound_requested.emit("warning")
	return record

func truck(cyber: bool = false) -> Dictionary:
	var h := lane_strike([-1,0,1],"traffic",2.0,24)
	if h.is_empty(): return h
	h.visual.queue_free()
	h.visual = HazardArt.truck(cyber)
	add_child(h.visual)
	h.direction = -1 if rng.randf()<0.5 else 1
	h.previous = Vector2(-13*h.direction,-18)
	h.visual.position = Vector3(h.previous.x,0,h.previous.y)
	h.visual.rotation.y = 0 if h.direction==1 else PI
	announced.emit("CROSS TRAFFIC  •  HEAD FOR AN OUTER LANE")
	sound_requested.emit("truck")
	return h

func comet() -> void:
	if comet_used or hazards.size() >= int(Rules.config.event_cap): return
	comet_used = true
	var visual := Node3D.new()
	add_child(visual)
	Art.ball(visual,Vector3.ZERO,Vector3.ONE*1.1,Color("c4edff")).material_override = Art.material(Color("86cfff"),true)
	var tail := Art.cylinder(visual,Vector3(-5,2,0),0.45,10,Color("7cc4ef"),0)
	tail.rotation.z = -1.2
	tail.material_override = Art.material(Color("60a9df"),true)
	hazards.append({"kind":"comet","visual":visual,"time":0.0,"root":Node3D.new()})
	add_child(hazards.back().root)
	announced.emit("CELESTIAL IMPACT  •  WATCH THE SKY")
	sound_requested.emit("warning")

func director(delta: float, seconds: float, level: int, night: float, safe_window: bool) -> void:
	if not enabled or safe_window: return
	timer -= delta
	if timer <= 0 and hazards.is_empty():
		timer = rng.randf_range(17,24)
		if level == 1: truck(rng.randf()<0.5)
		elif night > 0.7 and not comet_used: comet()
		else: lane_strike([rng.randi_range(-2,2)],"shards",2.0,12)
	if level == 1 and seconds > 58 and night > 0.7 and not comet_used and hazards.is_empty(): comet()

func tick(delta: float, player_x: float, speed: float) -> void:
	for h in hazards.duplicate():
		h.time += delta
		if h.kind == "comet":
			var p := clampf(h.time/3,0,1)
			h.visual.position = Vector3(35-60*p,45*(1-p)+2,-85-55*p)
			if p >= 1:
				burst_requested.emit(h.visual.position,Color("8cd4ff"),32)
				sound_requested.emit("explosion")
				remove(h)
				var lanes: Array = [-2,-1,0,1,2]
				for i in range(3):
					var index := rng.randi_range(0,lanes.size()-1)
					lane_strike([lanes.pop_at(index)],"shards",2.1+i*0.15,12)
			continue
		var active_time: float = h.time-h.warning
		if h.kind == "traffic":
			if active_time >= 0:
				var previous: Vector2 = h.previous
				var position_2d := Vector2((-13+active_time*11)*h.direction,-speed*1.18+active_time*speed)
				h.visual.position = Vector3(position_2d.x,0,position_2d.y)
				if not h.hit and Rules.segment_hits(previous,position_2d,Vector2(player_x,0),1.8):
					h.hit = true
					damaged.emit(h.damage)
					burst_requested.emit(h.visual.position,Art.GOLD,12)
				h.previous = position_2d
				if active_time > 2.8: remove(h)
			continue
		var progress := clampf(h.time/h.warning,0,1)
		h.visual.position = Vector3(float(h.lanes[0])*2,20*(1-progress)+sin(progress*PI)*4,-25*(1-progress))
		for piece in h.visual.get_children(): piece.rotation += Vector3(0.4,0.7,0.2)*delta
		if active_time >= 0 and not h.impacted:
			h.impacted = true
			burst_requested.emit(Vector3(float(h.lanes[0])*2,0.5,0),Color("b39b73"),14)
			sound_requested.emit("impact")
		if active_time >= 0 and active_time < 0.7 and not h.hit:
			for lane in h.lanes:
				if absf(player_x-float(lane)*2)<0.8:
					h.hit = true
					damaged.emit(h.damage)
					break
		if active_time > 0.8: remove(h)

func remove(h: Dictionary) -> void:
	hazards.erase(h)
	h.visual.queue_free()
	h.root.queue_free()

func clear() -> void:
	for h in hazards.duplicate(): remove(h)
	timer = 13
	comet_used = false
