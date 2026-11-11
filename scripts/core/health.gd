class_name Health
extends RefCounted
signal died
var hp: float
var maximum: float
var dead := false
func _init(value: float = 100.0) -> void:
	hp = value
	maximum = value
func hit(damage: float) -> bool:
	if dead or damage <= 0.0:
		return false
	hp = maxf(0.0, hp - damage)
	if hp <= 0.0:
		dead = true
		died.emit()
	return true
