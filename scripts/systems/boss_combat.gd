class_name BossCombat
extends RefCounted
signal announced(text: String)
signal qte_requested(direction: int, prop: String)
var phase := "idle"
var clock := 0.0
var action := 0
var target_x := 0.0
var chapter := 1
var rng := RandomNumberGenerator.new()
var damaged := false

func reset(level: int) -> void:
	chapter = level
	phase = "idle"
	clock = 1.5
	action = 0
	damaged = false

func tick(delta: float, player_x: float, enemy: Dictionary, projectiles: ProjectileSystem, hazards: HazardSystem) -> void:
	if enemy.is_empty() or enemy.health.dead: return
	clock -= delta
	if phase == "charge":
		enemy.pos.y += delta*32
		enemy.pos.x = move_toward(enemy.pos.x,target_x,delta*5)
		if not damaged and enemy.pos.y > -4 and absf(player_x-enemy.pos.x)<1.6:
			damaged = true
			hazards.damaged.emit(30)
		if enemy.pos.y > 3:
			phase = "return"
	elif phase == "return":
		enemy.pos.y = move_toward(enemy.pos.y,-27,delta*17)
		enemy.pos.x = move_toward(enemy.pos.x,0,delta*3)
		if enemy.pos.y <= -27:
			phase = "idle"
			clock = 2.5
	elif phase == "windup_charge" and clock <= 0:
		phase = "charge"
		damaged = false
	elif phase == "idle" and clock <= 0 and hazards.hazards.is_empty():
		if chapter == 2: titan_attack(enemy,hazards)
		else: dozer_attack(player_x,enemy,projectiles,hazards)

func dozer_attack(player_x: float, enemy: Dictionary, projectiles: ProjectileSystem, hazards: HazardSystem) -> void:
	match action%3:
		0:
			announced.emit("MISSILE FAN  •  DODGE AFTER LOCK")
			var count := rng.randi_range(2,4)
			for i in range(count):
				var angle := lerpf(-0.65,0.65,float(i)/maxf(1,count-1))
				projectiles.spawn("rocket",Vector3(enemy.pos.x+(i-(count-1)*0.5)*0.65,1.8,enemy.pos.y+1),Vector2(sin(angle),cos(angle))*10,18,false)
			clock = 5
		1:
			target_x = player_x
			phase = "windup_charge"
			clock = 1.65
			hazards.lane_strike([clampi(roundi(player_x/2),-2,2)],"ram",1.65,0)
			announced.emit("BULLDOZER RAM  •  CHANGE LANES NOW")
		_:
			var first := rng.randi_range(-2,0)
			hazards.lane_strike([first,first+2],"earth",2.0,18)
			clock = 5
	action += 1

func titan_attack(enemy: Dictionary, hazards: HazardSystem) -> void:
	match action%4:
		0,2:
			var prop := "tree" if action%4 == 0 else "house"
			announced.emit("TITAN THROW  •  GET READY")
			qte_requested.emit(rng.randi_range(0,2),prop)
			clock = 5
		1:
			hazards.lane_strike([-2,0,2],"earth",2.0,18)
			clock = 4.7
		_:
			hazards.lane_strike([-1,1],"tree",1.9,22)
			clock = 4.7
	action += 1
