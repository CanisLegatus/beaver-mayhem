class_name Economy
extends RefCounted
signal changed
signal confiscated(item: String)
signal debt_started
var money: int = 0
var debt_time: float = 0.0
var damage_level: int = 0
var rate_level: int = 0
var owned: Array[String] = ["log"]
var active: String = "log"
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()
	reset()

func reset() -> void:
	money = int(Rules.config.starting_money)
	debt_time = 0.0
	damage_level = 0
	rate_level = 0
	owned = ["log"]
	active = "log"
	changed.emit()

func credit(amount: int) -> void:
	var was_negative := money < 0
	money += amount
	if money >= 0:
		debt_time = 0.0
	elif not was_negative:
		debt_started.emit()
	changed.emit()

func buy(item: String) -> bool:
	var level := damage_level if item == "damage" else rate_level
	var cost := Rules.upgrade_cost(item, level) if item in ["damage", "rate"] else int(Rules.config.weapon_prices.get(item, -1))
	if cost < 0 or money < cost or (item in owned):
		return false
	money -= cost
	match item:
		"damage": damage_level += 1
		"rate": rate_level += 1
		_:
			owned.append(item)
			active = item
	changed.emit()
	return true

func cycle() -> void:
	active = owned[(owned.find(active) + 1) % owned.size()]
	changed.emit()

func tick(delta: float) -> void:
	if money >= 0:
		debt_time = 0.0
		return
	debt_time += delta
	while debt_time >= float(Rules.config.debt_seconds):
		debt_time -= float(Rules.config.debt_seconds)
		confiscate()

func confiscate() -> String:
	var eligible: Array[String] = []
	if damage_level > 0: eligible.append("damage")
	if rate_level > 0: eligible.append("rate")
	for weapon in owned:
		if weapon != "log": eligible.append(weapon)
	if eligible.is_empty():
		confiscated.emit("NO ASSETS LEFT")
		return ""
	var item: String = eligible[rng.randi_range(0, eligible.size() - 1)]
	match item:
		"damage": damage_level -= 1
		"rate": rate_level -= 1
		_:
			owned.erase(item)
			if active == item: active = "log"
	confiscated.emit(item.to_upper())
	changed.emit()
	return item
