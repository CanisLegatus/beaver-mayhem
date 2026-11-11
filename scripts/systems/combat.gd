class_name PlayerCombat
extends RefCounted
var cooldown := 0.0
var heat := 0.0
var overheated := false
var last_weapon := "log"

func reset() -> void:
	cooldown = 0
	heat = 0
	overheated = false
	last_weapon = "log"

func tick(delta: float, x: float, economy: Economy, projectiles: ProjectileSystem) -> bool:
	# Heat persists across switching so cycling cannot bypass cooling.
	if economy.active != "laser" or overheated:
		heat = maxf(0, heat - delta * 0.5)
	if overheated and heat <= 0: overheated = false
	cooldown -= delta
	if economy.active == "laser" and overheated:
		cooldown = maxf(0.0, cooldown)
		return false
	if cooldown > 0: return false
	var stats := Rules.weapon_stats(economy.active, economy.damage_level, economy.rate_level)
	cooldown += float(stats.interval)
	for i in range(int(stats.count)):
		var angle := (i - 1) * 0.12 if economy.active == "fan" else 0.0
		var offset := (i - 0.5) * 1.0 if economy.active == "twin" else 0.0
		var velocity := Vector2(sin(angle), -cos(angle)) * float(stats.speed)
		projectiles.spawn(economy.active, Vector3(x + offset, 1, -0.8), velocity, stats.damage, true, stats.pierce)
	if economy.active == "laser":
		heat += float(stats.interval) / 2.2
		if heat >= 1.0: overheated = true
	last_weapon = economy.active
	return true
