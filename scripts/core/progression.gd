class_name Progression
extends RefCounted
const LEVEL_COUNT := 10
var unlocked := 1
var selected := 1
var save_path := "user://progress.cfg"
var save_error := OK

func _init(path: String = "user://progress.cfg") -> void:
	save_path = path
	var file := ConfigFile.new()
	if file.load(save_path) == OK:
		unlocked = clampi(int(file.get_value("campaign", "unlocked", 1)), 1, LEVEL_COUNT)
		selected = clampi(int(file.get_value("campaign", "selected", unlocked)), 1, unlocked)

func select(level: int) -> bool:
	if level < 1 or level > unlocked: return false
	selected = level
	return true

func complete(level: int) -> bool:
	if level < 1 or level > unlocked: return false
	unlocked = maxi(unlocked, mini(LEVEL_COUNT, level + 1))
	return save()

func save() -> bool:
	var file := ConfigFile.new()
	file.set_value("campaign", "unlocked", unlocked)
	file.set_value("campaign", "selected", selected)
	# Atomic replacement prevents interrupted writes from destroying progress.
	save_error = file.save(save_path + ".tmp")
	if save_error == OK:
		save_error = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	return save_error == OK
